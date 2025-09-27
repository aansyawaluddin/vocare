import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/page/perawat/inap/detail_laporan.dart';
import 'package:vocare/page/perawat/inap/voice.dart';

class DaftarRiwayatAdminPage extends StatefulWidget {
  final User user;
  final String patientId;
  final String patientName;
  final String noRekamMedis;

  const DaftarRiwayatAdminPage({
    super.key,
    required this.user,
    required this.patientId,
    required this.patientName,
    required this.noRekamMedis,
  });

  @override
  State<DaftarRiwayatAdminPage> createState() => _DaftarRiwayatPageState();
}

class _DaftarRiwayatPageState extends State<DaftarRiwayatAdminPage> {
  bool _isLoading = true;
  String? _error;
  List<Laporan> _laporanList = [];

  // --- Constants for UI styling ---
  static const background = Color(0xFFDFF0FF);
  static const cardBorder = Color(0xFFCED7E8);
  static const headingBlue = Color(0xFF0F4C81);
  static const buttonTambah = Color(0xFF093275);
  static const textPrimary = Color(0xFF083B74);

  @override
  void initState() {
    super.initState();
    _fetchLaporan();
  }

  String _getBaseUrl() {
    return dotenv.env['API_URL'] ?? dotenv.env['API_BASE_URL'] ?? '';
  }

  Map<String, String> _getAuthHeaders() {
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${widget.user.token}',
    };
  }

  Future<void> _fetchLaporan() async {
    if (widget.patientId.isEmpty || widget.patientId == '-') {
      setState(() {
        _error = 'ID Pasien tidak valid.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final base = _getBaseUrl();
      final uri = Uri.parse('$base/laporan').replace(
        queryParameters: {'patient_id': widget.patientId},
      );

      final response = await http.get(uri, headers: _getAuthHeaders());

      if (response.statusCode != 200) {
        throw Exception('Gagal memuat laporan: Status Code ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      final List<dynamic> data = (body is Map && body.containsKey('data')) ? body['data'] : body;

      final allLaporan = data.map((json) => Laporan.fromJson(json)).toList();

      final filteredLaporan = allLaporan.where((l) => l.patientId == widget.patientId).toList();

      filteredLaporan.sort(
        (a, b) => (b.tanggal ?? DateTime(0)).compareTo(a.tanggal ?? DateTime(0)),
      );

      setState(() {
        _laporanList = filteredLaporan;
      });
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Tanpa Tanggal';
    try {
      return DateFormat('d MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return dt.toIso8601String();
    }
  }

  String _truncate(String? text, [int len = 120]) {
    if (text == null || text.isEmpty) return '-';
    return text.length <= len ? text : text.substring(0, len) + '...';
  }

  Widget _buildReportCard(Laporan laporan) {
    final String title = _formatDate(laporan.tanggal);

    final subj = laporan.subjective ?? '-';
    final obj = laporan.objective ?? '-';
    final ass = laporan.assessment ?? '-';
    final plan = laporan.plan ?? '-';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetaiRiwayatPage(
                laporan: laporan,
                user: widget.user,
                patientId: widget.patientId,
                patientName: widget.patientName,
                noRekamMedis: widget.noRekamMedis,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: headingBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('S: $subj', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              Text('O: $obj', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              Text('A: $ass', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              Text('P: $plan', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetaiRiwayatPage(
                          laporan: laporan,
                          user: widget.user,
                          patientId: widget.patientId,
                          patientName: widget.patientName,
                          noRekamMedis: widget.noRekamMedis,
                        ),
                      ),
                    );
                  },
                  child: const Text('Lihat selengkapnya'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 18, top: 10),
        itemBuilder: (context, index) => Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: cardBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: 5,
      );
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_laporanList.isEmpty) {
      return const Center(child: Text('Belum ada laporan untuk pasien ini.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchLaporan,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 18, top: 10),
        itemCount: _laporanList.length,
        itemBuilder: (context, index) {
          final laporan = _laporanList[index];
          return _buildReportCard(laporan);
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: background,
        centerTitle: true,
        title: const Text(
          'Daftar Laporan',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.patientName} (RM: ${widget.noRekamMedis})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: buttonTambah,
                ),
              ),
              const SizedBox(height: 15),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }
}
