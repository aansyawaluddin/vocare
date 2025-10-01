// lib/page/perawat/inap/cppt.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vocare/page/perawat/inap/intervensi.dart'; // Make sure this import is correct

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
  // MODIFIED: Changed button color name for clarity
  static const buttonIntervensi = Color(0xFF009563);
  static const buttonUpdate = Color(0xFF007BFF);

  Map<String, dynamic>? _cpptData;
  bool _isLoading = false;
  // MODIFIED: Renamed state variable for clarity
  bool _isPostingIntervensi = false;
  bool _isUpdating = false;
  String? _error;

  late final TextEditingController _subjectiveController;
  late final TextEditingController _objectiveController;
  late final TextEditingController _assessmentController;
  late final TextEditingController _planController;
  late final TextEditingController _keteranganController;

  @override
  void initState() {
    super.initState();
    _subjectiveController = TextEditingController();
    _objectiveController = TextEditingController();
    _assessmentController = TextEditingController();
    _planController = TextEditingController();
    _keteranganController = TextEditingController();

    if (widget.cpptId != 0) {
      _fetchCppt();
    }
  }

  @override
  void dispose() {
    _subjectiveController.dispose();
    _objectiveController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    _keteranganController.dispose();
    super.dispose();
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
          _subjectiveController.text = _cpptData?['subjective']?.toString() ?? '';
          _objectiveController.text = _cpptData?['objective']?.toString() ?? '';
          _assessmentController.text = _cpptData?['assessment']?.toString() ?? '';
          _planController.text = _cpptData?['plan']?.toString() ?? '';
          _keteranganController.text = _cpptData?['keterangan']?.toString() ?? '';
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateCppt() async {
    setState(() => _isUpdating = true);

    final url = '${_baseUrlFromEnv()}/cppt/${widget.cpptId}';
    final headers = _buildHeaders();
    final body = jsonEncode({
      'subjective': _subjectiveController.text,
      'objective': _objectiveController.text,
      'assessment': _assessmentController.text,
      'plan': _planController.text,
      'keterangan': _keteranganController.text,
    });

    try {
      if (kDebugMode) debugPrint('PUT $url -> $body');
      final response =
          await http.put(Uri.parse(url), headers: headers, body: body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CPPT berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String msg = response.body;
        try {
          final parsed = jsonDecode(response.body);
          if (parsed is Map && parsed['message'] != null) {
            msg = parsed['message'].toString();
          }
        } catch (_) {}
        throw Exception(
          'Gagal memperbarui CPPT (${response.statusCode}): $msg',
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
        setState(() => _isUpdating = false);
      }
    }
  }

  // --- NEW FUNCTION TO POST INTERVENTION ---
  Future<void> _postIntervensi() async {
    setState(() => _isPostingIntervensi = true);

    final url = '${_baseUrlFromEnv()}/intervensi/';
    final headers = _buildHeaders();
    final body = jsonEncode({
      'patient_id': widget.patientId,
      'user_id': widget.perawatId, // Assuming perawatId is the user_id
      'query': widget.query,
    });

    try {
      if (kDebugMode) debugPrint('POST $url -> $body');
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        int? intervensiId;
        if (data.containsKey('id')) {
          intervensiId = int.tryParse(data['id'].toString());
        } else if (data.containsKey('data') &&
            data['data'] is Map &&
            data['data']['id'] != null) {
          intervensiId = int.tryParse(data['data']['id'].toString());
        }

        if (intervensiId == null) {
          throw Exception('Gagal mendapatkan ID Intervensi dari server.');
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IntervensiInap(
              intervensiId: intervensiId!,
              token: widget.token ?? '',
              patientId: widget.patientId,
              perawatId: widget.perawatId,
              query: widget.query,
              cpptId: widget.cpptId,
            ),
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
          'Gagal mengirim intervensi (${response.statusCode}): $msg',
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
        setState(() => _isPostingIntervensi = false);
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
        ],
      ),
    );
  }

  Widget _buildEditableField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(height: 1.4, fontSize: 16),
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildBody() {
    if (widget.cpptId == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.info_outline, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Tidak ada CPPT yang dipilih atau ID tidak valid.',
                textAlign: TextAlign.center,
              ),
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
          const SizedBox(height: 15),
          section('Subjective', child: _buildEditableField(_subjectiveController)),
          const SizedBox(height: 10),
          section('Objective', child: _buildEditableField(_objectiveController)),
          const SizedBox(height: 10),
          section('Assessment', child: _buildEditableField(_assessmentController)),
          const SizedBox(height: 10),
          section('Plan', child: _buildEditableField(_planController)),
          const SizedBox(height: 10),
          section('Keterangan', child: _buildEditableField(_keteranganController)),
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
    final bool isActionInProgress = _isLoading || _isPostingIntervensi || _isUpdating;

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
      // --- MODIFIED: BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            children: [
              Expanded(
                child: _buildLoadingButton(
                  isLoading: _isUpdating,
                  onPressed: isActionInProgress ? null : _updateCppt,
                  text: 'Simpan Perubahan',
                  loadingText: 'Menyimpan...',
                  color: buttonUpdate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLoadingButton(
                  // Use the new state variable
                  isLoading: _isPostingIntervensi,
                  // Call the new function
                  onPressed: isActionInProgress ? null : _postIntervensi,
                  // Updated button text
                  text: 'Buat Intervensi',
                  loadingText: 'Mengirim...',
                  color: buttonIntervensi,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}