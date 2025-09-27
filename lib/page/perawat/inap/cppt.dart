import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vocare/page/perawat/inap/report.dart';

class CpptTambahan extends StatefulWidget {
  final int cpptId;
  final String patientId;
  final String perawatId;
  final String query;
  final String? token;

  const CpptTambahan({
    super.key,
    required this.cpptId,
    required this.patientId,
    required this.perawatId,
    required this.query,
    this.token,
  });

  @override
  State<CpptTambahan> createState() => _CpptTambahanState();
}

class _CpptTambahanState extends State<CpptTambahan> {
  static const background = Color.fromARGB(255, 223, 240, 255);
  static const cardBorder = Color(0xFFCED7E8);
  static const headingBlue = Color(0xFF0F4C81);
  static const buttonSave = Color(0xFF009563);

  Map<String, dynamic>? _cpptData;
  bool _isLoading = false;
  bool _isLoadingCppt = false;
  bool _isPostingLaporan = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCppt();
  }

  String _baseUrlFromEnv() {
    return dotenv.env['API_BASE_URL'] ??
        dotenv.env['API_URL'] ??
        'http://your-api-host';
  }

  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (widget.token != null && widget.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${widget.token}';
    }
    return headers;
  }

  Future<void> _fetchCppt() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final url = '${_baseUrlFromEnv()}/cppt/${widget.cpptId}';

    try {
      if (kDebugMode) debugPrint('GET $url');
      final resp = await http.get(Uri.parse(url), headers: _buildHeaders());
      if (kDebugMode) debugPrint('Fetch CPPT ${resp.statusCode}: ${resp.body}');

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(resp.body);
        Map<String, dynamic> obj = {};
        if (data.containsKey('data') && data['data'] is Map) {
          obj = Map<String, dynamic>.from(data['data']);
        } else {
          obj = data;
        }
        setState(() {
          _cpptData = obj;
        });
      } else {
        String msg = resp.body;
        try {
          final parsed = jsonDecode(resp.body);
          if (parsed is Map && parsed['message'] != null)
            msg = parsed['message'].toString();
        } catch (_) {}
        setState(() {
          _error = 'Gagal mengambil CPPT: ${resp.statusCode} - $msg';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal mengambil CPPT: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _postLaporan() async {
    setState(() => _isPostingLaporan = true);

    final url = '${_baseUrlFromEnv()}/laporan/';
    final headers = _buildHeaders();
    final body = jsonEncode({
      "cppt_id": widget.cpptId,
      "patient_id": widget.patientId,
      "perawat_id": widget.perawatId,
      "query": widget.query,
    });

    try {
      if (kDebugMode) debugPrint('POST $url -> $body');
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        int? laporanId;
        if (data.containsKey('id')) {
          laporanId = int.tryParse(data['id'].toString());
        } else if (data.containsKey('data') &&
            data['data'] is Map &&
            data['data']['id'] != null) {
          laporanId = int.tryParse(data['data']['id'].toString());
        }

        if (laporanId == null) {
          throw Exception('Gagal mendapatkan ID Laporan dari response server.');
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LaporanTambahan(laporanId: laporanId!, token: widget.token),
          ),
        );
      } else {
        String msg = response.body;
        try {
          final parsed = jsonDecode(response.body);
          if (parsed is Map && parsed['message'] != null)
            msg = parsed['message'].toString();
        } catch (_) {}
        throw Exception(
          'Gagal mengirim laporan (${response.statusCode}): $msg',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPostingLaporan = false);
      }
    }
  }

  Widget section(String title, {required Widget child}) {
    return Container(
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
          const SizedBox(height: 6),
          child,
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (widget.cpptId == 0 && _cpptData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.info_outline, size: 48),
              SizedBox(height: 12),
              Text('CPPT dibuat, tetapi cppt_id tidak tersedia dari server.'),
            ],
          ),
        ),
      );
    }

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_cpptData == null)
      return const Center(child: Text('Tidak ada data CPPT'));

    final d = _cpptData!;

    String formatDate(String? iso) {
      if (iso == null) return '-';
      try {
        final dt = DateTime.parse(iso);
        return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        return iso;
      }
    }

    Widget buildSignature(String? sig) {
      if (sig == null || sig.isEmpty) return const SizedBox.shrink();
      try {
        if (sig.startsWith('http')) {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Image.network(sig, fit: BoxFit.contain),
          );
        }

        final idx = sig.indexOf('base64,');
        String payload = sig;
        if (idx >= 0) payload = sig.substring(idx + 7);
        final bytes = base64Decode(payload);
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Image.memory(bytes, fit: BoxFit.contain),
        );
      } catch (e) {
        return const SizedBox.shrink();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 18, top: 10),
        children: [
          const SizedBox(height: 6),
          Text(
            'CPPT ${d['id'] ?? ''} ${formatDate(d['tanggal']?.toString())} ${d['user_id'] ?? ''}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0XFF093275),
            ),
          ),
          const SizedBox(height: 5),
          section(
            'Subjective',
            child: Text(
              d['subjective']?.toString() ?? '-',
              style: const TextStyle(height: 1.4, fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),
          section(
            'Objective',
            child: Text(
              d['objective']?.toString() ?? '-',
              style: const TextStyle(height: 1.4, fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),
          section(
            'Assessment',
            child: Text(
              d['assessment']?.toString() ?? '-',
              style: const TextStyle(height: 1.4, fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),
          section(
            'Plan',
            child: Text(
              d['plan']?.toString() ?? '-',
              style: const TextStyle(height: 1.4, fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),
          section(
            'Keterangan',
            child: Text(
              d['keterangan']?.toString() ?? '-',
              style: const TextStyle(height: 1.4, fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),
          if ((d['dokter'] ?? '').toString().isNotEmpty)
            section(
              'Dokter',
              child: Text(
                d['dokter']?.toString() ?? '-',
                style: const TextStyle(height: 1.4, fontSize: 16),
              ),
            ),
          const SizedBox(height: 10),
          if ((d['signature'] ?? '').toString().isNotEmpty)
            section(
              'Tanda Tangan',
              child: buildSignature(d['signature']?.toString()),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        titleSpacing: 60,
        title: const Text(
          'Vocare Report',
          style: TextStyle(fontSize: 20, color: Color(0xFF093275)),
        ),
        backgroundColor: const Color(0xFFD7E2FD),
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: (_isLoadingCppt || _isPostingLaporan)
                  ? null
                  : _postLaporan,
              icon: _isPostingLaporan
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isPostingLaporan ? 'Mengirim...' : 'Buat Laporan',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonSave,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
