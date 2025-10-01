// lib/page/perawat/inap/review_tambahan.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vocare/common/type.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vocare/page/perawat/inap/cppt.dart';
import 'package:vocare/page/perawat/inap/intervensi.dart';

class ReviewTambahan extends StatefulWidget {
  final User user;
  final String reportText;
  final String patientId;

  const ReviewTambahan({
    super.key,
    required this.user,
    required this.reportText,
    required this.patientId,
  });

  @override
  State<ReviewTambahan> createState() => _ReviewTambahanState();
}

class _ReviewTambahanState extends State<ReviewTambahan> {
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

  String _getBaseUrl() {
    return dotenv.env['API_URL'] ?? dotenv.env['API_BASE_URL'] ?? '';
  }

  Future<void> _submitCppt() async {
    setState(() => _isLoading = true);

    try {
      final base = _getBaseUrl();
      if (base.isEmpty) throw Exception('NO_API');
      final apiUrl = base.endsWith('/') ? '${base}cppt/' : '$base/cppt/';
      final token = widget.user.token ?? '';

      final body = jsonEncode({
        'patient_id': widget.patientId,
        'perawat_id': widget.user.id,
        'query': _currentText,
      });

      if (kDebugMode) {
        debugPrint('--- [MENGIRIM POST KE CPPT] ---');
        debugPrint('URL    : POST $apiUrl');
        debugPrint('BODY   : $body');
        debugPrint('---------------------------------');
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        final responseBody = jsonDecode(response.body);
        int cpptId = 0;
        if (responseBody is Map) {
          cpptId =
              int.tryParse(
                    (responseBody['id'] ??
                                responseBody['cppt_id'] ??
                                responseBody['data']?['id'])
                            ?.toString() ??
                        '0',
                  ) ??
                  0;
        }

        debugPrint('Laporan CPPT berhasil dikirim dengan CPPT ID: $cpptId');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan CPPT berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CpptTambahan(
              cpptId: cpptId,
              token: token,
              patientId: widget.patientId,
              perawatId: widget.user.id,
              query: _currentText,
            ),
          ),
        );
      } else {
        _handleErrorResponse(response);
      }
    } catch (e) {
      _handleGenericError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NEW: FUNCTION TO GET THE LATEST CPPT ID ---
  Future<int?> _getLatestCpptId(String token) async {
    final base = _getBaseUrl();
    if (base.isEmpty) throw Exception('API URL not found');
    final url = Uri.parse('$base/cppt?patient_id=${widget.patientId}');

    debugPrint('--- [MENGAMBIL CPPT TERBARU] ---');
    debugPrint('URL    : GET $url');
    debugPrint('----------------------------------');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(response.body);
      final List<dynamic> cpptList = (decodedBody['data'] as List<dynamic>?) ?? [];

      if (cpptList.isEmpty) {
        return null; // No CPPT records found
      }

      // Sort the list by date in descending order
      cpptList.sort((a, b) {
        final dateA = DateTime.tryParse(a['tanggal']?.toString() ?? '');
        final dateB = DateTime.tryParse(b['tanggal']?.toString() ?? '');
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA); // Newest first
      });

      // Return the ID of the first item (the latest one)
      final latestCpptId = int.tryParse(cpptList.first['id']?.toString() ?? '');
      debugPrint('CPPT ID terbaru ditemukan: $latestCpptId');
      return latestCpptId;
    } else {
      throw Exception('Gagal mengambil data CPPT: Status ${response.statusCode}');
    }
  }

  // --- MODIFIED: FUNCTION TO SUBMIT INTERVENTION ---
  Future<void> _submitIntervensi() async {
    setState(() => _isLoading = true);
    final token = widget.user.token ?? '';

    try {
      // 1. Get the latest CPPT ID first
      final int? latestCpptId = await _getLatestCpptId(token);

      if (latestCpptId == null) {
        throw Exception(
            'Tidak dapat membuat intervensi. Tidak ada data CPPT untuk pasien ini.');
      }

      // 2. Proceed to create the intervention
      final base = _getBaseUrl();
      if (base.isEmpty) throw Exception('API URL not found');
      final apiUrl = base.endsWith('/') ? '${base}intervensi/' : '$base/intervensi/';

      final body = jsonEncode({
        'patient_id': widget.patientId,
        'user_id': widget.user.id,
        'query': _currentText,
      });

      debugPrint('--- [MENGIRIM POST KE INTERVENSI] ---');
      debugPrint('URL    : POST $apiUrl');
      debugPrint('BODY   : $body');
      debugPrint('---------------------------------');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        final responseBody = jsonDecode(response.body);
        int newIntervensiId = 0;
        if (responseBody is Map) {
          newIntervensiId = int.tryParse((responseBody['id'] ??
                      responseBody['intervensi_id'] ??
                      responseBody['data']?['id'])
                  ?.toString() ??
              '0') ?? 0;
        }

        if (newIntervensiId == 0) {
          throw Exception("Gagal mendapatkan ID Intervensi dari server.");
        }

        debugPrint('Intervensi berhasil dikirim dengan ID: $newIntervensiId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Intervensi berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );

        // 3. Navigate to IntervensiInap with all necessary data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IntervensiInap(
              intervensiId: newIntervensiId,
              token: token,
              patientId: widget.patientId,
              perawatId: widget.user.id,
              query: _currentText,
              cpptId: latestCpptId, // Pass the fetched CPPT ID
            ),
          ),
        );
      } else {
        _handleErrorResponse(response);
      }
    } catch (e) {
      _handleGenericError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _handleErrorResponse(http.Response response) {
    if (!mounted) return;
    String errorMessage =
        'Gagal mengirim data: Status Code ${response.statusCode}';
    try {
      final responseBody = jsonDecode(response.body);
      if (responseBody is Map && responseBody.containsKey('message')) {
        errorMessage = responseBody['message'].toString();
      }
    } catch (_) {}
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
    );
  }

  void _handleGenericError(Object e) {
    if (kDebugMode) debugPrint('Terjadi kesalahan: $e');
    final errorMessage = e.toString().replaceAll('Exception: ', '');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Terjadi kesalahan: $errorMessage'),
        backgroundColor: Colors.red,
      ),
    );
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
                'Edit',
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
                    hintText: 'Masukkan teks ...',
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
    const successButtonGreen = Color(0xFF28a745);

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
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _showEditSheet,
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lightButtonBlue,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitCppt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkButtonBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'CPPT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitIntervensi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: successButtonGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Intervensi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}