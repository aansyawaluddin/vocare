import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class LaporanTambahan extends StatefulWidget {
  final int laporanId;
  final String? token;

  const LaporanTambahan({super.key, required this.laporanId, this.token});

  @override
  State<LaporanTambahan> createState() => _LaporanTambahanState();
}

class _LaporanTambahanState extends State<LaporanTambahan> {
  static const background = Color.fromARGB(255, 223, 240, 255);
  static const cardBorder = Color(0xFFCED7E8);
  static const headingBlue = Color(0xFF0F4C81);
  static const titleColor = Color(0xFF093275);
  static const appBarBackground = Color(0xFFD7E2FD);

  Map<String, dynamic>? _laporanData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLaporan();
  }

  String _baseUrlFromEnv() {
    return dotenv.env['API_BASE_URL'] ??
        dotenv.env['API_URL'] ??
        'http://your-api-host';
  }

  Map<String, String> _buildHeaders() {
    final headers = {'Accept': 'application/json'};
    if (widget.token != null && widget.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${widget.token}';
    }
    return headers;
  }

  Future<void> _fetchLaporan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final url = '${_baseUrlFromEnv()}/laporan/${widget.laporanId}';

    try {
      if (kDebugMode) debugPrint('GET $url');
      final response = await http.get(Uri.parse(url), headers: _buildHeaders());

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        setState(() {
          // Ambil data dari dalam key "data" jika ada
          _laporanData = body.containsKey('data') && body['data'] is Map
              ? body['data']
              : body;
        });
      } else {
        throw Exception('Gagal memuat laporan: Status ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Membersihkan string dari API dan mengubahnya menjadi daftar bernomor.
  String _formatContentToList(String? content) {
    if (content == null || content.isEmpty || content == '{}') {
      return 'Tidak ada data';
    }

    // 1. Hapus kurung kurawal di awal dan akhir
    String cleaned = content.replaceAll(RegExp(r'^\{|\}$'), '');

    // 2. Pisahkan setiap item berdasarkan koma
    List<String> items = cleaned.split(',');

    // 3. Bersihkan setiap item dari tanda kutip dan spasi, lalu beri nomor
    List<String> formattedItems = [];
    for (int i = 0; i < items.length; i++) {
      String item = items[i]
          .trim() // Hapus spasi
          .replaceAll(RegExp(r'^"|"'), ''); // Hapus tanda kutip
      if (item.isNotEmpty) {
        formattedItems.add('${i + 1}. $item');
      }
    }

    // 4. Gabungkan kembali dengan pemisah baris baru
    return formattedItems.join('\n');
  }

  Widget _buildSection(String title, String? content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: cardBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: headingBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content ?? 'Tidak ada data',
            style: const TextStyle(height: 1.4, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (_laporanData == null) {
      return const Center(child: Text('Tidak ada data laporan ditemukan.'));
    }

    final data = _laporanData!;
    // Kode BARU di dalam _buildBody()

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSection(
          'SDKI (Standar Diagnosis Keperawatan Indonesia)',
          _formatContentToList(data['SDKI']?.toString()), 
        ),
        _buildSection(
          'SLKI (Standar Luaran Keperawatan Indonesia)',
          _formatContentToList(data['SLKI']?.toString()), 
        ),
        _buildSection(
          'SIKI (Standar Intervensi Keperawatan Indonesia)',
          _formatContentToList(data['SIKI']?.toString()), 
        ),
        _buildSection(
          'Tindakan Lanjutan',
          _formatContentToList(
            data['tindakan_lanjutan']?.toString(),
          ), 
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        titleSpacing: 60,
        title: const Text(
          'Hasil Laporan',
          style: TextStyle(fontSize: 20, color: titleColor),
        ),
        backgroundColor: appBarBackground,
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: titleColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Selesai',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
