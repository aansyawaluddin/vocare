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
  static const buttonUpdate = Color(0xFF007BFF); // ADDED

  Map<String, dynamic>? _laporanData;
  bool _isLoading = true;
  bool _isUpdating = false; // ADDED: State for update process
  String? _error;

  // ADDED: Controllers for editable fields
  late final TextEditingController _sdkiController;
  late final TextEditingController _slkiController;
  late final TextEditingController _sikiController;
  late final TextEditingController _tindakanLanjutanController;

  @override
  void initState() {
    super.initState();
    // ADDED: Initialize controllers
    _sdkiController = TextEditingController();
    _slkiController = TextEditingController();
    _sikiController = TextEditingController();
    _tindakanLanjutanController = TextEditingController();
    _fetchLaporan();
  }

  // ADDED: Dispose controllers to prevent memory leaks
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

  Map<String, String> _buildHeaders({bool isJsonContent = false}) {
    // MODIFIED: Added isJsonContent parameter
    final headers = {'Accept': 'application/json'};
    if (isJsonContent) {
      headers['Content-Type'] = 'application/json';
    }
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
          // ADDED: Populate controllers with data from API
          _sdkiController.text = _formatContentToList(data['SDKI']?.toString());
          _slkiController.text = _formatContentToList(data['SLKI']?.toString());
          _sikiController.text = _formatContentToList(data['SIKI']?.toString());
          _tindakanLanjutanController.text = _formatContentToList(
            data['tindakan_lanjutan']?.toString(),
          );
        });
      } else {
        throw Exception('Gagal memuat laporan: Status ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ADDED: Function to update the report via PUT request
  Future<void> _updateLaporan() async {
    setState(() => _isUpdating = true);

    final url = '${_baseUrlFromEnv()}/laporan/${widget.laporanId}';
    final headers = _buildHeaders(isJsonContent: true);
    final body = jsonEncode({
      'SDKI': _formatTextToApi(_sdkiController.text),
      'SLKI': _formatTextToApi(_slkiController.text),
      'SIKI': _formatTextToApi(_sikiController.text),
      'tindakan_lanjutan': _formatTextToApi(_tindakanLanjutanController.text),
    });

    try {
      if (kDebugMode) debugPrint('PUT $url -> $body');
      final response =
          await http.put(Uri.parse(url), headers: headers, body: body);

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
        setState(() => _isUpdating = false);
      }
    }
  }

  /// Converts API string e.g., `{"Item 1","Item 2"}` to a numbered list.
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

  /// ADDED: Converts a numbered list string back to the API format.
  String _formatTextToApi(String text) {
    if (text.trim().isEmpty || text.trim() == 'Tidak ada data') {
      return '{}';
    }
    // Split by new line, remove numbering, trim, and filter out empty lines
    final items = text
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'^\d+\.\s*'), '').trim())
        .where((item) => item.isNotEmpty)
        .toList();
    // Enclose each item in quotes and join with a comma
    final quotedItems = items.map((item) => '"$item"').join(',');
    // Return in the {"item1","item2"} format
    return '{$quotedItems}';
  }

  // MODIFIED: This widget now takes a controller for editable content.
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
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(height: 1.4, fontSize: 16),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
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
        // MODIFIED: Using controllers instead of raw data strings.
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
        _buildSection('Tindakan Lanjutan', _tindakanLanjutanController),
      ],
    );
  }
  
  // ADDED: Helper for creating loading buttons
  Widget _buildLoadingButton(
      {required bool isLoading,
      required VoidCallback? onPressed,
      required String text,
      required String loadingText,
      required Color color}) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    padding: const EdgeInsets.all(2.0),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(loadingText)
                ],
              )
            : Text(text,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isActionInProgress = _isLoading || _isUpdating;

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
      // MODIFIED: Added a Row with two buttons.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: Row(
          children: [
            Expanded(
              child: _buildLoadingButton(
                isLoading: _isUpdating,
                onPressed: isActionInProgress ? null : _updateLaporan,
                text: 'Simpan Perubahan',
                loadingText: 'Menyimpan...',
                color: buttonUpdate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isActionInProgress
                    ? null
                    : () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: titleColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
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
          ],
        ),
      ),
    );
  }
}
