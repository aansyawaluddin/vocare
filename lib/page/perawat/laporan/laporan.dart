import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vocare/common/type.dart';
import 'package:vocare/page/perawat/laporan/cppt_and_intervensi.dart';

class VocareLaporan extends StatefulWidget {
  final int laporanId;
  final String? token;
  final String reportText;
  final User user;

  const VocareLaporan({
    super.key,
    required this.laporanId,
    this.token,
    required this.reportText,
    required this.user,
  });

  @override
  State<VocareLaporan> createState() => _VocareLaporanState();
}

class _VocareLaporanState extends State<VocareLaporan> {
  static const background = Color.fromARGB(255, 223, 240, 255);
  static const cardBorder = Color(0xFFCED7E8);
  static const headingBlue = Color(0xFF0F4C81);
  static const titleColor = Colors.green;
  static const appBarBackground = Color(0xFFD7E2FD);

  Map<String, dynamic>? _laporanData;
  bool _isLoading = true;
  String? _error;
  bool _isUpdatingLaporan = false;

  bool _isPostingCppt = false;

  late final TextEditingController _sdkiController;
  late final TextEditingController _slkiController;
  late final TextEditingController _sikiController;
  late final TextEditingController _tindakanLanjutanController;

  late final String _baseUrl;

  @override
  void initState() {
    super.initState();
    _baseUrl = _baseUrlFromEnv();
    _sdkiController = TextEditingController();
    _slkiController = TextEditingController();
    _sikiController = TextEditingController();
    _tindakanLanjutanController = TextEditingController();

    _fetchLaporan();
  }

  @override
  void dispose() {
    _sdkiController.dispose();
    _slkiController.dispose();
    _sikiController.dispose();
    _tindakanLanjutanController.dispose();
    super.dispose();
  }

  String _baseUrlFromEnv() {
    return dotenv.env['API_BASE_URL'] ?? dotenv.env['API_URL'] ?? '';
  }

  Map<String, String> _buildHeaders({bool isPutting = false}) {
    final headers = {
      'Accept': 'application/json',
      if (isPutting) 'Content-Type': 'application/json',
    };
    if (widget.token != null && widget.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${widget.token}';
    }
    return headers;
  }

  String _formatContentToList(String? content) {
    if (content == null || content.isEmpty || content == '[]') {
      return '';
    }

    List<String> lines = [];

    try {
      if (content.trim().startsWith('[') && content.trim().endsWith(']')) {
        List<dynamic> list = jsonDecode(content);
        lines = list.map((e) => e.toString().trim()).toList();
      } else {
        String cleaned = content.replaceAll(RegExp(r'[\[\]"]'), '');
        lines = cleaned.split(',').map((e) => e.trim()).toList();
      }

      List<String> cleanLines = lines
          .map((line) {
            String noNumber = line.replaceAll(
              RegExp(r'^\d+(\.\d+)*\s*\.?\s*'),
              '',
            );
            return noNumber.trim();
          })
          .where((line) => line.isNotEmpty)
          .toList();

      return cleanLines.join('\n');
    } catch (e) {
      return content.replaceAll(RegExp(r'^\d+\.\s*', multiLine: true), '');
    }
  }

  Future<void> _fetchLaporan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final url = '$_baseUrl/laporan/${widget.laporanId}';

    try {
      if (kDebugMode) debugPrint('GET $url');
      final response = await http.get(Uri.parse(url), headers: _buildHeaders());

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final data = body.containsKey('data') && body['data'] is Map
            ? body['data']
            : body;

        setState(() {
          _laporanData = data;
          _sdkiController.text = _formatContentToList(data['SDKI']?.toString());
          _slkiController.text = _formatContentToList(data['SLKI']?.toString());
          _sikiController.text = _formatContentToList(data['SIKI']?.toString());
          _tindakanLanjutanController.text =
              data['tindakan_lanjutan']?.toString() ??
              data['plan']?.toString() ??
              '';
        });
      } else {
        throw Exception('Gagal memuat laporan: Status ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLaporan() async {
    setState(() => _isUpdatingLaporan = true);

    final url = '$_baseUrl/laporan/${widget.laporanId}';
    final headers = _buildHeaders(isPutting: true);

    final body = jsonEncode({
      'SDKI': _sdkiController.text,
      'SLKI': _slkiController.text,
      'SIKI': _sikiController.text,
    });

    try {
      if (kDebugMode) debugPrint('PUT $url -> $body');
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(
          'Gagal memperbarui laporan: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingLaporan = false);
    }
  }

  Future<void> _processCppt() async {
    if (_laporanData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data laporan belum siap.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPostingCppt = true);

    final url = '$_baseUrl/cppt/';
    final headers = _buildHeaders(isPutting: true);

    int patientId =
        int.tryParse(_laporanData!['patient_id']?.toString() ?? '0') ?? 0;

    final body = jsonEncode({
      "patient_id": patientId,
      "query": widget.reportText,
    });

    try {
      if (kDebugMode) debugPrint('POST CPPT $url -> $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        int? newCpptId;
        if (data.containsKey('id')) {
          newCpptId = int.tryParse(data['id'].toString());
        } else if (data.containsKey('data') && data['data'] is Map) {
          newCpptId = int.tryParse(data['data']['id'].toString());
        }

        if (newCpptId == null)
          throw Exception("ID CPPT tidak ditemukan di response.");

        int perawatId =
            int.tryParse(
              _laporanData!['perawat_id']?.toString() ??
                  _laporanData!['user_id']?.toString() ??
                  '0',
            ) ??
            0;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VocareReport3(
              cpptId: newCpptId!,
              patientId: patientId,
              perawatId: perawatId,
              query: widget.reportText,
              token: widget.token,
              user: widget.user,
            ),
          ),
        );
      } else {
        throw Exception(
          "Gagal POST CPPT (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error CPPT: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPostingCppt = false);
    }
  }

  Widget _buildSection(String title, TextEditingController controller) {
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
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(height: 1.4, fontSize: 16),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: headingBlue, width: 2),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    if (_laporanData == null)
      return const Center(child: Text('Tidak ada data laporan ditemukan.'));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSection(
          'SDKI (Standar Diagnosis Keperawatan Indonesia)',
          _sdkiController,
        ),
        _buildSection(
          'SLKI (Standar Luaran Keperawatan Indonesia)',
          _slkiController,
        ),
        _buildSection(
          'SIKI (Standar Intervensi Keperawatan Indonesia)',
          _sikiController,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isBusy = _isLoading || _isUpdatingLaporan || _isPostingCppt;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        titleSpacing: 60,
        title: const Text(
          'Hasil Laporan',
          style: TextStyle(fontSize: 20, color: Color(0xFF093275)),
        ),
        backgroundColor: appBarBackground,
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: Row(
          children: [
            // Tombol Simpan
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isBusy ? null : _updateLaporan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: headingBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUpdatingLaporan
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Simpan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Tombol CPPT
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isBusy
                      ? null
                      : _processCppt, // Menggunakan fungsi POST baru
                  style: ElevatedButton.styleFrom(
                    backgroundColor: titleColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isPostingCppt
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'CPPT',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
