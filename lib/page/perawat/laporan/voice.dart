import 'dart:async';
import 'dart:convert'; // ✨ NEW: For decoding JSON
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✨ NEW
import 'package:http/http.dart' as http; // ✨ NEW
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✨ NEW
import 'package:vocare/common/type.dart';
import 'package:vocare/page/perawat/laporan/review.dart';

enum VoiceState { initial, listening, processing }

// ✨ NEW: Add a state for data fetching
enum DataState { loading, loaded, error }

// Top-level cache constants
const String _kCacheKey = 'vocare_questions_cache_v1';
const String _kCacheTsKey = 'vocare_questions_cache_ts_v1';
const Duration _kCacheTTL = Duration(hours: 24); // TTL: bisa diubah sesuai kebutuhan

class VoicePageLaporan extends StatefulWidget {
  const VoicePageLaporan({super.key, required this.user});
  final User user;
  @override
  State<VoicePageLaporan> createState() => _VoicePageLaporanState();
}

class _VoicePageLaporanState extends State<VoicePageLaporan>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _text = '';
  String _statusText = '';
  VoiceState _state = VoiceState.initial;
  int _session = 0;
  bool _navigatedForSession = false;

  bool _isSessionActive = false;
  late final AnimationController _animController;
  String _chosenLocale = 'id_ID';
  String _lastPartial = '';
  String _fullBuffer = '';
  bool _autoRestartEnabled = true;
  bool _reinitInProgress = false;
  Timer? _restartTimer;
  int _reinitAttempts = 0;
  final bool _preferOnDevice = false;
  DateTime? _lastAutoRestart;
  static const Duration _autoRestartCooldown = Duration(milliseconds: 400);

  DataState _dataState = DataState.loading;
  String? _errorMessage;
  List<String> _pasienQuestions = [];
  List<String> _perawatQuestions = [];

  String _activeQuestionSet = 'pasien';

  // ✨ NEW: Define the initial hardcoded questions
  final List<String> _initialQuestions = const [
    "Siapa nama lengkap pasien?",
    "Berapa nomor rekam medis pasien?",
    "Apa jenis kelamin pasien?",
    "Kapan tanggal lahir pasien?",
    "Apa status perkawinan pasien?",
    "Apa alamat pasien?",
    "Apa pekerjaan pasien?",
    "Siapa nama penanggung jawab pasien?",
    "Apa hubungan penanggung jawab dengan pasien?",
    "Bagaimana kontak penanggung jawab yang bisa dihubungi?",
    "Tanggal berapa pasien melakukan kunjungan?",
    "Jam berapa pasien tiba di rumah sakit?",
    "Bagaimana cara masuk pasien ke rumah sakit (berjalan kaki/kursi roda/brankar)?",
    "Pasien masuk ke poliklinik mana?",
    "Apakah pasien datang dengan rujukan?",
    "Siapa pendamping pasien saat datang?",
    "Kelas pelayanan apa yang digunakan pasien?",
    "Apa sumber data anamnesa yang digunakan?",
  ];

  // ✨ NEW: showInitialQuestions controls whether the initial list is shown
  bool _showInitialQuestions = true;

  // ✨ NEW: Flag to allow a short grace period after stop so final result arrives
  bool _awaitingFinalization = false;

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSpeech();
      _fetchQuestions();
    });
  }

  // -------------------------
  // SharedPreferences cache helpers
  // -------------------------
  Future<Map<String, dynamic>?> _loadCachedQuestions() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final s = sp.getString(_kCacheKey);
      if (s == null) return null;
      final decoded = json.decode(s);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (e) {
      debugPrint('Load cache error: $e');
    }
    return null;
  }

  Future<int> _getCacheTimestamp() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kCacheTsKey) ?? 0;
  }

  Future<void> _saveCachedQuestions(Map<String, dynamic> data) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kCacheKey, json.encode(data));
      await sp.setInt(_kCacheTsKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Save cache error: $e');
    }
  }

  Future<void> _clearQuestionsCache() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kCacheKey);
    await sp.remove(_kCacheTsKey);
  }

  // -------------------------
  // Network refresh (background-capable)
  // -------------------------
  Future<void> _refreshQuestionsFromNetwork({bool showErrors = false}) async {
    try {
      final apiUrl = dotenv.env['API_URL'];
      if (apiUrl == null) {
        if (showErrors) throw Exception('API_URL not found in .env file');
        return;
      }
      final response = await http.get(Uri.parse('$apiUrl/assesments/questions'));
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        final data = decodedData['data'] as Map<String, dynamic>? ?? {};

        // simpan cache
        await _saveCachedQuestions(data);

        // update UI hanya bila ada perbedaan atau saat awal belum ada data
        final List<String> pQuestions = List<String>.from(
          (data['pasien']?[0]?['list_pertanyaan']) ?? [],
        );
        final List<String> nQuestions = List<String>.from(
          (data['perawat']?[0]?['list_pertanyaan']) ?? [],
        );

        if (!mounted) return;
        safeSetState(() {
          _pasienQuestions = pQuestions;
          _perawatQuestions = nQuestions;
          _dataState = DataState.loaded;
        });
      } else {
        if (showErrors) {
          throw Exception(
              'Failed to load questions. Status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Error refreshing questions from network: $e');
      if (showErrors && mounted) {
        safeSetState(() {
          _errorMessage = e.toString();
          _dataState = DataState.error;
        });
      }
    }
  }

  // --- Ganti _fetchQuestions dengan versi cache-aware ---
  Future<void> _fetchQuestions() async {
    safeSetState(() {
      _dataState = DataState.loading;
      _errorMessage = null;
    });

    try {
      // 1) Coba load cache
      final cached = await _loadCachedQuestions();
      final ts = await _getCacheTimestamp();
      final cacheAge =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));

      if (cached != null) {
        // Terdapat cache — tampilkan segera
        final List<String> pQuestions = List<String>.from(
          (cached['pasien']?[0]?['list_pertanyaan']) ?? [],
        );
        final List<String> nQuestions = List<String>.from(
          (cached['perawat']?[0]?['list_pertanyaan']) ?? [],
        );

        safeSetState(() {
          _pasienQuestions = pQuestions;
          _perawatQuestions = nQuestions;
          _dataState = DataState.loaded;
        });

        // Jika cache masih fresh: jalankan refresh di background tapi jangan ganggu UI
        if (cacheAge < _kCacheTTL) {
          // background refresh (tidak menampilkan error ke user)
          _refreshQuestionsFromNetwork();
          return;
        } else {
          // cache expired — tampilkan cache terlebih dulu, lalu refresh di background
          _refreshQuestionsFromNetwork();
          return;
        }
      }

      // 2) Tidak ada cache — ambil dari network (tunggu sampai selesai)
      final apiUrl = dotenv.env['API_URL'];
      if (apiUrl == null) throw Exception('API_URL not found in .env file');

      final response = await http.get(Uri.parse('$apiUrl/assesments/questions'));

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        final data = decodedData['data'] as Map<String, dynamic>? ?? {};

        final List<String> pQuestions = List<String>.from(
          (data['pasien']?[0]?['list_pertanyaan']) ?? [],
        );
        final List<String> nQuestions = List<String>.from(
          (data['perawat']?[0]?['list_pertanyaan']) ?? [],
        );

        // simpan cache
        await _saveCachedQuestions(data);

        safeSetState(() {
          _pasienQuestions = pQuestions;
          _perawatQuestions = nQuestions;
          _dataState = DataState.loaded;
        });
      } else {
        throw Exception(
            'Failed to load questions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      // Jika ada cache sebelumnya, biarkan tetap tampil; kalau gak ada, tampilkan error
      if (!mounted) return;
      final cached = await _loadCachedQuestions();
      if (cached != null) {
        // sudah ditampilkan lebih dulu; cukup log saja
        safeSetState(() {
          _errorMessage = e.toString();
          _dataState = DataState.loaded; // keep showing cached data
        });
      } else {
        safeSetState(() {
          _errorMessage = e.toString();
          _dataState = DataState.error;
        });
      }
    }
  }

  @override
  void dispose() {
    _cancelRestartTimer();
    try {
      _speech.cancel();
    } catch (_) {}
    try {
      _speech.stop();
    } catch (_) {}
    _animController.dispose();
    super.dispose();
  }

  Future<bool> _ensureMicrophonePermission() async {
    final status = await Permission.microphone.status;
    debugPrint('Current microphone permission status: $status');

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (!mounted) return false;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Perlu izin mikrofon'),
          content: const Text(
            'Aplikasi membutuhkan akses mikrofon untuk fitur voice. '
            'Silakan buka Pengaturan aplikasi dan berikan izin Mikrofon.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(ctx).pop();
              },
              child: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      );
      return false;
    }

    final result = await Permission.microphone.request();
    debugPrint('Request result: $result');
    return result.isGranted;
  }

  Future<void> _initSpeech() async {
    safeSetState(() {
      _statusText = 'Memeriksa permission...';
    });

    final ok = await _ensureMicrophonePermission();
    if (!ok) {
      safeSetState(() {
        _speechEnabled = false;
        _text = 'Permission mikrofon tidak diberikan.';
        _statusText = 'permission_denied';
        _state = VoiceState.initial;
      });
      return;
    }

    safeSetState(() {
      _statusText = 'Menginisialisasi speech-to-text...';
    });

    try {
      bool available = await _speech.initialize(
        onStatus: (status) async {
          debugPrint('Speech status callback: $status');
          final s = (status ?? '').toLowerCase();

          safeSetState(() {
            _statusText = status ?? '';
          });

          if (s.contains('listening')) {
            safeSetState(() {
              _isListening = true;
              _navigatedForSession = false;
              _state = VoiceState.listening;
            });
            try {
              _animController.repeat();
            } catch (_) {}
            return;
          }

          if (s.contains('notlistening') ||
              s.contains('done') ||
              s.contains('stopped')) {
            final wasListening = _isListening;
            safeSetState(() {
              _isListening = false;
            });
            try {
              _animController.stop();
            } catch (_) {}

            // 🔁 Auto-restart jika sesi logis masih aktif dan bukan karena user stop
            if (_autoRestartEnabled &&
                wasListening &&
                _isSessionActive && // ✅ KUNCI: hanya jika sesi logis aktif
                !_navigatedForSession &&
                _speechEnabled &&
                !_reinitInProgress) {
              final now = DateTime.now();
              final last =
                  _lastAutoRestart ?? DateTime.fromMillisecondsSinceEpoch(0);
              if (now.difference(last) > _autoRestartCooldown) {
                _lastAutoRestart = now;
                if (_lastPartial.isNotEmpty) {
                  _fullBuffer = _mergeWithOverlap(_fullBuffer, _lastPartial);
                  _lastPartial = '';
                }
                debugPrint(
                  'Auto-restart triggered by status ($status). Restarting quickly...',
                );
                Future.delayed(const Duration(milliseconds: 150)).then((_) {
                  if (!mounted) return;
                  if (_isSessionActive &&
                      _speechEnabled &&
                      !_reinitInProgress) {
                    try {
                      _startListeningSession();
                    } catch (e) {
                      debugPrint('Auto-restart failed to start: $e');
                    }
                  }
                });
                return;
              }
            }

            // Hanya kembalikan ke initial jika sesi logis TIDAK aktif
            safeSetState(() {
              if (_state != VoiceState.processing && !_isSessionActive) {
                _state = VoiceState.initial;
              }
            });
          }
        },
        onError: (error) async {
          debugPrint('Speech error callback: $error');
          final msg = error?.toString() ?? 'Unknown error';
          safeSetState(() {
            _text = 'Speech error: $msg';
            _statusText = 'error';
          });

          final errStr = msg.toLowerCase();
          bool shouldRestart = false;

          if (errStr.contains('error_no_match') ||
              errStr.contains('not_matching') ||
              errStr.contains('error_speech_timeout')) {
            if (_lastPartial.isNotEmpty) {
              _fullBuffer = _mergeWithOverlap(_fullBuffer, _lastPartial);
              _lastPartial = '';
            }
            shouldRestart = true;
          } else if (errStr.contains('error_client') ||
              errStr.contains('permanent')) {
            debugPrint('Client/permanent error: triggering reinit');
            await _handleClientErrorAndReinit(errStr);
            return;
          }

          if (shouldRestart &&
              _autoRestartEnabled &&
              _isSessionActive &&
              !_reinitInProgress) {
            await Future.delayed(const Duration(milliseconds: 250));
            if (!mounted) return;
            if (_isSessionActive && _speechEnabled && !_reinitInProgress) {
              try {
                _startListeningSession();
              } catch (e) {
                debugPrint('Restart after error failed: $e');
              }
            }
            return;
          }

          // Hanya hentikan jika sesi TIDAK aktif
          if (!_isSessionActive) {
            try {
              await _speech.stop();
            } catch (_) {}
            safeSetState(() {
              _speechEnabled = false;
              _isListening = false;
              _state = VoiceState.initial;
            });
          }
        },
      );

      if (!available) {
        safeSetState(() {
          _speechEnabled = false;
          _text = 'Speech recognition tidak tersedia di perangkat ini.';
          _statusText = 'unavailable';
          _state = VoiceState.initial;
        });
      } else {
        try {
          final locales = await _speech.locales();
          final systemLocale = await _speech.systemLocale();
          debugPrint(
            'Available locales: ${locales.map((l) => l.localeId).toList()}',
          );
          debugPrint('System locale: ${systemLocale?.localeId}');

          final idLocale = locales.firstWhere(
            (l) => l.localeId.toLowerCase().contains('id'),
            orElse: () =>
                systemLocale ??
                (locales.isNotEmpty
                    ? locales.first
                    : LocaleName('id_ID', 'id_ID')),
          );
          _chosenLocale = idLocale.localeId;
          debugPrint('Chosen locale: $_chosenLocale');
        } catch (e) {
          debugPrint('Gagal mendapatkan locales: $e');
        }

        safeSetState(() {
          _speechEnabled = true;
          _statusText = 'ready';
          _state = VoiceState.initial;
        });
      }
    } catch (e, st) {
      debugPrint('Exception saat initialize: $e\n$st');
      safeSetState(() {
        _speechEnabled = false;
        _statusText = 'init_error';
        _text = 'Gagal inisialisasi speech: $e';
        _state = VoiceState.initial;
      });
    }
  }

  Future<void> _handleClientErrorAndReinit(String reason) async {
    if (_reinitInProgress) {
      debugPrint('Reinit already in progress, skipping.');
      return;
    }
    _reinitInProgress = true;
    _reinitAttempts++;
    debugPrint(
      'handleClientErrorAndReinit triggered (#$_reinitAttempts): $reason',
    );

    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('cancel() during reinit failed: $e');
    }
    final wait = Duration(milliseconds: (600 * (_reinitAttempts.clamp(1, 10))));
    await Future.delayed(wait);

    try {
      await _initSpeech();
      _reinitAttempts = 0;
    } catch (e) {
      debugPrint('Re-init gagal: $e');
      safeSetState(() {
        _speechEnabled = false;
        _statusText = 'init_error_after_client_error';
      });
    } finally {
      _reinitInProgress = false;
    }
  }

  String _mergeWithOverlap(String prev, String next) {
    final prevTrim = prev.trim();
    final nextTrim = next.trim();
    if (prevTrim.isEmpty) return nextTrim;
    if (nextTrim.isEmpty) return prevTrim;

    final prevWords = prevTrim.split(RegExp(r'\s+'));
    final nextWords = nextTrim.split(RegExp(r'\s+'));

    const int maxOverlap = 8;
    final int tryOverlap = math.min(
      maxOverlap,
      math.min(prevWords.length, nextWords.length),
    );

    int bestK = 0;
    for (int k = tryOverlap; k >= 1; k--) {
      final prevSuffix = prevWords
          .sublist(prevWords.length - k)
          .join(' ')
          .toLowerCase();
      final nextPrefix = nextWords.sublist(0, k).join(' ').toLowerCase();
      if (prevSuffix == nextPrefix) {
        bestK = k;
        break;
      }
    }

    if (bestK == 0) {
      return (prevTrim + ' ' + nextTrim).trim();
    }

    final merged =
        prevWords.join(' ') + ' ' + nextWords.sublist(bestK).join(' ');
    return merged.trim();
  }

  void _cancelRestartTimer() {
    try {
      _restartTimer?.cancel();
    } catch (_) {}
    _restartTimer = null;
  }

  Future<void> _startListeningSession() async {
    if (!_speechEnabled || !_isSessionActive) return; // ✅ tambahan guard
    _session++;
    final int localSession = _session;

    debugPrint('Memulai listening session: $localSession');

    safeSetState(() {
      _isListening = true;
      _state = VoiceState.listening;
      _statusText = 'listening';
      _awaitingFinalization = false; // reset
    });

    _lastPartial = '';

    try {
      _animController.repeat();
    } catch (_) {}

    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('cancel() failed: $e');
    }
    await Future.delayed(const Duration(milliseconds: 180));

    try {
      await _speech.listen(
        onResult: (result) async {
          if (localSession != _session) return;

          _lastPartial = result.recognizedWords;
          safeSetState(() {
            _text = _lastPartial;
          });

          if (result.finalResult == true) {
            final merged = _mergeWithOverlap(_fullBuffer, _lastPartial);
            _fullBuffer = merged;
            _lastPartial = '';
            debugPrint(
              'Final received and stitched into fullBuffer. length=${_fullBuffer.length}',
            );
          }
        },
        localeId: _chosenLocale,
        // ✨ LONG durations to allow long dictation (keperluan pasien panjang)
        listenFor: const Duration(hours: 2),
        // pauseFor determines how long silence is tolerated before auto-stop
        pauseFor: const Duration(minutes: 2),
        partialResults: true,
        cancelOnError: false,
        onSoundLevelChange: (level) {},
        onDevice: _preferOnDevice,
      );

      _cancelRestartTimer();
    } catch (e, st) {
      debugPrint('Exception saat _speech.listen: $e\n$st');
      if (_isSessionActive) {
        await _handleClientErrorAndReinit('exception_when_listen: $e');
      }
    }
  }

  Future<void> _listenOrStop() async {
    if (!_speechEnabled) {
      safeSetState(() {
        _text = 'Speech recognition belum siap. Menginisialisasi...';
        _statusText = 'retrying';
      });
      await _initSpeech();
      if (!_speechEnabled) {
        return;
      }
    }

    final perm = await Permission.microphone.status;
    if (!perm.isGranted) {
      safeSetState(() {
        _text = 'Permission mikrofon hilang. Silakan beri izin.';
        _statusText = 'permission_lost';
        _speechEnabled = false;
        _state = VoiceState.initial;
      });
      return;
    }

    if (!_isListening) {
      // 🔑 START SESI LOGIS
      _isSessionActive = true;
      _lastPartial = '';
      _navigatedForSession = false;
      _reinitAttempts = 0;
      await _startListeningSession();
    } else {
      // 🔑 STOP SESI LOGIS
      _isSessionActive = false;
      _session++;
      _navigatedForSession = true;

      safeSetState(() {
        _isListening = false;
        _state = VoiceState.processing;
        _statusText = 'processing';
        _awaitingFinalization = true; // allow grace period for final result
      });

      try {
        _animController.stop();
      } catch (_) {}

      try {
        await _speech.stop();
      } catch (e) {
        debugPrint('Error saat stop(): $e');
        // If stop fails, try cancel as fallback
        try {
          await _speech.cancel();
        } catch (_) {}
      }

      _cancelRestartTimer();

      // ✨ NEW: Give a short grace period (up to 900ms) so the engine can deliver a final result
      // In many cases the finalResult callback arrives a few hundred ms after stop().
      await Future.delayed(const Duration(milliseconds: 700));

      // capture all text available (fullBuffer + any last partial)
      final captured = (_fullBuffer + ' ' + _lastPartial).trim();
      final finalMerged = _mergeWithOverlap('', captured);

      // reset buffers AFTER capture
      _fullBuffer = '';
      _lastPartial = '';
      _awaitingFinalization = false;

      final toShow = finalMerged.isNotEmpty
          ? finalMerged
          : 'Tidak ada teks yang dikenali.';
      if (!mounted) return;
      _navigateToReview(toShow);

      safeSetState(() {
        _state = VoiceState.initial;
        _statusText = 'ready';
        _text = '';
        _isListening = false;
      });
    }
  }

  void _navigateToReview(String reportText) {
    if (!mounted) return;
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VocareReport(
            reportText: reportText,
            username: widget.user.username,
            token: widget.user.token,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Navigate error: $e');
    }
  }

  Widget _buildQuestions() {
    Widget content;
    switch (_dataState) {
      case DataState.loading:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text(
                  'Pertanyaan Awal:',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _initialQuestions.map((q) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Icon(Icons.circle, size: 8),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              q,
                              style: const TextStyle(fontSize: 15, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
        break;

      case DataState.error:
        content = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Gagal memuat pertanyaan:\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _fetchQuestions,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        );
        break;

      case DataState.loaded:
        if (_showInitialQuestions) {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pertanyaan Awal:',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _initialQuestions.map((q) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Icon(Icons.circle, size: 8),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                q,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      'Pertanyaan Pasien',
                      active: _activeQuestionSet == 'pasien',
                      isRight: false, // kiri = putih
                      onPressed: () {
                        safeSetState(() {
                          _showInitialQuestions = false;
                          _activeQuestionSet = 'pasien';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildToggleButton(
                      'Pertanyaan Perawat',
                      active: _activeQuestionSet == 'perawat',
                      isRight: true, // kanan = biru
                      onPressed: () {
                        safeSetState(() {
                          _showInitialQuestions = false;
                          _activeQuestionSet = 'perawat';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          final bool isShowingPerawat = _activeQuestionSet == 'perawat';
          final questions = isShowingPerawat ? _perawatQuestions : _pasienQuestions;
          final title = isShowingPerawat
              ? 'Pertanyaan Untuk Perawat:'
              : 'Pertanyaan Untuk Pasien:';

          content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: questions.map((q) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Icon(Icons.circle, size: 8),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                q,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      'Pertanyaan Awal',
                      active: _showInitialQuestions,
                      isRight: false, 
                      onPressed: () {
                        safeSetState(() {
                          _showInitialQuestions = true;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildToggleButton(
                      isShowingPerawat ? 'Pertanyaan Pasien' : 'Pertanyaan Perawat',
                      active: isShowingPerawat
                          ? _activeQuestionSet == 'pasien'
                          : _activeQuestionSet == 'perawat',
                      isRight: true, 
                      onPressed: () {
                        safeSetState(() {
                          _activeQuestionSet = isShowingPerawat ? 'pasien' : 'perawat';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        break;
    }

    return SizedBox(
      height: 400,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: content,
        ),
      ),
    );
  }

  ButtonStyle _commonButtonStyle({bool filled = true}) {
    const radius = 8.0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    if (filled) {
      return ElevatedButton.styleFrom(
        shape: shape,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        elevation: 2,
      );
    } else {
      return OutlinedButton.styleFrom(
        shape: shape,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      );
    }
  }

  Widget _buildPrimaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        style: _commonButtonStyle(filled: true),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  Widget _buildSecondaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        style: _commonButtonStyle(filled: false),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  Widget _buildTextButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 44,
      child: TextButton(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  Widget _buildToggleButton(
    String label, {
    required bool active,
    required bool isRight,
    required VoidCallback onPressed,
  }) {
    const radius = 8.0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    const primaryColor = Color(0xFF093275);


    final background = isRight ? primaryColor : Colors.white;
    final foreground = isRight ? Colors.white : primaryColor;
    final side = isRight
        ? null
        : const BorderSide(color: primaryColor, width: 1.2);
    final elevation = active
        ? 2.0
        : 0.0;

    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: shape,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: elevation,
          side: side,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildCenterContent() {
    const blue = Color(0xFF093275);
    const double micSize = 110;
    const double iconSize = 36;
    const double tapTextSize = 14;

    switch (_state) {
      case VoiceState.initial:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _speechEnabled ? _listenOrStop : _initSpeech,
              child: Container(
                width: micSize,
                height: micSize,
                decoration: BoxDecoration(color: blue, shape: BoxShape.circle),
                child: Center(
                  child: Icon(Icons.mic, size: iconSize, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap To Speak',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: tapTextSize,
                color: Color(0xFF093275),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );

      case VoiceState.listening:
        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final v = _animController.value;
            final double phaseStep = 2 * math.pi / 5;
            double amp(double phase) =>
                0.5 + 0.5 * math.sin(2 * math.pi * v + phase);

            const double baseHeight = 12.0;
            const double extraHeight = 48.0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                SizedBox(
                  height: baseHeight + extraHeight + 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final phase = phaseStep * i;
                      final h = baseHeight + amp(phase) * extraHeight;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _buildBar(h),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _listenOrStop,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // 🔍 Opsional: info saat engine sedang restart
                if (!_isListening && _isSessionActive)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Restart otomatis... lanjutkan berbicara',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        );

      case VoiceState.processing:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(strokeWidth: 5),
            ),
            SizedBox(height: 12),
            Text(
              'Loading',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF093275),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildBar(double height) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF093275),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7E2FD),
      appBar: AppBar(
        titleSpacing: 30,
        title: const Text(
          'Vocare Report',
          style: TextStyle(fontSize: 20, color: Color(0xFF093275)),
        ),
        backgroundColor: const Color(0xFFD7E2FD),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildQuestions(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildCenterContent(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Text(
                _isListening
                    ? 'Mendengarkan...'
                    : (_statusText == 'ready'
                        ? 'Siap Merekam'
                        : _isSessionActive
                            ? 'Sesi aktif – lanjutkan berbicara'
                            : 'Status: $_statusText'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}