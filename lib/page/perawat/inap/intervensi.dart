import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vocare/page/perawat/inap/laporan.dart';

class IntervensiInap extends StatefulWidget {
  final String token;
  final String patientId;
  final String perawatId;
  final String query; // Query awal tetap dibawa untuk referensi
  final int cpptId;

  const IntervensiInap({
    super.key,
    required this.token,
    required this.patientId,
    required this.perawatId,
    required this.query,
    required this.cpptId,
  });

  @override
  State<IntervensiInap> createState() => _IntervensiInapState();
}

class _IntervensiInapState extends State<IntervensiInap> {
  // --- MODIFIED: Added controllers for the form fields ---
  late final TextEditingController _implementasiController;
  late final TextEditingController _evaluasiController;
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;

  static const Color headingBlue = Color(0xFF0F4C81);
  static const Color buttonSave = Color(0xFF009563);

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _implementasiController = TextEditingController();
    _evaluasiController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _implementasiController.dispose();
    _evaluasiController.dispose();
    super.dispose();
  }

  // --- NEW: FUNCTION TO SUBMIT THE INTERVENTION FORM ---
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

      // --- MODIFIED: Body now uses controller text ---
      final body = jsonEncode({
        'patient_id': widget.patientId,
        'user_id': widget.perawatId,
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
        final decodedBody = jsonDecode(response.body);
        final dynamic newIntervensiId = (decodedBody is Map)
            ? (decodedBody['data']?['id'] ?? decodedBody['id'])
            : null;

        if (newIntervensiId == null) {
          throw Exception('Gagal mendapatkan ID Intervensi dari server.');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Intervensi berhasil disimpan!'),
              backgroundColor: Colors.green,
            ),
          );
          // After submitting intervention, proceed to post the report
          await _postLaporan(newIntervensiId);
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

  // --- MODIFIED: This function now accepts the intervensiId ---
  Future<void> _postLaporan(dynamic intervensiId) async {
    final base = dotenv.env['API_URL'] ?? dotenv.env['API_BASE_URL'] ?? '';
    final url = Uri.parse('$base/laporan/');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${widget.token}',
    };
    final body = jsonEncode({
      "cppt_id": widget.cpptId,
      "patient_id": widget.patientId,
      "perawat_id": widget.perawatId,
      "intevensi_id": intervensiId,
      "query": widget.query,
    });

    try {
      debugPrint('POST ${url.toString()} -> $body');
      final response = await http.post(url, headers: headers, body: body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        final int? laporanId = int.tryParse(
          (responseBody['data']?['id'] ?? responseBody['id'])?.toString() ?? '',
        );

        if (laporanId == null) {
          throw Exception('Gagal mendapatkan ID Laporan dari respons server.');
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LaporanTambahan(laporanId: laporanId, token: widget.token),
          ),
        );
      } else {
        throw Exception(
          'Gagal membuat laporan (Status ${response.statusCode}): ${response.body}',
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Intervensi Baru"),
        backgroundColor: const Color(0xFFD7E2FD),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // --- MODIFIED: Body is now a form ---
        child: Form(
          key: _formKey,
          child: ListView(
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
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Masukkan detail implementasi...',
                  border: OutlineInputBorder(),
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
        ),
      ),
      // --- MODIFIED: Bottom button now submits the form ---
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
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Simpan Intervensi & Buat Laporan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}
