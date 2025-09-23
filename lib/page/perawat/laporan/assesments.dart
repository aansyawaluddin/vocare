import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:vocare/widgets/perawat/report_utils.dart';
import 'package:vocare/widgets/perawat/report_widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;


import 'package:vocare/page/perawat/laporan/cppt.dart';

class VocareReport2 extends StatefulWidget {
  final String reportText;
  final Map<String, dynamic>? apiResponse;
  final String? username; // optional, diteruskan dari VocareReport
  final String? token; // optional, diteruskan dari VocareReport

  const VocareReport2({
    super.key,
    required this.reportText,
    this.apiResponse,
    this.username,
    this.token,
  });

  @override
  State<VocareReport2> createState() => _VocareReport2State();
}

const Color _backgroundColor = Color.fromARGB(255, 223, 240, 255);
const Color _appBarBackgroundColor = Color(0xFFD7E2FD);
const Color _titleColor = Color(0xFF093275);
const Color _buttonSaveColor = Color(0xFF009563);

const double _horizontalPadding = 20.0;
const double _sectionSpacing = 12.0;

class _VocareReport2State extends State<VocareReport2> {
  // State variables
  File? _signatureFile;
  Uint8List? _signatureBytes;
  String? _signatureExtension;
  Map<String, dynamic>? _cachedExtractedFields;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _logApiResponse();
    _cacheExtractedFields();
  }

  @override
  void didUpdateWidget(covariant VocareReport2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.apiResponse != oldWidget.apiResponse) {
      _logApiResponse();
      _cacheExtractedFields();
    }
  }

  void _logApiResponse() {
    if (!kDebugMode) return;

    try {
      // pretty print (indent) jika bisa
      final pretty = const JsonEncoder.withIndent(
        '  ',
      ).convert(widget.apiResponse);
      _debugPrintFull(pretty);
    } catch (e) {
      // fallback: kalau widget.apiResponse bukan json-serializable, print toString dalam chunks
      _debugPrintFull(widget.apiResponse?.toString() ?? 'apiResponse: null');
    }
  }

  /// Debug print yang memecah menjadi potongan agar tidak terpotong oleh logcat/debugPrint.
  void _debugPrintFull(String text, {int chunkSize = 1000}) {
    if (text.length <= chunkSize) {
      debugPrint(text);
      return;
    }
    for (var i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      debugPrint(text.substring(i, end));
    }
  }

  /// Cache extracted fields: merge top-level apiResponse + apiResponse['data'] + hasil parsing khusus
  void _cacheExtractedFields() {
    final Map<String, dynamic> merged = {};

    // 1) copy top-level fields
    if (widget.apiResponse != null) {
      widget.apiResponse!.forEach((k, v) {
        merged[k] = v;
      });

      // 2) jika ada 'data' dan merupakan Map, merge isinya (jangan overwrite top-level jika sudah ada)
      final dynamic dataField = widget.apiResponse!['data'];
      if (dataField is Map<String, dynamic>) {
        dataField.forEach((k, v) {
          if (!merged.containsKey(k)) merged[k] = v;
        });
      } else if (dataField is String) {
        // kalau 'data' adalah JSON string, coba decode dan merge
        try {
          final parsed = jsonDecode(dataField);
          if (parsed is Map<String, dynamic>) {
            parsed.forEach((k, v) {
              if (!merged.containsKey(k)) merged[k] = v;
            });
          }
        } catch (_) {
          // ignore jika tidak bisa decode
        }
      }
    }

    // 3) gunakan helper extractAssessmentObject/extractFieldsFromAssessment bila tersedia agar hasil parsing sebelumnya juga masuk
    try {
      final extractedFromData = extractAssessmentObject(widget.apiResponse);
      final extractedFieldsFromData = extractFieldsFromAssessment(
        extractedFromData,
      );
      if (extractedFieldsFromData != null) {
        extractedFieldsFromData.forEach((k, v) {
          if (!merged.containsKey(k)) merged[k] = v;
        });
      }
    } catch (_) {
      // jika fungsi tidak ada atau error, lanjut saja
    }

    _cachedExtractedFields = merged;

    if (kDebugMode) {
      try {
        debugPrint(
          'Merged extracted fields: ${jsonEncode(_cachedExtractedFields)}',
        );
      } catch (_) {
        debugPrint(
          'Merged extracted fields (toString): $_cachedExtractedFields',
        );
      }
    }
  }

  // ===========================
  // HTTP helpers
  // ===========================
  String _baseUrlFromEnv() {
    return dotenv.env['API_BASE_URL'] ??
        dotenv.env['API_URL'] ??
        'http://your-api-host'; // ganti sesuai env Anda
  }

  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (widget.token != null && widget.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${widget.token}';
      if (kDebugMode)
        debugPrint(
          'Authorization header set (partial): ${widget.token!.substring(0, widget.token!.length > 8 ? 8 : widget.token!.length)}...',
        );
    } else {
      if (kDebugMode) debugPrint('No token available; Authorization header NOT set.');
    }
    return headers;
  }

  Future<int?> _createPatient({
    required int idAssessment,
    required String nama,
  }) async {
    final baseUrl = _baseUrlFromEnv();
    final url = '$baseUrl/patients/';
    final body = jsonEncode({'id_assesment': idAssessment, 'nama': nama});

    try {
      if (kDebugMode) debugPrint('POST $url -> $body');
      final resp = await http.post(
        Uri.parse(url),
        headers: _buildHeaders(),
        body: body,
      );

      if (kDebugMode) debugPrint('CreatePatient response ${resp.statusCode}: ${resp.body}');

      if (resp.statusCode == 200 ||
          resp.statusCode == 201 ||
          resp.statusCode == 202) {
        if (resp.body.isEmpty) return null;
        final Map<String, dynamic> data = jsonDecode(resp.body);
        if (data.containsKey('id'))
          return (data['id'] is int) ? data['id'] : int.tryParse(data['id'].toString());
        if (data.containsKey('patient_id'))
          return (data['patient_id'] is int) ? data['patient_id'] : int.tryParse(data['patient_id'].toString());
        for (final v in data.values) {
          if (v is int) return v;
          if (v is Map && v['id'] != null) return int.tryParse(v['id'].toString());
        }
        return null;
      } else {
        String msg = resp.body;
        try {
          final parsed = jsonDecode(resp.body);
          if (parsed is Map && parsed['message'] != null) msg = parsed['message'].toString();
        } catch (_) {}
        throw Exception('Create patient failed: ${resp.statusCode} - $msg');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Modified: ensure both snake_case and camelCase keys are sent
  Future<Map<String, dynamic>?> _createCppt({
    required int patientId,
    required int perawatId,
    required String query,
  }) async {
    final baseUrl = _baseUrlFromEnv();
    final url = '$baseUrl/cppt/';
    // kirim baik snake_case dan camelCase untuk kompatibilitas API
    final bodyMap = {
      'patient_id': patientId,
      'perawat_id': perawatId,
      'query': query,
      // duplikasi dalam camelCase
      'patientId': patientId,
      'perawatId': perawatId,
    };

    final body = jsonEncode(bodyMap);

    try {
      if (kDebugMode) debugPrint('POST $url -> $body');
      final resp = await http.post(
        Uri.parse(url),
        headers: _buildHeaders(),
        body: body,
      );

      if (kDebugMode) debugPrint('CreateCPPT response ${resp.statusCode}: ${resp.body}');

      if (resp.statusCode == 200 ||
          resp.statusCode == 201 ||
          resp.statusCode == 202) {
        if (resp.body.isEmpty) return {};
        final Map<String, dynamic> data = jsonDecode(resp.body);
        return data;
      } else {
        String msg = resp.body;
        try {
          final parsed = jsonDecode(resp.body);
          if (parsed is Map && parsed['message'] != null) msg = parsed['message'].toString();
        } catch (_) {}
        throw Exception('Create CPPT failed: ${resp.statusCode} - $msg');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------
  // detect perawat id from several sources
  // Modified to try JWT token payload as last resort
  int _detectPerawatId(
    Map<String, dynamic>? merged,
    Map<String, dynamic>? apiResponse,
  ) {
    try {
      if (merged != null) {
        final keys = [
          'perawat_id',
          'perawatId',
          'perawat',
          'created_by',
          'id_perawat',
          'user_id',
          'userId',
        ];
        for (final k in keys) {
          if (merged.containsKey(k)) {
            final val = merged[k];
            if (val is int) return val;
            if (val is String) {
              final parsed = int.tryParse(val);
              if (parsed != null) return parsed;
            }
          }
        }
      }

      if (apiResponse != null) {
        final keys = [
          'perawat_id',
          'perawatId',
          'perawat',
          'user_id',
          'userId',
        ];
        for (final k in keys) {
          if (apiResponse.containsKey(k)) {
            final val = apiResponse[k];
            if (val is int) return val;
            if (val is String) {
              final parsed = int.tryParse(val);
              if (parsed != null) return parsed;
            }
          }
        }
      }

      if (widget.username != null) {
        final parsed = int.tryParse(widget.username!);
        if (parsed != null) return parsed;
      }

      // terakhir: coba decode token JWT
      if (widget.token != null && widget.token!.isNotEmpty) {
        final fromJwt = _extractPerawatIdFromJwt(widget.token);
        if (fromJwt != null) return fromJwt;
      }
    } catch (_) {}

    return 0;
  }

  // Helper: decode JWT payload and try extract user/perawat id
  int? _extractPerawatIdFromJwt(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> map = jsonDecode(decoded);
      final keys = [
        'perawat_id',
        'user_id',
        'id',
        'sub',
        'perawatId',
        'userId',
      ];
      for (final k in keys) {
        if (map.containsKey(k)) {
          final v = map[k];
          if (v is int) return v;
          if (v is String) {
            final parsed = int.tryParse(v);
            if (parsed != null) return parsed;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  // ===========================
  // File picker + UI helpers
  // ===========================
  Future<void> _pickSignatureFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.single;
        setState(() {
          _signatureExtension = picked.extension?.toLowerCase();
          _signatureBytes = picked.bytes;
          _signatureFile = picked.path != null ? File(picked.path!) : null;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        _showErrorSnackBar('Gagal memilih file: $e');
      }
    }
  }

  void _clearSignature() {
    setState(() {
      _signatureFile = null;
      _signatureBytes = null;
      _signatureExtension = null;
    });
  }

  bool _isImageFile() {
    final allowedImageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic'};

    if (_signatureExtension != null) {
      return allowedImageExtensions.contains(_signatureExtension);
    }

    if (_signatureFile != null) {
      final extension = _signatureFile!.path.toLowerCase().split('.').last;
      return allowedImageExtensions.contains(extension);
    }

    return false;
  }

  void _showFullImageViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: _signatureBytes != null
              ? Image.memory(_signatureBytes!, fit: BoxFit.contain)
              : _signatureFile != null
                  ? Image.file(_signatureFile!, fit: BoxFit.contain)
                  : const SizedBox.shrink(),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ===========================
  // Helper: ekstrak id assessment & nama pasien dari merged map
  // ===========================
  Map<String, dynamic> _extractIdAndName(Map<String, dynamic>? merged) {
    int? idAssessment;
    String? namaPasien;

    if (merged == null) return {'id': null, 'nama': null};

    // 1) top-level id
    final topId = merged['id'];
    if (topId != null) {
      if (topId is int)
        idAssessment = topId;
      else
        idAssessment = int.tryParse(topId.toString());
    }

    // 2) variasi key id
    final idCandidates = [
      'id_assesment',
      'id_assessment',
      'assesment_id',
      'assessment_id',
      'assessmentId',
    ];
    for (final k in idCandidates) {
      if (idAssessment != null) break;
      if (merged.containsKey(k)) {
        final v = merged[k];
        if (v is int)
          idAssessment = v;
        else
          idAssessment = int.tryParse(v?.toString() ?? '');
      }
    }

    // 3) cari nama pasien di banyak kemungkinan lokasi (termasuk nested)
    final nameCandidates = [
      'nama_pasien',
      'nama',
      'patient_name',
      'patient',
      'informasi_umum.nama_pasien',
      'informasi_umum.nama',
      'data.nama_pasien',
      'data.nama',
    ];

    String? tryNested(String key) {
      if (key.contains('.')) {
        final parts = key.split('.');
        dynamic cur = merged;
        for (final p in parts) {
          if (cur is Map && cur.containsKey(p)) {
            cur = cur[p];
          } else {
            cur = null;
            break;
          }
        }
        return cur?.toString();
      } else {
        return merged.containsKey(key) ? merged[key]?.toString() : null;
      }
    }

    for (final k in nameCandidates) {
      final candidate = tryNested(k);
      if (candidate != null && candidate.isNotEmpty) {
        namaPasien = candidate;
        break;
      }
    }

    // 4) fallback: jika 'data' adalah JSON string, coba decode dan cari nama
    if ((namaPasien == null || namaPasien.isEmpty) &&
        merged.containsKey('data')) {
      final d = merged['data'];
      if (d is String) {
        try {
          final decoded = jsonDecode(d);
          if (decoded is Map) {
            final cand =
                decoded['nama'] ??
                decoded['nama_pasien'] ??
                decoded['patient_name'];
            if (cand != null) namaPasien = cand.toString();
          }
        } catch (_) {}
      } else if (d is Map<String, dynamic>) {
        final cand = d['nama'] ?? d['nama_pasien'] ?? d['patient_name'];
        if (cand != null) namaPasien = cand.toString();
      }
    }

    return {'id': idAssessment, 'nama': namaPasien};
  }

  // ===========================
  // Save flow: create patient, then create cppt
  // ===========================
  Future<void> cppt() async {
    final merged = _cachedExtractedFields ?? {};
    final idAndName = _extractIdAndName(merged);
    final idAssessment = idAndName['id'] as int?;
    final namaPasien = idAndName['nama'] as String?;

    if (idAssessment == null) {
      _showErrorSnackBar(
        'Gagal: id_assesment tidak ditemukan pada data assessment.',
      );
      return;
    }
    if (namaPasien == null || namaPasien.isEmpty) {
      _showErrorSnackBar(
        'Gagal: nama pasien tidak ditemukan pada data assessment.',
      );
      return;
    }

    // Pastikan token tersedia
    if (widget.token == null || widget.token!.isEmpty) {
      _showErrorSnackBar('Token tidak tersedia. Silakan login ulang.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 1) buat patient
      final patientId = await _createPatient(
        idAssessment: idAssessment,
        nama: namaPasien,
      );
      if (patientId == null) {
        throw Exception(
          'Server tidak mengembalikan patient id setelah membuat patient.',
        );
      }

      // 2) detect perawat id
      final perawatId = _detectPerawatId(merged, widget.apiResponse);
      // jika perawatId masih 0, hentikan dan beri pesan yang jelas
      if (perawatId == 0) {
        if (mounted) {
          _showErrorSnackBar(
            'Gagal: perawat_id tidak ditemukan pada data. Pastikan "username" berisi id perawat atau token JWT valid berisi id user.',
          );
        }
        return;
      }

      // 3) buat cppt
      final cpptResp = await _createCppt(
        patientId: patientId,
        perawatId: perawatId,
        query: widget.reportText,
      );

      // parse cppt id dari response
      int? cpptId;
      if (cpptResp != null) {
        if (cpptResp['id'] != null) cpptId = int.tryParse(cpptResp['id'].toString());
        if (cpptId == null && cpptResp['cppt_id'] != null) cpptId = int.tryParse(cpptResp['cppt_id'].toString());
        if (cpptId == null && cpptResp['data'] is Map && cpptResp['data']['id'] != null) cpptId = int.tryParse(cpptResp['data']['id'].toString());
      }

      // sukses -> notify dan lanjut ke VocareReport3
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sukses menyimpan patient dan CPPT.'),
            backgroundColor: Colors.green,
          ),
        );

        if (cpptId != null) {
          // navigate and pass cppt id + token
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VocareReport3(
                cpptId: cpptId ?? 0,
                token: widget.token,
              ),
            ),
          );
        } else {
          // jika id tidak ditemukan, tetap navigasi tanpa id (fallback)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VocareReport3(
                cpptId: 0,
                token: widget.token,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Gagal menyimpan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ===========================
  // UI build
  // ===========================
  @override
  Widget build(BuildContext context) {
    final extractedFields = _cachedExtractedFields ?? {};

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        titleSpacing: 60,
        title: const Text(
          'Vocare Report',
          style: TextStyle(fontSize: 20, color: _titleColor),
        ),
        backgroundColor: _appBarBackgroundColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 18, top: 10),
            children: [
              const SizedBox(height: 6),
              const Text(
                'Assessment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 10),

              buildInformasiUmumSection(extractedFields),
              const SizedBox(height: _sectionSpacing),
              buildPengantarPendampingSection(extractedFields),
              const SizedBox(height: _sectionSpacing),
              buildKeluhanUtamaSection(extractedFields),
              const SizedBox(height: _sectionSpacing),
              buildRiwayatKesehatanSection(extractedFields),
              const SizedBox(height: _sectionSpacing),
              buildStatusGeneralSection(extractedFields),
              const SizedBox(height: _sectionSpacing),
              buildPemeriksaanFisikSection(extractedFields),
              const SizedBox(height: _sectionSpacing),
              buildAsesmenNyeriSection(extractedFields),
              const SizedBox(height: _sectionSpacing),
              buildSkriningGiziSection(extractedFields),
              const SizedBox(height: _sectionSpacing),
              buildSkriningRisikoJatuhSection(extractedFields),
              const SizedBox(height: _sectionSpacing),
              buildStatusPsikososialSection(extractedFields),
              const SizedBox(height: _sectionSpacing),
              buildRencanaPerawatanSection(extractedFields),
              const SizedBox(height: _sectionSpacing),
              buildMasalahKeperawatanSection(extractedFields),
              const SizedBox(height: _sectionSpacing),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : cppt,
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonSaveColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'CPPT',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}



