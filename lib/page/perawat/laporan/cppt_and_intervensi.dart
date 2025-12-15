import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vocare/page/perawat/laporan/laporan.dart';

class VocareReport3 extends StatefulWidget {
  final int cpptId;
  final int patientId;
  final int perawatId;
  final int? intervensiId;
  final String query;
  final String? token;

  const VocareReport3({
    super.key,
    required this.cpptId,
    required this.patientId,
    required this.perawatId,
    this.intervensiId,
    required this.query,
    this.token,
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
  bool _isPostingLaporan = false;
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
      _isLoading || _isPostingLaporan || _isUpdatingCppt || _isDeleting;

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

  /// Helper Function to format assessment string into a numbered list.
  String _formatAssessment(String? rawText) {
    if (rawText == null || rawText.isEmpty) {
      return '';
    }

    // Removes curly braces, quotes, and square brackets
    String cleanedText = rawText.replaceAll(RegExp(r'[{}"[\]]'), '');

    // Splits items by comma, trims whitespace, and removes empty items
    List<String> items = cleanedText
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (items.isEmpty) {
      return cleanedText; // Returns cleaned text if no items are found
    }

    // Builds the numbered list
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < items.length; i++) {
      buffer.write('${i + 1}. ${items[i]}');
      if (i < items.length - 1) {
        buffer.write('\n');
      }
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
      if (kDebugMode) debugPrint('Fetch CPPT ${resp.statusCode}: ${resp.body}');

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
        String msg = resp.body;
        try {
          final parsed = jsonDecode(resp.body);
          if (parsed is Map && parsed['message'] != null)
            msg = parsed['message'].toString();
        } catch (_) {}
        if (mounted)
          setState(() {
            _error = 'Gagal mengambil CPPT: ${resp.statusCode} - $msg';
          });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = 'Gagal mengambil CPPT: $e';
        });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  // === NEW: _createOrUpdateIntervensi ===
  Future<int?> _createOrUpdateIntervensi({
    required int patientId,
    required int perawatId,
    required String implementasi,
    required String evaluasi,
  }) async {
    final baseUrl = _baseUrlFromEnv();
    final headers = _buildHeaders();

    // Tentukan URL dan metode (POST untuk buat baru, PUT untuk update)
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
      if (kDebugMode) debugPrint('$method $url -> $body');

      final http.Response resp;
      if (isUpdate) {
        resp = await http.put(Uri.parse(url), headers: headers, body: body);
      } else {
        resp = await http.post(Uri.parse(url), headers: headers, body: body);
      }

      if (kDebugMode)
        debugPrint('Intervensi response ${resp.statusCode}: ${resp.body}');

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
        String msg = resp.body;
        try {
          final parsed = jsonDecode(resp.body);
          if (parsed is Map && parsed['message'] != null)
            msg = parsed['message'].toString();
        } catch (_) {}
        throw Exception('Gagal $method Intervensi: ${resp.statusCode} - $msg');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error createOrUpdateIntervensi: $e');
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
      if (kDebugMode) debugPrint('PUT $url -> $body');
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
        String msg = response.body;
        try {
          final parsed = jsonDecode(response.body);
          if (parsed is Map && parsed['message'] != null)
            msg = parsed['message'].toString();
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
      if (mounted) setState(() => _isUpdatingCppt = false);
    }
  }

  Future<void> _postLaporan() async {
    setState(() => _isPostingLaporan = true);

    int? intervensiIdToSend = _currentIntervensiId;

    // 1. BUAT/UPDATE INTERVENSI DULU
    try {
      final newIntervensiId = await _createOrUpdateIntervensi(
        patientId: widget.patientId,
        perawatId: widget.perawatId,
        implementasi: _implementasiController.text,
        evaluasi: _evaluasiController.text,
      );
      if (newIntervensiId == null) {
        throw Exception("Gagal mendapatkan ID Intervensi setelah POST/PUT.");
      }
      intervensiIdToSend = newIntervensiId;
      if (mounted) {
        setState(() {
          _currentIntervensiId = newIntervensiId;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Intervensi berhasil ${(_currentIntervensiId != null ? 'diperbarui' : 'dibuat')}!',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Peringatan: Gagal membuat/mengupdate intervensi. Laporan mungkin tidak terhubung: $e',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      if (kDebugMode) debugPrint('Create/Update intervensi failed: $e');
    }

    // Ambil ID terbaru (jika ada)
    final int? cpptIdToSend = (widget.cpptId != 0)
        ? widget.cpptId
        : (_cpptData != null
              ? int.tryParse(_cpptData!['id']?.toString() ?? '')
              : null);

    // Cek ID yang dibutuhkan
    if (cpptIdToSend == null || cpptIdToSend == 0) {
      if (mounted) _showErrorSnackBar("Gagal: CPPT ID tidak tersedia.");
      if (mounted) setState(() => _isPostingLaporan = false);
      return;
    }
    if (intervensiIdToSend == null || intervensiIdToSend == 0) {
      if (mounted)
        _showErrorSnackBar(
          "Gagal: Intervensi ID tidak tersedia. Harap isi Intervensi.",
        );
      if (mounted) setState(() => _isPostingLaporan = false);
      return;
    }

    if (kDebugMode) {
      debugPrint(
        'Preparing POST laporan with: cpptId=$cpptIdToSend, patientId=${widget.patientId}, perawatId=${widget.perawatId}, intervensiId=$intervensiIdToSend',
      );
    }

    // 2. POST LAPORAN
    final url = '${_baseUrlFromEnv()}/laporan/';
    final headers = _buildHeaders();

    final bodyMap = {
      'cppt_id': cpptIdToSend,
      'patient_id': widget.patientId,
      'intevensi_id': intervensiIdToSend, // Gunakan ID Intervensi yang baru
      'perawat_id': widget.perawatId,
      'query': widget.query,
    };

    final body = jsonEncode(bodyMap);

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
                VocareLaporan(laporanId: laporanId!, token: widget.token),
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
      if (mounted) setState(() => _isPostingLaporan = false);
    }
  }

  Future<void> _deleteCppt() async {
    if (widget.cpptId == 0) {
      _showErrorSnackBar('cppt_id tidak tersedia. Tidak dapat menghapus.');
      return;
    }
    if (widget.patientId == 0) {
      _showErrorSnackBar(
        'patient_id tidak tersedia. Pembatalan penghapusan Pasien.',
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Hapus CPPT & Pasien'),
        content: const Text(
          '⚠️ Apakah Anda yakin ingin menghapus CPPT DAN DATA PASIEN terkait? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    final cpptUrl = '${_baseUrlFromEnv()}/cppt/${widget.cpptId}';
    final patientUrl = '${_baseUrlFromEnv()}/patients/${widget.patientId}';
    final headers = _buildHeaders();

    try {
      // 1. HAPUS CPPT
      if (kDebugMode) debugPrint('DELETE CPPT $cpptUrl');
      final respCppt = await http.delete(Uri.parse(cpptUrl), headers: headers);
      if (!mounted) return;

      if (respCppt.statusCode >= 200 && respCppt.statusCode < 300) {
        // 2. CPPT BERHASIL DIHAPUS, LANJUT HAPUS PASIEN
        if (kDebugMode) debugPrint('DELETE PATIENT $patientUrl');
        final respPatient = await http.delete(
          Uri.parse(patientUrl),
          headers: headers,
        );
        if (!mounted) return;

        if (respPatient.statusCode >= 200 && respPatient.statusCode < 300) {
          // Keduanya berhasil dihapus
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CPPT dan Pasien berhasil dihapus.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          // Gagal menghapus pasien
          String msg = respPatient.body;
          try {
            final parsed = jsonDecode(respPatient.body);
            if (parsed is Map && parsed['message'] != null)
              msg = parsed['message'].toString();
          } catch (_) {}
          // Beri peringatan karena CPPT sudah terhapus
          throw Exception(
            'CPPT terhapus, tetapi Gagal menghapus Pasien (${respPatient.statusCode}): $msg',
          );
        }
      } else {
        // Gagal menghapus CPPT
        String msg = respCppt.body;
        try {
          final parsed = jsonDecode(respCppt.body);
          if (parsed is Map && parsed['message'] != null)
            msg = parsed['message'].toString();
        } catch (_) {}
        throw Exception('Gagal menghapus CPPT (${respCppt.statusCode}): $msg');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Gagal menghapus: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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

    Widget buildEditableField(TextEditingController controller) {
      return TextFormField(
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
          const SizedBox(height: 10),
          _currentIntervensiId != null
              ? Text(
                  'Intervensi ID: ${_currentIntervensiId!}',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                )
              : const Text(
                  'Intervensi baru akan dibuat saat mengirim Laporan.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
        ],
      );
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
          section(
            'Subjective',
            child: buildEditableField(_subjectiveController),
          ),
          const SizedBox(height: 10),
          section('Objective', child: buildEditableField(_objectiveController)),
          const SizedBox(height: 10),
          section(
            'Assessment',
            child: buildEditableField(_assessmentController),
          ),
          const SizedBox(height: 10),
          section('Plan', child: buildEditableField(_planController)),
          const SizedBox(height: 10),
          section(
            'Keterangan',
            child: buildEditableField(_keteranganController),
          ),
          const SizedBox(height: 10),
          if ((d['dokter'] ?? '').toString().isNotEmpty ||
              _dokterController.text.isNotEmpty)
            section('Dokter', child: buildEditableField(_dokterController)),
          const SizedBox(height: 10),
          if ((d['signature'] ?? '').toString().isNotEmpty)
            section(
              'Tanda Tangan',
              child: buildSignature(d['signature']?.toString()),
            ),
          const SizedBox(height: 10),

          // NEW: Intervensi Manual Input Section
          section(
            'Intervensi (Implementasi & Evaluasi)',
            child: intervensiEditorSection(),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isBusy || widget.cpptId == 0)
                            ? null
                            : _deleteCppt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isDeleting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'Hapus',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
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
                        onPressed: (_isBusy) ? null : _updateCppt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonUpdate,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isUpdatingCppt
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
                      child: ElevatedButton.icon(
                        onPressed: (_isBusy)
                            ? null
                            : _postLaporan, // _postLaporan sekarang menangani Intervensi POST/PUT
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
                          _isPostingLaporan ? 'Mengirim...' : 'Hasil',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
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
                ],
              ),
            ),
          ),
        ),
        if (_isBusy) ...[
          const ModalBarrier(dismissible: false, color: Colors.black45),
          const Center(
            child: SizedBox(
              height: 64,
              width: 64,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
