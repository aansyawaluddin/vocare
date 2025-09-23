// lib/page/perawat/laporan/report.dart (atau sesuai strukturmu)
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vocare/page/perawat/laporan/assesments.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VocareReport extends StatefulWidget {
  final String reportText;
  final String username;
  final String token;

  const VocareReport({
    super.key,
    required this.reportText,
    required this.username,
    required this.token,
  });

  @override
  State<VocareReport> createState() => _VocareReportState();
}

class _VocareReportState extends State<VocareReport> {
  late TextEditingController _controller;
  late String _currentText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentText = widget.reportText;
    _controller = TextEditingController(text: _currentText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Fungsi untuk melakukan POST ke server /assesments/ (sesuaikan dengan kebutuhan)
  Future<Map<String, dynamic>?> _postAssessment({
    required String perawat,
    required String query,
  }) async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? dotenv.env['API_URL'] ?? 'http://your-api-host';
    final candidates = [
      '$baseUrl/assesments/',
    ];

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (widget.token.isNotEmpty) 'Authorization': 'Bearer ${widget.token}',
    };

    final body = jsonEncode({'perawat': perawat, 'query': query});

    http.Response? lastResponse;
    for (final url in candidates) {
      try {
        if (kDebugMode) debugPrint('POST $url -> $body');
        final response = await http.post(Uri.parse(url), headers: headers, body: body);
        lastResponse = response;

        if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
          if (response.body.isEmpty) return {};
          final Map<String, dynamic> data = jsonDecode(response.body);
          return data;
        } else if (response.statusCode == 404) {
          if (kDebugMode) debugPrint('Endpoint not found: $url (404). Trying next candidate...');
          continue;
        } else {
          String msg;
          try {
            final parsed = jsonDecode(response.body);
            msg = parsed is Map && parsed['message'] != null ? parsed['message'].toString() : response.body;
          } catch (_) {
            msg = response.body;
          }
          throw Exception('Request failed (${response.statusCode}): $msg');
        }
      } catch (e) {
        if (url == candidates.last) rethrow;
        if (kDebugMode) debugPrint('Error posting to $url: $e — mencoba endpoint lain');
      }
    }

    if (lastResponse != null) {
      throw Exception('Request failed with status ${lastResponse.statusCode}');
    }

    return null;
  }

  Future<void> _submitAndNext() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _postAssessment(
        perawat: widget.username,
        query: _currentText,
      );

      if (!mounted) return;

      // Navigasi ke VocareReport2, pastikan token & username diteruskan
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VocareReport2(
            reportText: _currentText,
            apiResponse: result,
            username: widget.username,
            token: widget.token,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal kirim laporan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEditSheet() {
    showModalBottomSheet(
      backgroundColor: const Color(0xFFDFF0FF),
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final sheetHeight = MediaQuery.of(context).size.height * 0.5;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Laporan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF083B74),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: sheetHeight,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    hintText: 'Masukkan teks laporan...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentText = _controller.text;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFDFF0FF);
    const cardBorder = Color(0xFFCED7E8);
    const headingBlue = Color(0xFF0F4C81);
    const lightButtonBlue = Color(0xFF7FB0FF);
    const darkButtonBlue = Color(0xFF083B74);

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
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
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hasil Transkrip Voice:',
                          style: TextStyle(
                            color: headingBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _currentText,
                          style: const TextStyle(height: 1.4, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _showEditSheet,
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lightButtonBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitAndNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkButtonBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Text(
                                'Next',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}
