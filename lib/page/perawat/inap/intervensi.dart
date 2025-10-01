// lib/page/perawat/inap/intervensi.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vocare/page/perawat/inap/laporan.dart'; // Make sure this import is correct

class IntervensiInap extends StatefulWidget {
  final int intervensiId;
  final String token;
  // --- ADDED: Parameters passed from the previous page ---
  final String patientId;
  final String perawatId;
  final String query;
  final int cpptId;

  const IntervensiInap({
    super.key,
    required this.intervensiId,
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
  bool _isLoading = true;
  // --- ADDED: State for the new 'Buat Laporan' button ---
  bool _isPostingLaporan = false;
  Map<String, dynamic>? _intervensiData;
  String? _error;

  static const Color headingBlue = Color(0xFF0F4C81);
  static const Color buttonSave = Color(0xFF009563);

  @override
  void initState() {
    super.initState();
    _fetchIntervensiData();
  }

  Future<void> _fetchIntervensiData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final base = dotenv.env['API_URL'] ?? dotenv.env['API_BASE_URL'] ?? '';
      if (base.isEmpty) throw Exception('API URL tidak ditemukan di .env');

      final url = Uri.parse('$base/intervensi/${widget.intervensiId}');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is Map<String, dynamic>) {
          _intervensiData =
              (decodedBody['data'] as Map<String, dynamic>?) ?? decodedBody;
        } else {
          throw Exception('Format respons tidak valid');
        }
      } else {
        throw Exception('Gagal memuat data: Status ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- NEW FUNCTION TO POST LAPORAN ---
  Future<void> _postLaporan() async {
    setState(() => _isPostingLaporan = true);

    final base = dotenv.env['API_URL'] ?? dotenv.env['API_BASE_URL'] ?? '';
    final url = Uri.parse('$base/laporan/');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${widget.token}',
    };
    final body = jsonEncode({
      // Based on your requirement
      "cppt_id": widget.cpptId,
      "patient_id": widget.patientId,
      "perawat_id": widget.perawatId,
      "intevensi_id": widget.intervensiId, // The ID of the current intervensi
      "query": widget.query,
    });

    try {
      debugPrint('POST ${url.toString()} -> $body');
      final response = await http.post(url, headers: headers, body: body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        int? laporanId;
        if (responseBody is Map) {
          laporanId = int.tryParse(
                (responseBody['id'] ?? responseBody['data']?['id'])?.toString() ??
                    '',
              ) ??
              0;
        }
        if (laporanId == 0 || laporanId == null) {
          throw Exception('Gagal mendapatkan ID Laporan dari respons server.');
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaporanTambahan(
              laporanId: laporanId!,
              token: widget.token,
            ),
          ),
        );
      } else {
        throw Exception(
            'Gagal membuat laporan (Status ${response.statusCode}): ${response.body}');
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
        setState(() => _isPostingLaporan = false);
      }
    }
  }


  String formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Intervensi"),
        backgroundColor: const Color(0xFFD7E2FD),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildContent(),
      ),
      // --- ADDED: BOTTOM NAVIGATION BAR FOR 'Buat Laporan' BUTTON ---
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: ElevatedButton(
          onPressed: (_isLoading || _isPostingLaporan) ? null : _postLaporan,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonSave,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isPostingLaporan
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Buat Laporan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Terjadi kesalahan: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchIntervensiData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return intervensiSection();
  }

  Widget intervensiSection() {
    if (_intervensiData == null) {
      return const Center(child: Text('Tidak ada data intervensi.'));
    }

    final iv = _intervensiData!;
    final tanggalRaw = iv['tanggal']?.toString() ?? iv['created_at']?.toString();
    final tanggal = tanggalRaw != null ? formatDate(tanggalRaw) : '-';
    final evaluasi =
        iv['evaluasi']?.toString() ?? iv['evaluation']?.toString() ?? '-';
    final implementasi = iv['implementasi']?.toString() ??
        iv['implementation']?.toString() ??
        '-';

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note, size: 18, color: headingBlue),
                const SizedBox(width: 8),
                Text(
                  tanggal,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Implementasi',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: headingBlue),
            ),
            const SizedBox(height: 6),
            Text(implementasi, style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 16),
            const Text(
              'Evaluasi',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: headingBlue),
            ),
            const SizedBox(height: 6),
            Text(evaluasi, style: const TextStyle(fontSize: 15, height: 1.5)),
          ],
        ),
      ),
    );
  }
}