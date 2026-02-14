import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vocare/common/type.dart';
import 'package:vocare/page/perawat/home.dart';

class VocareReport3 extends StatefulWidget {
  final int cpptId;
  final int patientId;
  final int perawatId;
  final int? intervensiId;
  final String query;
  final String? token;
  final User user;

  const VocareReport3({
    super.key,
    required this.cpptId,
    required this.patientId,
    required this.perawatId,
    this.intervensiId,
    required this.query,
    this.token,
    required this.user,
  });

  @override
  State<VocareReport3> createState() => _VocareReport3State();
}

class _VocareReport3State extends State<VocareReport3> {
  static const background = Color.fromARGB(255, 223, 240, 255);
  static const cardBorder = Color(0xFFCED7E8);
  static const headingBlue = Color(0xFF0F4C81);
  static const buttonSave = Color(0xFF009563);
  static const buttonUpdate = Color(0xFF0F4C81);

  Map<String, dynamic>? _cpptData;
  int? _currentIntervensiId;
  bool _isLoading = false;
  bool _isFinishing = false; // Ganti _isPostingLaporan
  bool _isUpdatingCppt = false;
  bool _isDeleting = false;
  String? _error;

  late final TextEditingController _subjectiveController;
  late final TextEditingController _objectiveController;
  late final TextEditingController _assessmentController;
  late final TextEditingController _planController;
  late final TextEditingController _keteranganController;
  late final TextEditingController _dokterController;

  late final TextEditingController _implementasiController;
  late final TextEditingController _evaluasiController;

  @override
  void initState() {
    super.initState();

    _subjectiveController = TextEditingController();
    _objectiveController = TextEditingController();
    _assessmentController = TextEditingController();
    _planController = TextEditingController();
    _keteranganController = TextEditingController();
    _dokterController = TextEditingController();

    _implementasiController = TextEditingController(text: '');
    _evaluasiController = TextEditingController(text: '');

    _currentIntervensiId = widget.intervensiId;

    if (widget.cpptId > 0) _fetchCppt();
  }

  @override
  void dispose() {
    _subjectiveController.dispose();
    _objectiveController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    _keteranganController.dispose();
    _dokterController.dispose();
    _implementasiController.dispose();
    _evaluasiController.dispose();
    super.dispose();
  }

