import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/page/perawat/inap/review.dart';

enum VoiceState { initial, listening, processing }

class VoicePageLaporanTambahan extends StatefulWidget {
  const VoicePageLaporanTambahan({
    super.key,
    required this.user,
    required this.patientId,
  });
  final User user;
  final String patientId;
  @override
  State<VoicePageLaporanTambahan> createState() => _VoicePageLaporanState();
}

class _VoicePageLaporanState extends State<VoicePageLaporanTambahan>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _text = '';
  String _statusText = '';
  VoiceState _state = VoiceState.initial;
  int _session = 0;
  bool _navigatedForSession = false;

  late final AnimationController _animController;

  // dipilih berdasarkan locales yg tersedia
  String _chosenLocale = 'id_ID';

  // partial terakhir tiap onResult
  String _lastPartial = '';
  // gabungan semua partial selama long session
  String _fullBuffer = '';
  // jika true, kita ingin auto-restart dan menangkap audio lebih panjang
  bool _keepListening = false;

  // guard untuk mencegah re-init berulang
  bool _reinitInProgress = false;

  // restart timer untuk proactively restart before engine timeout
  Timer? _restartTimer;
  // konfigurasi: berapa sering kita restart (harus < listenFor)
  // default: restart tiap 270 detik (4.5 menit)
  static const Duration _proactiveRestartInterval = Duration(seconds: 270);

  // kontrol exponential backoff ketika gagal reinit
  int _reinitAttempts = 0;

  // apakah ingin mencoba on-device recognition (set true jika device support)
  final bool _preferOnDevice = false;

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

    // inisialisasi speech setelah frame pertama — mencegah showDialog di initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSpeech();
    });
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

          // update UI flag
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
          } else if (s.contains('notlistening') ||
              s.contains('done') ||
              s.contains('stopped')) {
            // sesi berakhir. jika _keepListening true => restart kecil lalu continue
            safeSetState(() {
              _isListening = false;
            });
            try {
              _animController.stop();
            } catch (_) {}

            if (_keepListening && _speechEnabled && mounted) {
              // simpan partial terakhir ke buffer lalu restart session
              _fullBuffer = (_fullBuffer + ' ' + _lastPartial).trim();
              debugPrint(
                'Auto-restart via status: menyimpan lastPartial ke fullBuffer. length=${_fullBuffer.length}',
              );

              // beri jeda kecil sebelum restart untuk mengurangi gap
              await Future.delayed(const Duration(milliseconds: 180));

              if (!_speech.isListening && _keepListening && mounted) {
                _startListeningSession(); // not awaited intentionally
              }
            } else {
              // jika tidak keepListening dan ada partial, coba navigasi jika belum dilakukan
              if (!_keepListening &&
                  _state == VoiceState.listening &&
                  !_navigatedForSession &&
                  _text.isNotEmpty) {
                _navigatedForSession = true;
                _navigateToReview(_text);
              }
              safeSetState(() {
                _state = VoiceState.initial;
                _statusText = 'ready';
              });
            }
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

          // jika timeout tapi keepListening => simpan partial & restart
          if (errStr.contains('error_speech_timeout') && _keepListening) {
            debugPrint(
              'Terjadi speech_timeout, akan simpan partial & restart karena keepListening=true',
            );
            _fullBuffer = (_fullBuffer + ' ' + _lastPartial).trim();
            _lastPartial = '';
            await Future.delayed(const Duration(milliseconds: 250));
            if (_keepListening && mounted && !_speech.isListening) {
              try {
                _startListeningSession();
              } catch (e) {
                debugPrint('Gagal restart setelah timeout: $e');
              }
            }
            return;
          }

          // jika error client/permanent -> re-init dengan guard & backoff
          if (errStr.contains('error_client') || errStr.contains('permanent')) {
            debugPrint(
              'Error client/permanent terdeteksi: mencoba re-init (guarded)',
            );
            await _handleClientErrorAndReinit(errStr);
            return;
          }

          // default: hentikan semuanya
          _keepListening = false;
          try {
            await _speech.stop();
          } catch (_) {}
          safeSetState(() {
            _speechEnabled = false;
            _isListening = false;
            _state = VoiceState.initial;
          });
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
        // dapatkan daftar locale dan pilih yang cocok (id jika ada)
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
          // keep default _chosenLocale
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

  // Guarded reinit with exponential backoff
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

    _keepListening = false;
    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('cancel() during reinit failed: $e');
    }
    // backoff: 600ms * attempts (clamped)
    final wait = Duration(milliseconds: (600 * (_reinitAttempts.clamp(1, 10))));
    await Future.delayed(wait);

    try {
      await _initSpeech();
      _reinitAttempts = 0; // reset success
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

  // merge prev+next removing overlapping words if any
  String _mergeWithOverlap(String prev, String next) {
    final prevTrim = prev.trim();
    final nextTrim = next.trim();
    if (prevTrim.isEmpty) return nextTrim;
    if (nextTrim.isEmpty) return prevTrim;

    final prevWords = prevTrim.split(RegExp(r'\s+'));
    final nextWords = nextTrim.split(RegExp(r'\s+'));

    // max overlap window (in words)
    const int maxOverlap = 8;
    final int tryOverlap = math.min(
      maxOverlap,
      math.min(prevWords.length, nextWords.length),
    );

    // find largest k (<= tryOverlap) such that last k words of prev == first k words of next
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
      // no overlap found -> simple concat
      return (prevTrim + ' ' + nextTrim).trim();
    }

    // remove overlapping prefix from next
    final merged =
        prevWords.join(' ') + ' ' + nextWords.sublist(bestK).join(' ');
    return merged.trim();
  }

  // start/stop proactive restart timer
  void _startRestartTimerIfNeeded() {
    _cancelRestartTimer();
    if (!_keepListening) return;

    _restartTimer = Timer(_proactiveRestartInterval, () {
      debugPrint(
        'Proactive restart timer triggered. Restarting listening session.',
      );
      // stitch partial into fullBuffer before restart to avoid losing it
      _fullBuffer = (_fullBuffer + ' ' + _lastPartial).trim();
      _lastPartial = '';
      // restart session safely
      _startListeningSession();
      // restart the timer for next cycle
      _startRestartTimerIfNeeded();
    });
  }

  void _cancelRestartTimer() {
    try {
      _restartTimer?.cancel();
    } catch (_) {}
    _restartTimer = null;
  }

  // helper: start one listen session (dipanggil oleh start/restart)
  Future<void> _startListeningSession() async {
    if (!_speechEnabled) return;
    _session++;
    final int localSession = _session;

    debugPrint('Memulai listening session: $localSession');

    safeSetState(() {
      _isListening = true;
      _state = VoiceState.listening;
      _statusText = 'listening';
      _text = '';
    });

    // reset last partial for the new session
    _lastPartial = '';

    try {
      _animController.repeat();
    } catch (_) {}

    // cancel previous recognizer to avoid overlaps
    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('cancel() failed: $e');
    }
    // jeda kecil agar engine stabil
    await Future.delayed(const Duration(milliseconds: 180));

    try {
      await _speech.listen(
        onResult: (result) async {
          debugPrint(
            'onResult(s=$localSession): final=${result.finalResult}, words=${result.recognizedWords}',
          );
          if (localSession != _session) return; // ignore outdated sessions

          // simpan partial setiap kali
          _lastPartial = result.recognizedWords;
          safeSetState(() {
            _text = _lastPartial;
          });

          // Jika finalResult muncul
          if (result.finalResult == true) {
            // jika keepListening -> stitch and restart (agresif)
            if (_keepListening) {
              debugPrint(
                'Final result diterima tapi keepListening=true -> stitch & restart',
              );

              // gabungkan ke buffer penuh dengan dedupe overlap
              final merged = _mergeWithOverlap(_fullBuffer, _lastPartial);
              _fullBuffer = merged;

              // reset lastPartial sebelum restart
              _lastPartial = '';

              // hentikan session saat ini jika masih dianggap listening
              try {
                await _speech.stop();
              } catch (_) {}

              try {
                _animController.stop();
              } catch (_) {}

              // jeda sangat pendek sebelum restart untuk meminimalkan gap
              await Future.delayed(const Duration(milliseconds: 150));

              if (_keepListening && mounted) {
                if (!_speech.isListening) {
                  debugPrint(
                    'Restart listening session karena finalResult (keepListening).',
                  );
                  _startListeningSession(); // not awaited intentionally
                }
              }
              return;
            }

            // jika bukan keepListening -> proses final (one-shot)
            if (localSession != _session) return;
            _session++;

            final finalTranscript = _lastPartial;
            try {
              await _speech.stop();
            } catch (_) {}

            try {
              _animController.stop();
            } catch (_) {}

            safeSetState(() {
              _isListening = false;
              _state = VoiceState.processing;
              _statusText = 'processing';
            });

            Future.delayed(const Duration(milliseconds: 150)).then((_) {
              if (!mounted) return;
              final toShow = finalTranscript.isNotEmpty
                  ? finalTranscript
                  : 'Tidak ada teks yang dikenali.';
              if (!mounted) return;
              _navigateToReview(toShow);
              safeSetState(() {
                _state = VoiceState.initial;
                _statusText = 'ready';
                _text = '';
                _isListening = false;
              });
            });
          }
        },
        localeId: _chosenLocale,
        // listenFor harus lebih besar dari restart interval; kami pilih 6 menit
        listenFor: const Duration(minutes: 6),
        // pauseFor menentukan kapan engine menganggap pause = selesai
        pauseFor: const Duration(seconds: 45),
        partialResults: true,
        cancelOnError: true,
        onSoundLevelChange: (level) {
          // keep minimal logging here
          // debugPrint('Sound level: $level');
        },
        onDevice: _preferOnDevice,
      );

      // setiap kali kita memulai sesi baru dalam mode keepListening,
      // hidupkan timer yang akan restart sebelum listenFor habis
      if (_keepListening) {
        _startRestartTimerIfNeeded();
      } else {
        _cancelRestartTimer();
      }
    } catch (e, st) {
      debugPrint('Exception saat _speech.listen: $e\n$st');
      await _handleClientErrorAndReinit('exception_when_listen: $e');
    }
  }

  Future<void> _listenOrStop() async {
    // jika belum siap, inisialisasi dulu dan lanjut hanya jika berhasil
    if (!_speechEnabled) {
      safeSetState(() {
        _text = 'Speech recognition belum siap. Menginisialisasi...';
        _statusText = 'retrying';
      });
      await _initSpeech();
      if (!_speechEnabled) {
        // gagal inisialisasi
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
      // mulai continuous long session
      _keepListening = true;
      _fullBuffer = '';
      _lastPartial = '';
      _navigatedForSession = false;
      _reinitAttempts = 0;

      // start listening
      await _startListeningSession();
    } else {
      // STOP listening (manual stop)
      _keepListening = false;
      _session++; // invalidate outstanding callbacks
      _navigatedForSession = true;

      // gabungkan final buffer + partial
      final captured = (_fullBuffer + ' ' + _lastPartial).trim();
      // ensure dedupe between buffers (in case)
      final finalMerged = _mergeWithOverlap('', captured);

      safeSetState(() {
        _isListening = false;
        _state = VoiceState.processing;
        _statusText = 'processing';
      });

      try {
        _animController.stop();
      } catch (_) {}

      try {
        await _speech.stop();
      } catch (_) {}

      // cancel proactive timer
      _cancelRestartTimer();

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

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
    // guard: mencegah navigasi ganda
    if (!mounted) return;
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReviewTambahan(
            user: widget.user,
            reportText: reportText,
            patientId: widget.patientId,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Navigate error: $e');
    }
  }

  Widget _buildCenterContent() {
    const blue = Color(0xFF093275);
    switch (_state) {
      case VoiceState.initial:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _speechEnabled ? _listenOrStop : _initSpeech,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(color: blue, shape: BoxShape.circle),
                child: const Center(
                  child: Icon(Icons.mic, size: 64, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap To Speak',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF093275),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );

      case VoiceState.listening:
        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final v = _animController.value;

            final double phase1 = 0.0;
            final double phase2 = 2 * math.pi / 5;
            final double phase3 = 4 * math.pi / 5;
            final double phase4 = 6 * math.pi / 5;
            final double phase5 = 8 * math.pi / 5;

            double amp(double phase) =>
                0.5 + 0.5 * math.sin(2 * math.pi * v + phase);

            const double baseHeight = 18.0;
            const double extraHeight = 80.0;

            final h1 = baseHeight + amp(phase1) * extraHeight;
            final h2 = baseHeight + amp(phase2) * extraHeight;
            final h3 = baseHeight + amp(phase3) * extraHeight;
            final h4 = baseHeight + amp(phase4) * extraHeight;
            final h5 = baseHeight + amp(phase5) * extraHeight;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                SizedBox(
                  height: baseHeight + extraHeight + 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBar(h1),
                      const SizedBox(width: 8),
                      _buildBar(h2),
                      const SizedBox(width: 8),
                      _buildBar(h3),
                      const SizedBox(width: 8),
                      _buildBar(h4),
                      const SizedBox(width: 8),
                      _buildBar(h5),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _listenOrStop,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
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
              width: 80,
              height: 80,
              child: CircularProgressIndicator(strokeWidth: 6),
            ),
            SizedBox(height: 16),
            Text(
              'Loading',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF093275),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildBar(double height) {
    return Container(
      width: 10,
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
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildCenterContent(),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                          : 'Status: $_statusText'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
