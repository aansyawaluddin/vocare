import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class IntervensiInap extends StatefulWidget {
  final String token;
  final String patientId;
  final String perawatId;
  final String query; // Query awal tetap dibawa untuk referensi
  final int cpptId;

  // Tambahkan parameter optional untuk prefill
  final String? initialImplementasi;
  final String? initialEvaluasi;

  const IntervensiInap({
    super.key,
    required this.token,
    required this.patientId,
    required this.perawatId,
    required this.query,
    required this.cpptId,
    this.initialImplementasi,
    this.initialEvaluasi,
  });

  @override
  State<IntervensiInap> createState() => _IntervensiInapState();
}

class _IntervensiInapState extends State<IntervensiInap> {
  late final TextEditingController _implementasiController;
  late final TextEditingController _evaluasiController;
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;

  static const Color headingBlue = Color(0xFF0F4C81);
  static const Color buttonSave = Color(0xFF009563);

  @override
  void initState() {
    super.initState();
    // Initialize controllers with initial values jika ada
    _implementasiController = TextEditingController(
      text:
          widget.initialImplementasi != null &&
              widget.initialImplementasi!.isNotEmpty
          ? widget.initialImplementasi
          : '',
    );
    _evaluasiController = TextEditingController(
      text: widget.initialEvaluasi != null && widget.initialEvaluasi!.isNotEmpty
          ? widget.initialEvaluasi
          : '',
    );
  }

  @override
  void dispose() {
    _implementasiController.dispose();
    _evaluasiController.dispose();
    super.dispose();
  }

  Future<void> _submitIntervensi() async {
    // Validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final base = dotenv.env['API_URL'] ?? dotenv.env['API_BASE_URL'] ?? '';
      if (base.isEmpty) throw Exception('API URL tidak ditemukan di .env');

      final url = Uri.parse('$base/intervensi/');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

      final body = jsonEncode({
        'patient_id': widget.patientId,
        'user_id': widget.perawatId,
        'cppt_id': widget.cpptId,
        'implementasi': _implementasiController.text,
        'evaluasi': _evaluasiController.text,
      });

      if (kDebugMode) {
        debugPrint('--- [MENGIRIM INTERVENSI BARU] ---');
        debugPrint('URL    : POST $url');
        debugPrint('BODY   : $body');
        debugPrint('---------------------------------');
      }

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Intervensi berhasil disimpan!'),
              backgroundColor: Colors.green,
            ),
          );


          int count = 0;
          Navigator.of(context).popUntil((_) => count++ >= 4);
        }
      } else {
        throw Exception(
          'Gagal membuat data intervensi: Status ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // _postLaporan SUDAH DIHAPUS

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Implementasi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: headingBlue,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _implementasiController,
            maxLines: 8, // Sedikit diperbesar
            decoration: const InputDecoration(
              hintText: 'Masukkan detail implementasi...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Implementasi tidak boleh kosong';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Evaluasi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: headingBlue,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _evaluasiController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Masukkan detail evaluasi...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Evaluasi tidak boleh kosong';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Intervensi Baru"),
        centerTitle: true,
        backgroundColor: const Color(0xFFD7E2FD),
      ),
      backgroundColor: const Color(0xFFD7E2FD),
      body: Stack(
        children: [
          _buildForm(),

          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitIntervensi,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonSave,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Simpan Intervensi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
