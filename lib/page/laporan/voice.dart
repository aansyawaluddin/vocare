import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

enum VoiceState { initial, listening, processing, result }

class VoicePage extends StatefulWidget {
  const VoicePage({super.key});
  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  final SpeechToText _speech = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _text = '';
  String _statusText = '';
  VoiceState _state = VoiceState.initial;

  // session token untuk menghindari pemrosesan ganda
  int _session = 0;

  // Helper aman untuk setState
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
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
        onStatus: (status) {
          debugPrint('Speech status callback: $status');
          safeSetState(() {
            _statusText = status;
            if (status == 'listening') {
              _isListening = true;
            } else if (status == 'notListening' ||
                status == 'done' ||
                status == 'stopped') {
              _isListening = false;
            }
          });
        },
        onError: (error) {
          debugPrint('Speech error callback: $error');
          String msg = 'Unknown error';
          try {
            msg = error.errorMsg ?? error.toString();
          } catch (_) {
            msg = error.toString();
          }

          safeSetState(() {
            _text = 'Speech error: $msg';
            _speechEnabled = false;
            _isListening = false;
            _state = VoiceState.initial;
            _statusText = 'error';
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

  /// Start or stop listening.
  Future<void> _listenOrStop() async {
    if (!_speechEnabled) {
      safeSetState(() {
        _text = 'Speech recognition belum siap. Mencoba inisialisasi...';
        _statusText = 'retrying';
      });
      await _initSpeech();
      return;
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
      // START listening: naikkan session token
      _session++;
      final int localSession = _session;

      safeSetState(() {
        _isListening = true;
        _state = VoiceState.listening;
        _statusText = 'listening';
        _text = '';
      });

      _speech.listen(
        onResult: (result) async {
          // jika session sudah invalid, abaikan semua callback
          if (localSession != _session) return;

          // update interim text dengan aman
          safeSetState(() {
            _text = result.recognizedWords;
          });

          // ketika final result -> processing -> result (proses sekali)
          if (result.finalResult == true) {
            // immediate invalidate the session to prevent duplicates
            if (localSession != _session) return;
            _session++; // invalidate any subsequent callbacks from previous session

            final finalTranscript = result.recognizedWords;
            try {
              await _speech.stop();
            } catch (_) {}

            safeSetState(() {
              _isListening = false;
              _state = VoiceState.processing;
              _statusText = 'processing';
              _text = 'Memproses hasil...';
            });

            // simulasi processing
            await Future.delayed(const Duration(seconds: 1));
            if (!mounted) return;

            safeSetState(() {
              _state = VoiceState.result;
              _statusText = 'ready';
              _text = finalTranscript.isNotEmpty
                  ? finalTranscript
                  : 'Tidak ada teks yang dikenali.';
            });
          }
        },
        localeId: 'id-ID',
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 8),
        partialResults: true,
        cancelOnError: true,
      );
    } else {
      // STOP listening manual:
      // invalidate session first to ignore callbacks that may come after stop
      _session++;
      final captured = _text; // interim text saat stop

      safeSetState(() {
        _isListening = false;
        _state = VoiceState.processing;
        _statusText = 'processing';
        _text = 'Memproses hasil...';
      });

      try {
        await _speech.stop();
      } catch (_) {}

      // simulasi processing
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      safeSetState(() {
        _state = VoiceState.result;
        _statusText = 'ready';
        _text = captured.isNotEmpty
            ? captured
            : 'Tidak ada teks yang dikenali.';
      });
    }
  }

  @override
  void dispose() {
    // hentikan speech dan batalkan callback secepat mungkin
    try {
      _speech.cancel();
    } catch (_) {}
    try {
      _speech.stop();
    } catch (_) {}
    super.dispose();
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
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        );

      case VoiceState.listening:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.graphic_eq, size: 120, color: Color(0xFF093275)),
            const SizedBox(height: 24),
            const Text(
              'Mendengarkan...',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFF093275),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _listenOrStop,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
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

      case VoiceState.result:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF093275),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                safeSetState(() {
                  _state = VoiceState.initial;
                });
              },
              icon: const Icon(Icons.replay),
              label: const Text('Record Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF093275),
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7E2FD),
      appBar: AppBar(
        titleSpacing: 0,
        title: const Center(
          child: Text(
            'Vocare Report',
            style: TextStyle(fontSize: 20, color: Color(0xFF093275)),
          ),
        ),
        backgroundColor: const Color(0xFFD7E2FD),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF093275)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status: $_statusText',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (!_speechEnabled)
                    IconButton(
                      onPressed: _initSpeech,
                      icon: const Icon(Icons.refresh, color: Color(0xFF093275)),
                    ),
                ],
              ),
            ),
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
                _statusText == 'processing'
                    ? 'Memproses...'
                    : _statusText.isNotEmpty
                    ? 'Status: $_statusText'
                    : '',
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
