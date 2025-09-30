import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vocare/widgets/perawat/report_widgets.dart';
import 'package:vocare/widgets/perawat/report_utils.dart';

class AssesmentsInap extends StatefulWidget {
  final int assessmentId;
  final String? token;

  const AssesmentsInap({
    super.key,
    required this.assessmentId,
    this.token,
  });

  @override
  State<AssesmentsInap> createState() => _AssesmentsInapState();
}

const Color _backgroundColor = Color.fromARGB(255, 223, 240, 255);
const Color _appBarBackgroundColor = Color(0xFFD7E2FD);
const Color _titleColor = Color(0xFF093275);

const double _horizontalPadding = 20.0;
const double _sectionSpacing = 12.0;

class _AssesmentsInapState extends State<AssesmentsInap> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _apiResponse;
  
  Map<String, dynamic>? _cachedExtractedFields;
  List<String> _rencanaAsuhan = [];

  @override
  void initState() {
    super.initState();
    _fetchAssessmentData();
  }

  Future<void> _fetchAssessmentData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final baseUrl = _baseUrlFromEnv();
      final endpointsToTry = [
        '$baseUrl/assesments/${widget.assessmentId}',
        '$baseUrl/assessments/${widget.assessmentId}'
      ];
      
      http.Response? response;
      for (final url in endpointsToTry) {
        if (kDebugMode) debugPrint('Attempting GET $url');
        response = await http.get(Uri.parse(url), headers: _buildHeaders());
        if (response.statusCode >= 200 && response.statusCode < 300) {
          break; 
        }
      }

      if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> decodedBody = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _apiResponse = decodedBody;
            _cacheExtractedFieldsFromResponse(decodedBody);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Gagal memuat data assessment: Status code ${response?.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
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

  // --- MODIFIED: Diubah nama dan menerima argumen agar lebih jelas ---
  void _cacheExtractedFieldsFromResponse(Map<String, dynamic> apiResponse) {
    final Map<String, dynamic> merged = {};

    apiResponse.forEach((k, v) {
      merged[k] = v;
    });

    final dynamic dataField = apiResponse['data'];
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

    try {
      final extractedFromData = extractAssessmentObject(apiResponse);
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
    }
    return headers;
  }

  Map<String, dynamic>? _tryParseLenient(dynamic raw) {
    if (raw == null) return null;
    String s = raw is String ? raw.trim() : raw.toString();
    if (s.isEmpty) return null;

    s = s.replaceAll(RegExp(r'^\s*```(?:json)?\s*'), '');
    s = s.replaceAll(RegExp(r'\s*```\s*$'), '');

    try {
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) return Map<String, dynamic>.from(decoded);
      if (decoded is List) return {'_list': decoded};
    } catch (_) {}

    final firstBrace = s.indexOf('{');
    final lastBrace = s.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      final sub = s.substring(firstBrace, lastBrace + 1);
      try {
        final decodedSub = jsonDecode(sub);
        if (decodedSub is Map<String, dynamic>) return Map<String, dynamic>.from(decodedSub);
      } catch (_) {}
    }
    return null;
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text('Gagal memuat data: $_errorMessage', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchAssessmentData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final extractedFields = _cachedExtractedFields ?? {};
    return ListView(
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
        RencanaAsuhanEditor(
          initialRencana: _rencanaAsuhan,
          editable: false,
          onChanged: (updated) {},
        ),
        const SizedBox(height: _sectionSpacing),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        titleSpacing: 60,
        title: const Text('Vocare Report', style: TextStyle(fontSize: 20, color: _titleColor)),
        backgroundColor: _appBarBackgroundColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: _isLoading
              ? _buildLoading()
              : _errorMessage != null
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }
}