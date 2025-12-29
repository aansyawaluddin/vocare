import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class VocareLaporan extends StatefulWidget {
  final int laporanId;
  final String? token;

  const VocareLaporan({super.key, required this.laporanId, this.token});

  @override
  State<VocareLaporan> createState() => _VocareLaporanState();
}

class _VocareLaporanState extends State<VocareLaporan> {
  static const background = Color.fromARGB(255, 223, 240, 255);
  static const cardBorder = Color(0xFFCED7E8);
  static const headingBlue = Color(0xFF0F4C81);
  static const titleColor = Color(0xFF093275);
  static const appBarBackground = Color(0xFFD7E2FD);

  Map<String, dynamic>? _laporanData;
  bool _isLoading = true;
  String? _error;
  bool _isUpdatingLaporan = false;

  late final TextEditingController _sdkiController;
  late final TextEditingController _slkiController;
  late final TextEditingController _sikiController;
  late final TextEditingController _tindakanLanjutanController;

  @override
  void initState() {
    super.initState();
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
    return dotenv.env['API_BASE_URL'] ??
        dotenv.env['API_URL'] ??
        'http://your-api-host';
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
        final data = body.containsKey('data') && body['data'] is Map
            ? body['data']
            : body;
        setState(() {
          _laporanData = data;
          // MODIFICATION: Populate controllers with data from the API
          _sdkiController.text = data['SDKI']?.toString() ?? '';
          _slkiController.text = data['SLKI']?.toString() ?? '';
          _sikiController.text = data['SIKI']?.toString() ?? '';
          _tindakanLanjutanController.text = data['tindakan_lanjutan']?.toString() ?? '';
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

  Future<void> _updateLaporan() async {
    setState(() => _isUpdatingLaporan = true);

    final url = '${_baseUrlFromEnv()}/laporan/${widget.laporanId}';
    final headers = _buildHeaders(isPutting: true);
    final body = jsonEncode({
      'SDKI': _sdkiController.text,
      'SLKI': _slkiController.text,
      'SIKI': _sikiController.text,
      'tindakan_lanjutan': _tindakanLanjutanController.text,
    });

    try {
      if (kDebugMode) debugPrint('PUT $url -> $body');
      final response = await http.put(Uri.parse(url), headers: headers, body: body);

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
            'Gagal memperbarui laporan: Status ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingLaporan = false);
      }
    }
  }


  String _formatContentToList(String? content) {
    if (content == null || content.isEmpty || content == '{}') {
      return 'Tidak ada data';
    }
    String cleaned = content.replaceAll(RegExp(r'^\{|\}$'), '');
    List<String> items = cleaned.split(',');
    List<String> formattedItems = [];
    for (int i = 0; i < items.length; i++) {
      String item = items[i].trim().replaceAll(RegExp(r'^"|"'), '');
      if (item.isNotEmpty) {
        formattedItems.add('${i + 1}. $item');
      }
    }
    return formattedItems.join('\n');
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
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
        _buildSection(
          'Tindakan Lanjutan',
          _tindakanLanjutanController,
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
        child: Row(
          children: [
            // Save Button
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isUpdatingLaporan) ? null : _updateLaporan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: headingBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isUpdatingLaporan)
                      ? null
                      : () {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: titleColor,
                    foregroundColor: Colors.white,
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
            ),
          ],
        ),
      ),
    );
  }
}