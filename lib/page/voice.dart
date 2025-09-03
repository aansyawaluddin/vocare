import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoicePage extends StatefulWidget {
  const VoicePage({super.key});
  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  final SpeechToText _speech = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _text = 'Tekan tombol mikrofon untuk mulai...';
  String _statusText = '';
  int _session = 0;

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
    setState(() {
      _statusText = 'Memeriksa permission...';
    });

    final ok = await _ensureMicrophonePermission();
    if (!ok) {
      setState(() {
        _speechEnabled = false;
        _text = 'Permission mikrofon tidak diberikan.';
        _statusText = 'Microphone permission ditolak';
      });
      return;
    }

    setState(() {
      _statusText = 'Menginisialisasi speech-to-text...';
    });

    bool available = false;
    try {
      available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status callback: $status');
          setState(() {
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

          // Ambil pesan error secara aman
          String msg = 'Unknown error';
          bool permanent = false;
          try {
            msg = error.errorMsg ?? error.toString();
            permanent = error.permanent == true;
          } catch (_) {
            msg = error.toString();
          }

          setState(() {
            _text = 'Speech error: $msg';
            _speechEnabled = false; // nonaktifkan sampai user retry
            _isListening = false;
            _statusText = 'error';
          });

          if (permanent) {
            debugPrint('Error ditandai permanent; user harus retry manual.');
          }
        },
      );
    } catch (e, st) {
      debugPrint('Exception saat initialize: $e\n$st');
    }

    if (!available) {
      setState(() {
        _speechEnabled = false;
        _text = 'Speech recognition tidak tersedia di perangkat ini.';
        _statusText = 'unavailable';
      });
      return;
    }

    setState(() {
      _speechEnabled = true;
      _statusText = 'ready';
      _text = 'Tekan tombol mikrofon untuk mulai...';
    });
  }

  /// Start/stop listening
  Future<void> _listen() async {
    if (!_speechEnabled) {
      setState(
        () => _text = 'Speech recognition belum siap. Tekan Retry jika perlu.',
      );
      return;
    }

    if (!_isListening) {
      // Pastikan lagi permission sebelum mulai
      final ok = await Permission.microphone.status == PermissionStatus.granted;
      if (!ok) {
        setState(() {
          _text =
              'Permission mikrofon hilang. Silakan Retry atau buka Pengaturan.';
          _statusText = 'permission_lost';
          _speechEnabled = false;
        });
        return;
      }

      // Mulai listening
      setState(() {
        _isListening = true;
        _text = 'Mendengarkan...';
        _session++; // buat session baru
        _statusText = 'listening';
      });

      final int currentSession = _session;

      _speech.listen(
        onResult: (result) {
          // hanya update UI bila masih session yang sama dan masih listening
          if (!_isListening) return;
          if (currentSession != _session) return;

          setState(() {
            _text = result.recognizedWords;
          });
        },
        localeId: 'id-ID',
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 8),
        partialResults: true,
        cancelOnError: true,
      );
    } else {
      // Stop/cancel listening dan invalidasi session
      await _speech.cancel();
      setState(() {
        _isListening = false;
        _session++;
        _text = 'Tekan tombol mikrofon untuk mulai...';
        _statusText = 'stopped';
      });
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  Widget _buildControls() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _speechEnabled ? _listen : null,
          icon: Icon(_isListening ? Icons.stop : Icons.mic),
          label: Text(_isListening ? 'Stop' : 'Mulai'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isListening ? Colors.red : null,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        if (!_speechEnabled)
          Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _text = 'Mencoba menginisialisasi ulang...';
                    _statusText = 'retrying';
                  });
                  await _initSpeech();
                },
                child: const Text('Retry Init Speech'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: openAppSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Buka Pengaturan App'),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _speechEnabled;
    return Scaffold(
      backgroundColor: Color(0xFFD7E2FD),
      appBar: AppBar(
        titleSpacing: 0,
        title: Center(
          child: const Text(
            'Vocare Report',
            style: TextStyle(fontSize: 20, color: Color(0xFF093275),),
          ),
        ),
        backgroundColor: Color(0xFFD7E2FD),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status: $_statusText',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    _text,
                    style: const TextStyle(fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _buildControls(),
            ),
          ],
        ),
      ),
    );
  }
}
