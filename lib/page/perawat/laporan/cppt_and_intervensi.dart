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
  Map<String, dynamic>? _intervensiData;
  bool _isLoading = false;
  bool _isLoadingIntervensi = false;
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

  @override
  void initState() {
    super.initState();

    _subjectiveController = TextEditingController();
    _objectiveController = TextEditingController();
    _assessmentController = TextEditingController();
    _planController = TextEditingController();
    _keteranganController = TextEditingController();
    _dokterController = TextEditingController();

    if (widget.cpptId > 0) _fetchCppt();
    if (widget.intervensiId != null && widget.intervensiId! > 0) {
      _fetchIntervensi(widget.intervensiId!);
    }
  }

  @override
  void dispose() {
    _subjectiveController.dispose();
    _objectiveController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    _keteranganController.dispose();
    _dokterController.dispose();
    super.dispose();
  }

  bool get _isBusy =>
      _isLoading || _isPostingLaporan || _isUpdatingCppt || _isDeleting || _isLoadingIntervensi;

  String _baseUrlFromEnv() {
    return dotenv.env['API_BASE_URL'] ?? dotenv.env['API_URL'] ?? 'http://your-api-host';
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
        if (mounted) {
          setState(() {
            _cpptData = obj;
            _subjectiveController.text = obj['subjective']?.toString() ?? '';
            _objectiveController.text = obj['objective']?.toString() ?? '';
            _assessmentController.text = obj['assessment']?.toString() ?? '';
            _planController.text = obj['plan']?.toString() ?? '';
            _keteranganController.text = obj['keterangan']?.toString() ?? '';
            _dokterController.text = obj['dokter']?.toString() ?? '';
          });
        }

        // if cppt contains intervensi_id and widget didn't receive one, fetch it
        try {
          final interId = obj['intervensi_id'];
          if ((widget.intervensiId == null || widget.intervensiId == 0) && interId != null) {
            final parsed = int.tryParse(interId.toString());
            if (parsed != null && parsed > 0) _fetchIntervensi(parsed);
          }
        } catch (_) {}
      } else {
        String msg = resp.body;
        try {
          final parsed = jsonDecode(resp.body);
          if (parsed is Map && parsed['message'] != null) msg = parsed['message'].toString();
        } catch (_) {}
        if (mounted) setState(() {
          _error = 'Gagal mengambil CPPT: ${resp.statusCode} - $msg';
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Gagal mengambil CPPT: $e';
      });
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchIntervensi(int id) async {
    setState(() {
      _isLoadingIntervensi = true;
      _intervensiData = null; // clear previous while loading
    });

    final url = '${_baseUrlFromEnv()}/intervensi/$id';

    try {
      if (kDebugMode) debugPrint('GET $url');
      final resp = await http.get(Uri.parse(url), headers: _buildHeaders());
      if (kDebugMode) debugPrint('Fetch Intervensi ${resp.statusCode}: ${resp.body}');

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
            _intervensiData = obj;
          });
        }
      } else {
        String msg = resp.body;
        try {
          final parsed = jsonDecode(resp.body);
          if (parsed is Map && parsed['message'] != null) msg = parsed['message'].toString();
        } catch (_) {}
        if (kDebugMode) debugPrint('Gagal mengambil intervensi: ${resp.statusCode} - $msg');
        if (mounted) setState(() {
          _intervensiData = null;
          _error = 'Gagal mengambil intervensi: ${resp.statusCode}';
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetchIntervensi: $e');
      if (mounted) setState(() {
        _intervensiData = null;
        _error = 'Error fetchIntervensi: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoadingIntervensi = false);
    }
  }

  Future<void> _updateCppt() async {
    setState(() => _isUpdatingCppt = true);

    final url = '${_baseUrlFromEnv()}/cppt/${widget.cpptId}';
    final headers = _buildHeaders();
    final body = jsonEncode({
      'subjective': _subjectiveController.text,
      'objective': _objectiveController.text,
      'assessment': _assessmentController.text,
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
        // optionally refresh
        if (widget.cpptId > 0) _fetchCppt();
      } else {
        String msg = response.body;
        try {
          final parsed = jsonDecode(response.body);
          if (parsed is Map && parsed['message'] != null) msg = parsed['message'].toString();
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

    final int? cpptIdToSend = (widget.cpptId != 0)
        ? widget.cpptId
        : (_cpptData != null ? int.tryParse(_cpptData!['id']?.toString() ?? '') : null);

    final int? patientIdToSend = (widget.patientId != 0)
        ? widget.patientId
        : (_cpptData != null ? int.tryParse(_cpptData!['patient_id']?.toString() ?? '') : null);

    final int? perawatIdToSend = (widget.perawatId != 0)
        ? widget.perawatId
        : (_cpptData != null
            ? int.tryParse((_cpptData!['perawat_id'] ?? _cpptData!['user_id'])?.toString() ?? '')
            : null);

    final int? intervensiIdToSend = (widget.intervensiId != null && widget.intervensiId! > 0)
        ? widget.intervensiId
        : (_intervensiData != null ? int.tryParse(_intervensiData!['id']?.toString() ?? '') : null);

    if (kDebugMode) {
      debugPrint('Preparing POST laporan with: cpptId=$cpptIdToSend, patientId=$patientIdToSend, perawatId=$perawatIdToSend, intervensiId=$intervensiIdToSend');
    }

    final url = '${_baseUrlFromEnv()}/laporan/';
    final headers = _buildHeaders();

    final Map<String, dynamic> bodyMap = {
      'cppt_id': widget.cpptId,
      'patient_id':widget.patientId,
      'intevensi_id':widget.intervensiId,
      'perawat_id':widget.perawatId,
      'query': widget.query,
    };

    if (cpptIdToSend != null && cpptIdToSend > 0) bodyMap['cppt_id'] = cpptIdToSend;
    if (patientIdToSend != null && patientIdToSend > 0) bodyMap['patient_id'] = patientIdToSend;
    if (perawatIdToSend != null && perawatIdToSend > 0) bodyMap['perawat_id'] = perawatIdToSend;
    if (intervensiIdToSend != null && intervensiIdToSend > 0) bodyMap['intervensi_id'] = intervensiIdToSend;

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
        } else if (data.containsKey('data') && data['data'] is Map && data['data']['id'] != null) {
          laporanId = int.tryParse(data['data']['id'].toString());
        }
        if (laporanId == null) {
          throw Exception('Gagal mendapatkan ID Laporan dari response server.');
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VocareLaporan(laporanId: laporanId!, token: widget.token),
          ),
        );
      } else {
        String msg = response.body;
        try {
          final parsed = jsonDecode(response.body);
          if (parsed is Map && parsed['message'] != null) msg = parsed['message'].toString();
        } catch (_) {}
        throw Exception('Gagal mengirim laporan (${response.statusCode}): $msg');
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

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Hapus CPPT'),
        content: const Text('Apakah Anda yakin ingin menghapus CPPT ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    final url = '${_baseUrlFromEnv()}/cppt/${widget.cpptId}';
    try {
      if (kDebugMode) debugPrint('DELETE $url');
      final resp = await http.delete(Uri.parse(url), headers: _buildHeaders());
      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CPPT berhasil dihapus.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // kembali ke layar sebelumnya
      } else {
        String msg = resp.body;
        try {
          final parsed = jsonDecode(resp.body);
          if (parsed is Map && parsed['message'] != null) msg = parsed['message'].toString();
        } catch (_) {}
        throw Exception('Gagal menghapus CPPT (${resp.statusCode}): $msg');
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
    if (_cpptData == null) return const Center(child: Text('Tidak ada data CPPT'));

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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
    }

    Widget intervensiSection() {
      if (_isLoadingIntervensi) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_intervensiData == null) {
        return const Text('Tidak ada data intervensi.');
      }

      final iv = _intervensiData!;
      final tanggalRaw = iv['tanggal']?.toString() ?? iv['created_at']?.toString();
      final tanggal = tanggalRaw != null ? formatDate(tanggalRaw) : '-';
      final evaluasi = iv['evaluasi']?.toString() ?? iv['evaluation']?.toString() ?? '-';
      final implementasi = iv['implementasi']?.toString() ?? iv['implementation']?.toString() ?? '-';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note, size: 18, color: headingBlue),
              const SizedBox(width: 8),
              Text(
                tanggal,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Evaluasi', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(evaluasi),
          const SizedBox(height: 10),
          Text('Implementasi', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(implementasi),
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
          section('Subjective', child: buildEditableField(_subjectiveController)),
          const SizedBox(height: 10),
          section('Objective', child: buildEditableField(_objectiveController)),
          const SizedBox(height: 10),
          section('Assessment', child: buildEditableField(_assessmentController)),
          const SizedBox(height: 10),
          section('Plan', child: buildEditableField(_planController)),
          const SizedBox(height: 10),
          section('Keterangan', child: buildEditableField(_keteranganController)),
          const SizedBox(height: 10),
          if ((d['dokter'] ?? '').toString().isNotEmpty || _dokterController.text.isNotEmpty)
            section('Dokter', child: buildEditableField(_dokterController)),
          const SizedBox(height: 10),
          if ((d['signature'] ?? '').toString().isNotEmpty) section('Tanda Tangan', child: buildSignature(d['signature']?.toString())),
          const SizedBox(height: 10),

          // Intervensi section (if available)
          if (_intervensiData != null) section('Intervensi', child: intervensiSection()),

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
                  // Delete Button
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isBusy || widget.cpptId == 0) ? null : _deleteCppt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Save/Update Button
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isBusy) ? null : _updateCppt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonUpdate,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  // Create Report Button
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: (_isBusy) ? null : _postLaporan,
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
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonSave,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

        // PERUBAHAN DI SINI: Overlay loading yang lebih sederhana
        if (_isBusy) ...[
          const ModalBarrier(dismissible: false, color: Colors.black45),
          const Center(
            child: SizedBox(
              height: 64,
              width: 64,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: Colors.white, // Opsi: agar lebih terlihat di background gelap
              ),
            ),
          ),
        ],
      ],
    );
  }
}