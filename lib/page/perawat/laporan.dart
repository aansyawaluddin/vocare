import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/widgets/laporan_widget.dart';

class RiwayatLaporan extends StatefulWidget {
  final User user;

  const RiwayatLaporan({super.key, required this.user});

  @override
  State<RiwayatLaporan> createState() => _RiwayatLaporanState();
}

class _RiwayatLaporanState extends State<RiwayatLaporan> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, String>> _reportsForUI = [];

  // Warna default, bisa disesuaikan
  final Color navyColor = const Color(0xFF093275);
  final Color cardBlueColor = const Color(0xFFD7E2FD);

  @override
  void initState() {
    super.initState();
    _fetchAndProcessReports();
  }

  /// Helper untuk mengambil base URL dari .env
  String _getBaseUrl() {
    return dotenv.env['API_URL'] ?? dotenv.env['API_BASE_URL'] ?? '';
  }

  /// Helper untuk membuat header otentikasi
  Map<String, String> _getAuthHeaders() {
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${widget.user.token}',
    };
  }

  /// Langkah 1: Mengambil daftar laporan dari API
  Future<List<Laporan>> _fetchLaporan() async {
    final url = Uri.parse('${_getBaseUrl()}/laporan/');
    final response = await http.get(url, headers: _getAuthHeaders());

    if (response.statusCode == 200) {
      // API mengembalikan list langsung atau di dalam key 'data'
      dynamic body = jsonDecode(response.body);
      List<dynamic> data = (body is Map && body.containsKey('data')) ? body['data'] : body;
      
      if (data is List) {
        return data.map((json) => Laporan.fromJson(json)).toList();
      } else {
        throw Exception('Format data laporan tidak valid');
      }
    } else {
      throw Exception('Gagal memuat laporan: ${response.statusCode}');
    }
  }

  /// Langkah 2: Mengambil daftar semua pasien dari API
  Future<List<Patient>> _fetchPatients() async {
    final url = Uri.parse('${_getBaseUrl()}/patients/');
    final response = await http.get(url, headers: _getAuthHeaders());

    if (response.statusCode == 200) {
      dynamic body = jsonDecode(response.body);
      List<dynamic> data = (body is Map && body.containsKey('data')) ? body['data'] : body;
      
      if (data is List) {
        return data.map((json) => Patient.fromJson(json)).toList();
      } else {
        throw Exception('Format data pasien tidak valid');
      }
    } else {
      throw Exception('Gagal memuat pasien: ${response.statusCode}');
    }
  }

  /// Langkah 3: Menggabungkan data dan mempersiapkannya untuk UI
  Future<void> _fetchAndProcessReports() async {
    try {
      // Ambil kedua data secara bersamaan
      final List<Laporan> laporanList = await _fetchLaporan();
      final List<Patient> patientList = await _fetchPatients();

      // Ubah list pasien menjadi map untuk pencarian cepat (O(1) average time complexity)
      final patientMap = {for (var p in patientList) p.id: p};

      // Proses dan gabungkan data
      final List<Map<String, String>> processedReports = [];
      for (final laporan in laporanList) {
        final patient = patientMap[laporan.patientId];
        
        // Format tanggal agar mudah dibaca
        final formattedDate = laporan.tanggal != null
            ? DateFormat('d MMMM yyyy', 'id_ID').format(laporan.tanggal!)
            : 'Tanggal tidak valid';

        processedReports.add({
          'name': patient?.nama ?? 'Nama Pasien Tidak Ditemukan',
          'date': formattedDate,
        });
      }

      if (!mounted) return;
      setState(() {
        _reportsForUI = processedReports;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Terjadi kesalahan: $_error', textAlign: TextAlign.center),
        ),
      );
    }

    if (_reportsForUI.isEmpty) {
      return const Center(
        child: Text('Belum ada riwayat laporan.'),
      );
    }

    return LaporanWidget(
      reports: _reportsForUI,
      navy: navyColor,
      cardBlue: cardBlueColor,
    );
  }
}