  bool get _isBusy =>
      _isLoading || _isFinishing || _isUpdatingCppt || _isDeleting;

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
    // Gunakan token dari object User
    if (widget.token != null && widget.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${widget.token}';
    }
    return headers;
  }

  String _formatAssessment(String? rawText) {
    if (rawText == null || rawText.isEmpty) return '';
    String cleanedText = rawText.replaceAll(RegExp(r'[{}"[\]]'), '');
    List<String> items = cleanedText
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (items.isEmpty) return cleanedText;

    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < items.length; i++) {
      buffer.write('${i + 1}. ${items[i]}');
      if (i < items.length - 1) buffer.write('\n');
    }
    return buffer.toString();
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

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(resp.body);
        Map<String, dynamic> obj = {};
        if (data.containsKey('data') && data['data'] is Map) {
          obj = Map<String, dynamic>.from(data['data']);
        } else {
          obj = data;
        }
        if (mounted) {
          setState(() {
            _cpptData = obj;
            _subjectiveController.text = obj['subjective']?.toString() ?? '';
            _objectiveController.text = obj['objective']?.toString() ?? '';
            _assessmentController.text = _formatAssessment(
              obj['assessment']?.toString(),
            );
            _planController.text = obj['plan']?.toString() ?? '';
            _keteranganController.text = obj['keterangan']?.toString() ?? '';
            _dokterController.text = obj['dokter']?.toString() ?? '';
          });
        }
      } else {
        if (mounted) setState(() => _error = 'Gagal mengambil CPPT');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal mengambil CPPT: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<int?> _createOrUpdateIntervensi({
    required int patientId,
    required int perawatId,
    required String implementasi,
    required String evaluasi,
  }) async {
    final baseUrl = _baseUrlFromEnv();
    final headers = _buildHeaders();

    final bool isUpdate =
        _currentIntervensiId != null && _currentIntervensiId! > 0;
    final String url = isUpdate
        ? '$baseUrl/intervensi/$_currentIntervensiId'
        : '$baseUrl/intervensi/';
    final String method = isUpdate ? 'PUT' : 'POST';

    final bodyMap = {
      'patient_id': patientId,
      'user_id': perawatId,
      'implementasi': implementasi,
      'evaluasi': evaluasi,
    };
    final body = jsonEncode(bodyMap);

    try {
      final http.Response resp;
      if (isUpdate) {
        resp = await http.put(Uri.parse(url), headers: headers, body: body);
      } else {
        resp = await http.post(Uri.parse(url), headers: headers, body: body);
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isEmpty) return _currentIntervensiId;
        final Map<String, dynamic> data = jsonDecode(resp.body);
        int? newId;
        newId = int.tryParse(data['id']?.toString() ?? '');
        if (newId == null)
          newId = int.tryParse(data['intervensi_id']?.toString() ?? '');
        if (newId == null && data['data'] is Map)
          newId = int.tryParse(data['data']['id']?.toString() ?? '');
        return newId ?? _currentIntervensiId;
      } else {
        throw Exception('Gagal $method Intervensi: ${resp.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _updateCppt() async {
    setState(() => _isUpdatingCppt = true);
    final url = '${_baseUrlFromEnv()}/cppt/${widget.cpptId}';
    final headers = _buildHeaders();

    String assessmentToSend = _assessmentController.text;
    if (RegExp(r'^\d+\.').hasMatch(assessmentToSend)) {
      List<String> items = assessmentToSend.split('\n').map((line) {
        return line.replaceAll(RegExp(r'^\d+\.\s*'), '').trim();
      }).toList();
      assessmentToSend = items.join(', ');
    }

    final body = jsonEncode({
      'subjective': _subjectiveController.text,
      'objective': _objectiveController.text,
      'assessment': assessmentToSend,
      'plan': _planController.text,
      'keterangan': _keteranganController.text,
      'dokter': _dokterController.text,
      "patient_id": widget.patientId,
      "perawat_id": widget.perawatId,
    });

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CPPT berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.cpptId > 0) _fetchCppt();
      } else {
        throw Exception('Gagal memperbarui CPPT (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingCppt = false);
    }
  }

  Future<void> _finishAndNavigate() async {
    setState(() => _isFinishing = true);

    try {
      await _createOrUpdateIntervensi(
        patientId: widget.patientId,
        perawatId: widget.perawatId,
        implementasi: _implementasiController.text,
        evaluasi: _evaluasiController.text,
      );
    } catch (e) {
      if (mounted) {
        debugPrint("Warning: Gagal menyimpan intervensi terakhir: $e");
      }
    }

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => HomePerawatPage(user: widget.user),
        ),
        (route) => false,
      );
    }

    if (mounted) setState(() => _isFinishing = false);
  }

  Future<void> _deleteCppt() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Yakin hapus CPPT & Pasien?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isDeleting = true);

    try {
      final headers = _buildHeaders();
      await http.delete(
        Uri.parse('${_baseUrlFromEnv()}/cppt/${widget.cpptId}'),
        headers: headers,
      );
      await http.delete(
        Uri.parse('${_baseUrlFromEnv()}/patients/${widget.patientId}'),
        headers: headers,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget buildEditableField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }

  Widget intervensiEditorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Implementasi',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        buildEditableField(_implementasiController),
        const SizedBox(height: 10),
        const Text('Evaluasi', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        buildEditableField(_evaluasiController),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            title: const Text(
              'Vocare Report',
              style: TextStyle(fontSize: 20, color: Color(0xFF093275)),
            ),
            backgroundColor: background,
            titleSpacing: 60,
          ),
          body: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 18, top: 10),
                      children: [
                        const SizedBox(height: 6),
                        if (_cpptData != null)
                          Text(
                            'CPPT ${_cpptData!['id'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0XFF093275),
                            ),
                          ),
                        const SizedBox(height: 15),
                        section(
                          'Subjective',
                          child: buildEditableField(_subjectiveController),
                        ),
                        const SizedBox(height: 10),
                        section(
                          'Objective',
                          child: buildEditableField(_objectiveController),
                        ),
                        const SizedBox(height: 10),
                        section(
                          'Assessment',
                          child: buildEditableField(_assessmentController),
                        ),
                        const SizedBox(height: 10),
                        section(
                          'Plan',
                          child: buildEditableField(_planController),
                        ),
                        const SizedBox(height: 10),
                        section(
                          'Intervensi (Implementasi & Evaluasi)',
                          child: intervensiEditorSection(),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isBusy || widget.cpptId == 0)
                        ? null
                        : _deleteCppt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isDeleting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Hapus'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _updateCppt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonUpdate,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isUpdatingCppt
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Simpan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    // Update: Panggil _finishAndNavigate
                    onPressed: _isBusy ? null : _finishAndNavigate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonSave,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isFinishing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Hasil'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isBusy)
          const ModalBarrier(dismissible: false, color: Colors.black45),
      ],
    );
  }
}
