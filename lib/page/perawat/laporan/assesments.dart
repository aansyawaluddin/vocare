// VocareReport2_fixed_send_fenced_data.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vocare/widgets/perawat/report_widgets.dart';
import 'package:vocare/widgets/perawat/report_utils.dart';
import 'package:vocare/page/perawat/laporan/cppt_and_intervensi.dart';

class VocareReport2 extends StatefulWidget {
  final String reportText;
  final Map<String, dynamic>? apiResponse;
  final String? username;
  final String? token;

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
  Map<String, dynamic>? _cachedExtractedFields;
  bool _isSaving = false;
  List<String> _rencanaAsuhan = [];

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
      final pretty = const JsonEncoder.withIndent('  ').convert(widget.apiResponse);
      _debugPrintFull(pretty);
    } catch (e) {
      _debugPrintFull(widget.apiResponse?.toString() ?? 'apiResponse: null');
    }
  }

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

  void _cacheExtractedFields() {
    final Map<String, dynamic> merged = {};

    if (widget.apiResponse != null) {
      widget.apiResponse!.forEach((k, v) {
        merged[k] = v;
      });

      final dynamic dataField = widget.apiResponse!['data'];
      if (dataField is Map<String, dynamic>) {
        dataField.forEach((k, v) {
          if (!merged.containsKey(k)) merged[k] = v;
        });
      } else if (dataField is String) {
        try {
          final parsed = _tryParseLenient(dataField) ?? jsonDecode(dataField);
          if (parsed is Map<String, dynamic>) {
            parsed.forEach((k, v) {
              if (!merged.containsKey(k)) merged[k] = v;
            });
          }
        } catch (_) {}
      }
    }

    try {
      final extractedFromData = extractAssessmentObject(widget.apiResponse);
      final extractedFieldsFromData = extractFieldsFromAssessment(extractedFromData);
      if (extractedFieldsFromData != null) {
        extractedFieldsFromData.forEach((k, v) {
          if (!merged.containsKey(k)) merged[k] = v;
        });
      }
    } catch (_) {}

    _cachedExtractedFields = merged;

    List<String> rencana = [];
    try {
      final cand = merged['rencana_asuhan_list'] ?? merged['rencana_asuhan'] ?? merged['rencana_asuhan_keperawatan'];
      if (cand is List) {
        rencana = cand.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      } else if (cand is String && cand.trim().isNotEmpty) {
        rencana = cand.split(RegExp(r'\r?\n|;|,|-')).map((e) => e.trim()).where((s) => s.isNotEmpty).toList();
      }
    } catch (_) {
      rencana = [];
    }

    _rencanaAsuhan = rencana;

    if (kDebugMode) {
      try {
        debugPrint('Merged extracted fields: ${jsonEncode(_cachedExtractedFields)}');
      } catch (_) {
        debugPrint('Merged extracted fields (toString): $_cachedExtractedFields');
      }
      debugPrint('Initial rencana_asuhan: $_rencanaAsuhan');
    }
  }

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
      if (kDebugMode)
        debugPrint('Authorization header set (partial): ${widget.token!.substring(0, widget.token!.length > 8 ? 8 : widget.token!.length)}...');
    } else {
      if (kDebugMode) debugPrint('No token available; Authorization header NOT set.');
    }
    return headers;
  }

  Future<int?> _createPatient({required int idAssessment, required String nama}) async {
    final baseUrl = _baseUrlFromEnv();
    final url = '$baseUrl/patients/';
    final body = jsonEncode({'id_assesment': idAssessment, 'nama': nama});
    try {
      if (kDebugMode) debugPrint('POST $url -> $body');
      final resp = await http.post(Uri.parse(url), headers: _buildHeaders(), body: body);
      if (kDebugMode) debugPrint('CreatePatient response ${resp.statusCode}: ${resp.body}');
      if (resp.statusCode == 200 || resp.statusCode == 201 || resp.statusCode == 202) {
        if (resp.body.isEmpty) return null;
        final Map<String, dynamic> data = jsonDecode(resp.body);
        if (data.containsKey('id')) return (data['id'] is int) ? data['id'] : int.tryParse(data['id'].toString());
        if (data.containsKey('patient_id')) return (data['patient_id'] is int) ? data['patient_id'] : int.tryParse(data['patient_id'].toString());
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

  Future<Map<String, dynamic>?> _createCppt({required int patientId, required int perawatId, required String query}) async {
    final baseUrl = _baseUrlFromEnv();
    final url = '$baseUrl/cppt/';
    final bodyMap = {
      'patient_id': patientId,
      'perawat_id': perawatId,
      'query': query,
      'patientId': patientId,
      'perawatId': perawatId,
    };
    final body = jsonEncode(bodyMap);
    try {
      if (kDebugMode) debugPrint('POST $url -> $body');
      final resp = await http.post(Uri.parse(url), headers: _buildHeaders(), body: body);
      if (kDebugMode) debugPrint('CreateCPPT response ${resp.statusCode}: ${resp.body}');
      if (resp.statusCode == 200 || resp.statusCode == 201 || resp.statusCode == 202) {
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

  // === NEW: Intervensi POST endpoint helper ===
  // POST /intervensi/ with body { "patient_id":0, "query":"string", "user_id":0 }
  Future<Map<String, dynamic>?> _createIntervensi({required int patientId, required int perawatId, required String query}) async {
    final baseUrl = _baseUrlFromEnv();
    final url = '$baseUrl/intervensi/';
    final bodyMap = {
      'patient_id': patientId,
      'query': query,
      'user_id': perawatId,
    };
    final body = jsonEncode(bodyMap);
    try {
      if (kDebugMode) debugPrint('POST $url -> $body');
      final resp = await http.post(Uri.parse(url), headers: _buildHeaders(), body: body);
      if (kDebugMode) debugPrint('CreateIntervensi response ${resp.statusCode}: ${resp.body}');
      if (resp.statusCode == 200 || resp.statusCode == 201 || resp.statusCode == 202) {
        if (resp.body.isEmpty) return {};
        final data = jsonDecode(resp.body);
        if (data is Map<String, dynamic>) return data;
        return {'result': data};
      } else {
        String msg = resp.body;
        try {
          final parsed = jsonDecode(resp.body);
          if (parsed is Map && parsed['message'] != null) msg = parsed['message'].toString();
        } catch (_) {}
        throw Exception('Create intervensi failed: ${resp.statusCode} - $msg');
      }
    } catch (e) {
      rethrow;
    }
  }

  int _detectPerawatId(Map<String, dynamic>? merged, Map<String, dynamic>? apiResponse) {
    try {
      if (merged != null) {
        final keys = ['perawat_id','perawatId','perawat','created_by','id_perawat','user_id','userId'];
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
        final keys = ['perawat_id','perawatId','perawat','user_id','userId'];
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

      if (widget.token != null && widget.token!.isNotEmpty) {
        final fromJwt = _extractPerawatIdFromJwt(widget.token);
        if (fromJwt != null) return fromJwt;
      }
    } catch (_) {}

    return 0;
  }

  int? _extractPerawatIdFromJwt(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> map = jsonDecode(decoded);
      final keys = ['perawat_id','user_id','id','sub','perawatId','userId'];
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Map<String, dynamic> _extractIdAndName(Map<String, dynamic>? merged) {
    int? idAssessment;
    String? namaPasien;

    if (merged == null) return {'id': null, 'nama': null};

    final topId = merged['id'];
    if (topId != null) {
      if (topId is int) idAssessment = topId;
      else idAssessment = int.tryParse(topId.toString());
    }

    final idCandidates = ['id_assesment','id_assessment','assesment_id','assessment_id','assessmentId'];
    for (final k in idCandidates) {
      if (idAssessment != null) break;
      if (merged.containsKey(k)) {
        final v = merged[k];
        if (v is int) idAssessment = v;
        else idAssessment = int.tryParse(v?.toString() ?? '');
      }
    }

    final nameCandidates = ['nama_pasien','nama','patient_name','patient','informasi_umum.nama_pasien','informasi_umum.nama','data.nama_pasien','data.nama'];

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

    if ((namaPasien == null || namaPasien.isEmpty) && merged.containsKey('data')) {
      final d = merged['data'];
      if (d is String) {
        try {
          final decoded = _tryParseLenient(d) ?? jsonDecode(d);
          if (decoded is Map) {
            final cand = decoded['nama'] ?? decoded['nama_pasien'] ?? decoded['patient_name'];
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

Future<void> cppt() async {
  final merged = _cachedExtractedFields ?? {};
  final idAndName = _extractIdAndName(merged);
  final idAssessment = idAndName['id'] as int?;
  final namaPasien = idAndName['nama'] as String?;

  if (idAssessment == null) {
    _showErrorSnackBar('Gagal: id_assesment tidak ditemukan pada data assessment.');
    return;
  }
  if (namaPasien == null || namaPasien.isEmpty) {
    _showErrorSnackBar('Gagal: nama pasien tidak ditemukan pada data assessment.');
    return;
  }

  if (widget.token == null || widget.token!.isEmpty) {
    _showErrorSnackBar('Token tidak tersedia. Silakan login ulang.');
    return;
  }

  setState(() { _isSaving = true; });

  try {
    final patientId = await _createPatient(idAssessment: idAssessment, nama: namaPasien);
    if (patientId == null) throw Exception('Server tidak mengembalikan patient id setelah membuat patient.');

    final perawatId = _detectPerawatId(merged, widget.apiResponse);
    if (perawatId == 0) {
      if (mounted) {
        _showErrorSnackBar('Gagal: perawat_id tidak ditemukan pada data. Pastikan "username" berisi id perawat atau token JWT valid berisi id user.');
      }
      if (mounted) setState(() { _isSaving = false; });
      return;
    }

    final cpptResp = await _createCppt(patientId: patientId, perawatId: perawatId, query: widget.reportText);

    int? cpptId;
    if (cpptResp != null) {
      if (cpptResp['id'] != null) cpptId = int.tryParse(cpptResp['id'].toString());
      if (cpptId == null && cpptResp['cppt_id'] != null) cpptId = int.tryParse(cpptResp['cppt_id'].toString());
      if (cpptId == null && cpptResp['data'] is Map && cpptResp['data']['id'] != null) cpptId = int.tryParse(cpptResp['data']['id'].toString());
    }

    // === NEW: create intervensi and parse its id ===
    int? intervensiId;
    try {
      final intervensiResp = await _createIntervensi(patientId: patientId, perawatId: perawatId, query: widget.reportText);
      if (kDebugMode) debugPrint('Intervensi response: ${intervensiResp ?? 'null'}');

      if (intervensiResp != null) {
        if (intervensiResp['id'] != null) {
          intervensiId = int.tryParse(intervensiResp['id'].toString());
        } else if (intervensiResp['intervensi_id'] != null) {
          intervensiId = int.tryParse(intervensiResp['intervensi_id'].toString());
        } else if (intervensiResp['data'] is Map && intervensiResp['data']['id'] != null) {
          intervensiId = int.tryParse(intervensiResp['data']['id'].toString());
        } else {
          // coba cari int di values (fallback)
          for (final v in intervensiResp.values) {
            if (v is int) {
              intervensiId = v;
              break;
            }
            if (v is String) {
              final parsed = int.tryParse(v);
              if (parsed != null) {
                intervensiId = parsed;
                break;
              }
            }
            if (v is Map && v['id'] != null) {
              intervensiId = int.tryParse(v['id'].toString());
              if (intervensiId != null) break;
            }
          }
        }
      }
    } catch (e) {
      // jangan block flow CPPT jika intervensi gagal
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Peringatan: gagal mengirim intervensi: $e'), backgroundColor: Colors.orange));
      if (kDebugMode) debugPrint('Create intervensi failed: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sukses menyimpan pasien, CPPT dan Intervensi.'), backgroundColor: Colors.green));

      Navigator.push(context, MaterialPageRoute(builder: (context) => VocareReport3(
        cpptId: cpptId ?? 0,
        token: widget.token,
        patientId: patientId,
        perawatId: perawatId,
        intervensiId: intervensiId ?? 0,
        query: widget.reportText,
      )));
    }
  } catch (e) {
    if (mounted) _showErrorSnackBar('Gagal menyimpan: $e');
  } finally {
    if (mounted) setState(() { _isSaving = false; });
  }
}


  Future<void> _deleteAssessment() async {
    final merged = _cachedExtractedFields ?? {};
    final idAndName = _extractIdAndName(merged);
    final idAssessment = idAndName['id'] as int?;

    if (idAssessment == null) {
      _showErrorSnackBar('Tidak dapat menghapus: id_assesment tidak ditemukan.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus assessment ini? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() { _isSaving = true; });

    try {
      final baseUrl = _baseUrlFromEnv();
      final endpointsToTry = ['$baseUrl/assesments/$idAssessment','$baseUrl/assessments/$idAssessment'];

      http.Response? lastResp;
      for (final url in endpointsToTry) {
        try {
          if (kDebugMode) debugPrint('DELETE $url');
          final resp = await http.delete(Uri.parse(url), headers: _buildHeaders());
          lastResp = resp;
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assessment berhasil dihapus.'), backgroundColor: Colors.green));
              Navigator.of(context).pop();
            }
            return;
          } else {
            if (kDebugMode) debugPrint('DELETE failed ${resp.statusCode}: ${resp.body}');
          }
        } catch (e) {
          if (kDebugMode) debugPrint('DELETE attempt error for $url -> $e');
        }
      }

      String msg = 'Gagal menghapus assessment.';
      if (lastResp != null) {
        try {
          final parsed = jsonDecode(lastResp.body);
          if (parsed is Map && parsed['message'] != null) msg = parsed['message'].toString();
          else msg = 'Server: ${lastResp.statusCode}';
        } catch (_) { msg = 'Server: ${lastResp.statusCode}'; }
      }
      if (mounted) _showErrorSnackBar('$msg');
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  // === MODIFIED method: PUT that sends top-level data as a fenced JSON string containing only the
  // asesmen_awal_keperawatan object (matches server-required format) ===
  Future<void> _saveRencanaAsuhan_StrictPut() async {
    final merged = _cachedExtractedFields ?? {};
    final idAndName = _extractIdAndName(merged);
    final int? idAssessment = idAndName['id'] as int?;

    if (idAssessment == null) {
      _showErrorSnackBar(
        'Gagal: id_assesment tidak ditemukan, tidak dapat menyimpan rencana asuhan.',
      );
      return;
    }

    setState(() => _isSaving = true);
    final baseUrl = _baseUrlFromEnv();
    final url = '$baseUrl/assesments/$idAssessment';

    try {
      // 1) GET current resource (lenient parsing)
      if (kDebugMode) debugPrint('GET $url');
      final getResp = await http.get(Uri.parse(url), headers: _buildHeaders());

      if (kDebugMode) debugPrint('GET resp ${getResp.statusCode}: ${getResp.body}');

      Map<String, dynamic> serverObj = {};
      dynamic getDecoded;

      if (getResp.statusCode >= 200 && getResp.statusCode < 300 && getResp.body.isNotEmpty) {
        getDecoded = _tryParseLenient(getResp.body) ?? (() {
          try {
            return jsonDecode(getResp.body);
          } catch (_) {
            return null;
          }
        })();

        if (getDecoded is Map<String, dynamic>) {
          serverObj = Map<String, dynamic>.from(getDecoded);
        } else {
          serverObj = Map<String, dynamic>.from(merged);
        }
      } else {
        if (kDebugMode)
          debugPrint('GET failed ${getResp.statusCode}: ${getResp.body}. Using cached data.');
        serverObj = Map<String, dynamic>.from(merged);
      }

      serverObj = serverObj ?? <String, dynamic>{};

      // Normalize top-level "data" into Map so we can find the nested asesmen object
      Map<String, dynamic> normalizedTopData = {};
      if (serverObj['data'] != null) {
        if (serverObj['data'] is String) {
          normalizedTopData = _tryParseLenient(serverObj['data']) ?? (() {
            try {
              final d = jsonDecode(serverObj['data']);
              return (d is Map<String, dynamic>) ? d : <String, dynamic>{};
            } catch (_) {
              return <String, dynamic>{};
            }
          })();
        } else if (serverObj['data'] is Map<String, dynamic>) {
          normalizedTopData = Map<String, dynamic>.from(serverObj['data']);
        }
      }

      // level2 should be the object that contains 'asesmen_awal_keperawatan'
      Map<String, dynamic> level2 = {};

      // Several possible shapes exist: serverObj['data'] may already be level1 (with 'data'),
      // or normalizedTopData may contain 'data' which then contains asesmen...
      try {
        // If normalizedTopData contains 'data' and that is Map -> use it
        if (normalizedTopData['data'] is Map<String, dynamic>) {
          level2 = Map<String, dynamic>.from(normalizedTopData['data']);
        } else if (normalizedTopData['asesmen_awal_keperawatan'] is Map<String, dynamic>) {
          // already the desired object
          level2 = Map<String, dynamic>.from(normalizedTopData);
        } else if (serverObj['data'] is Map && (serverObj['data']['data'] is Map)) {
          level2 = Map<String, dynamic>.from(serverObj['data']['data'] as Map);
        } else if (serverObj['data'] is Map && serverObj['data']['asesmen_awal_keperawatan'] is Map) {
          level2 = Map<String, dynamic>.from(serverObj['data'] as Map);
        }
      } catch (_) {
        level2 = {};
      }

      // ensure asesmen_awal_keperawatan exists
      level2['asesmen_awal_keperawatan'] ??= <String, dynamic>{};
      final Map<String, dynamic> asesmen = Map<String, dynamic>.from(
        level2['asesmen_awal_keperawatan'] as Map,
      );

      asesmen['rencana_asuhan_keperawatan'] = List<dynamic>.from(_rencanaAsuhan);

      // put back
      level2['asesmen_awal_keperawatan'] = asesmen;

      // Build the fenced JSON payload where top-level 'data' is a fenced string containing only level2
      final prettyLevel2 = const JsonEncoder.withIndent('  ').convert(level2);
      final fencedLevel2 = '```json\n$prettyLevel2\n```';

      // Determine top-level id / perawat / tanggal to include in payload
      final dynamic topId = serverObj['id'] ?? merged['id'] ?? idAssessment;
      final dynamic perawatTop = serverObj['perawat'] ?? merged['perawat'] ?? merged['perawatId'] ?? widget.username ?? serverObj['user'] ?? serverObj['user_id'];
      final dynamic tanggalTop = serverObj['tanggal'] ?? merged['tanggal'] ?? DateTime.now().toIso8601String();

      final List<Map<String, dynamic>> payloadCandidates = [];

      // Candidate 1: top-level data = fencedLevel2 (preferred, matches your required format)
      final candidate1 = <String, dynamic>{};
      candidate1.addAll(serverObj);
      candidate1['data'] = fencedLevel2;
      if (topId != null) candidate1['id'] = topId;
      if (perawatTop != null) candidate1['perawat'] = perawatTop.toString();
      if (tanggalTop != null) candidate1['tanggal'] = tanggalTop.toString();
      payloadCandidates.add(candidate1);

      // Candidate 2: top-level data = raw JSON string of level2 (no fences)
      final candidate2 = <String, dynamic>{};
      candidate2.addAll(serverObj);
      candidate2['data'] = jsonEncode(level2);
      if (topId != null) candidate2['id'] = topId;
      if (perawatTop != null) candidate2['perawat'] = perawatTop.toString();
      if (tanggalTop != null) candidate2['tanggal'] = tanggalTop.toString();
      payloadCandidates.add(candidate2);

      // Candidate 3: top-level data = nested map (level2)
      final candidate3 = <String, dynamic>{};
      candidate3.addAll(serverObj);
      candidate3['data'] = level2;
      if (topId != null) candidate3['id'] = topId;
      if (perawatTop != null) candidate3['perawat'] = perawatTop.toString();
      if (tanggalTop != null) candidate3['tanggal'] = tanggalTop.toString();
      payloadCandidates.add(candidate3);

      http.Response? putResp;
      String lastErr = '';

      for (final candidate in payloadCandidates) {
        try {
          final body = jsonEncode(candidate);

          if (kDebugMode) {
            debugPrint('Trying PUT $url (payload length: ${body.length}).');
            final preview = body.length > 1500 ? body.substring(0, 1500) + '... (truncated)' : body;
            debugPrint('Payload preview: $preview');
          }

          putResp = await http.put(
            Uri.parse(url),
            headers: _buildHeaders(),
            body: body,
          );

          if (kDebugMode) debugPrint('PUT resp ${putResp.statusCode}: ${putResp.body}');

          if (putResp.statusCode >= 200 && putResp.statusCode < 300) {
            // success — update cache so UI reflects new rencana
            _cachedExtractedFields ??= {};
            _cachedExtractedFields!['rencana_asuhan_list'] = List<String>.from(_rencanaAsuhan);

            // try to mirror nested positions in cache
            try {
              _cachedExtractedFields!['data'] ??= <String, dynamic>{};
              final l1Cache = _cachedExtractedFields!['data'];
              if (l1Cache is Map) {
                // ensure nested shape exists similar to level2
                l1Cache['data'] ??= <String, dynamic>{};
                final l2Cache = l1Cache['data'];
                if (l2Cache is Map) {
                  l2Cache['asesmen_awal_keperawatan'] ??= <String, dynamic>{};
                  final am = Map<String, dynamic>.from(l2Cache['asesmen_awal_keperawatan'] as Map);
                  am['rencana_asuhan_keperawatan'] = List<dynamic>.from(_rencanaAsuhan);
                  l2Cache['asesmen_awal_keperawatan'] = am;
                  l1Cache['data'] = l2Cache;
                  _cachedExtractedFields!['data'] = l1Cache;
                }
              }
            } catch (_) {}

            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rencana asuhan berhasil disimpan.'),
                  backgroundColor: Colors.green,
                ),
              );
            return; // done
          } else {
            String msg = 'Server: ${putResp.statusCode}';
            try {
              final parsed = jsonDecode(putResp.body);
              if (parsed is Map && parsed['message'] != null) msg = parsed['message'].toString();
              else msg = 'Server: ${putResp.statusCode}';
            } catch (_) {
              msg = 'Server: ${putResp.statusCode}';
            }
            lastErr = msg + ' - ' + putResp.body;
            if (kDebugMode) debugPrint('PUT candidate failed: $lastErr');
            // try next candidate
          }
        } catch (e, st) {
          lastErr = 'PUT attempt exception: $e';
          if (kDebugMode) {
            debugPrint(lastErr);
            debugPrint(st.toString());
          }
          // try next candidate
        }
      }

      if (mounted) _showErrorSnackBar('Gagal menyimpan rencana asuhan: $lastErr');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error _saveRencanaAsuhan_StrictPut: $e');
        debugPrint(st.toString());
      }
      if (mounted) _showErrorSnackBar('Gagal menyimpan rencana asuhan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Lenient parser that tries several heuristics to recover Map<String,dynamic>
  /// from server responses that might be double-encoded, fenced, or python-repr-like.
  Map<String, dynamic>? _tryParseLenient(dynamic raw) {
    if (raw == null) return null;
    String s = raw is String ? raw.trim() : raw.toString();
    if (s.isEmpty) return null;

    // 1) strip fenced code block markers (```json ... ```) - common from some services
    s = s.replaceAll(RegExp(r'^\s*```(?:json)?\s*'), '');
    s = s.replaceAll(RegExp(r'\s*```\s*\$'), '');

    // 2) try direct jsonDecode
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) return Map<String, dynamic>.from(decoded);
      if (decoded is List) return {'_list': decoded};
    } catch (_) {}

    // 3) try extracting substring from first '{' to last '}' (useful when wrapped in quotes)
    final firstBrace = s.indexOf('{');
    final lastBrace = s.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      final sub = s.substring(firstBrace, lastBrace + 1);
      try {
        final decodedSub = jsonDecode(sub);
        if (decodedSub is Map<String, dynamic>) return Map<String, dynamic>.from(decodedSub);
      } catch (_) {}
    }

    // 4) naive single-quote -> double-quote replacement (risky: may break apostrophes) - last resort
    try {
      final replaced = s.replaceAll("'", '"');
      final decoded = jsonDecode(replaced);
      if (decoded is Map<String, dynamic>) return Map<String, dynamic>.from(decoded);
    } catch (_) {}

    return null;
  }

  void _onRencanaChanged(List<String> updated) {
    setState(() { _rencanaAsuhan = updated; });
  }

  @override
  Widget build(BuildContext context) {
    final extractedFields = _cachedExtractedFields ?? {};
    final idAndName = _extractIdAndName(extractedFields);
    final idAssessment = idAndName['id'] as int?;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            titleSpacing: 60,
            title: const Text('Vocare Report', style: TextStyle(fontSize: 20, color: _titleColor)),
            backgroundColor: _appBarBackgroundColor,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 18, top: 10),
                children: [
                  const SizedBox(height: 6),
                  const Text('Assessment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _titleColor)),
                  const SizedBox(height: 10),

                  buildInformasiUmumSection(extractedFields),
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
                  RencanaAsuhanEditor(initialRencana: _rencanaAsuhan, editable: true, onChanged: _onRencanaChanged),
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
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_isSaving || idAssessment == null) ? null : _deleteAssessment,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_isSaving) ? null : _saveRencanaAsuhan_StrictPut,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan Rencana', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : cppt,
                        style: ElevatedButton.styleFrom(backgroundColor: _buttonSaveColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        child: const Text('Next', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (_isSaving) ...[
          const ModalBarrier(dismissible: false, color: Colors.black45),
          const Center(child: SizedBox(height: 64, width: 64, child: CircularProgressIndicator(strokeWidth: 4))),
        ],
      ],
    );
  }
}
