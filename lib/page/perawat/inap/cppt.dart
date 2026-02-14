import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vocare/page/perawat/inap/intervensi.dart';

class CpptTambahan extends StatefulWidget {
  final int cpptId;
  final String patientId;
  final String perawatId;
  final String query;
  final String? token;
  final int assessmentId;

  const CpptTambahan({
    super.key,
    required this.cpptId,
    required this.patientId,
    required this.perawatId,
    required this.query,
    this.token,
    required this.assessmentId,
  });

  @override
  State<CpptTambahan> createState() => _CpptTambahanState();
}

class _CpptTambahanState extends State<CpptTambahan> {
  static const background = Color.fromARGB(255, 223, 240, 255);
  static const cardBorder = Color(0xFFCED7E8);
  static const headingBlue = Color(0xFF0F4C81);
  static const buttonIntervensi = Color(0xFF009563);
  static const buttonUpdate = Color(0xFF007BFF);

  Map<String, dynamic>? _cpptData;
  bool _isLoading = false; // Untuk fetch awal
  bool _isUpdating = false; // Untuk proses simpan/update
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
          _subjectiveController.text =
              _cpptData?['subjective']?.toString() ?? '';
          _objectiveController.text = _cpptData?['objective']?.toString() ?? '';
          _assessmentController.text =
              _cpptData?['assessment']?.toString() ?? '';
          _planController.text = _cpptData?['plan']?.toString() ?? '';
          _keteranganController.text =
              _cpptData?['keterangan']?.toString() ?? '';
        });
      } else {
        String msg = resp.body;
        try {
          final parsed = jsonDecode(resp.body);
          if (parsed is Map && parsed['message'] != null) {
            msg = parsed['message'].toString();
          }
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
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

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

  void _goToIntervensiPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntervensiInap(
          token: widget.token ?? '',
          patientId: widget.patientId,
          perawatId: widget.perawatId,
          query: widget.query,
          cpptId: widget.cpptId,
        ),
      ),
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

    // Tampilkan loading biasa (bukan overlay) untuk initial fetch
    // karena datanya belum ada.
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) return Center(child: Text(_error!));
    if (_cpptData == null) {
      return const Center(child: Text('Tidak ada data CPPT'));
    }

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
          section(
            'Subjective',
            child: _buildEditableField(_subjectiveController),
          ),
          const SizedBox(height: 10),
          section(
            'Objective',
            child: _buildEditableField(_objectiveController),
          ),
          const SizedBox(height: 10),
          section(
            'Assessment',
            child: _buildEditableField(_assessmentController),
          ),
          const SizedBox(height: 10),
          section('Plan', child: _buildEditableField(_planController)),
          const SizedBox(height: 10),
          section(
            'Keterangan',
            child: _buildEditableField(_keteranganController),
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
    // Variable untuk mengunci tombol jika sedang loading
    final bool isActionInProgress = _isLoading || _isUpdating;

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
      // --- WRAP DENGAN STACK UNTUK OVERLAY ---
      body: Stack(
        children: [
          // Layer 1: Konten Utama
          SafeArea(child: _buildBody()),

          // Layer 2: Loading Overlay (Hanya muncul saat sedang Update/Simpan)
          // (Initial loading _isLoading sudah ditangani di dalam _buildBody untuk mengganti konten)
          if (_isUpdating)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    // Disable button saat proses berjalan
                    onPressed: isActionInProgress ? null : _updateCppt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonUpdate,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Simpan Perubahan',
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
                  height: 52,
                  child: ElevatedButton(
                    // Disable button saat proses berjalan
                    onPressed: isActionInProgress ? null : _goToIntervensiPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonIntervensi,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Buat Intervensi',
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
      ),
    );
  }
}
