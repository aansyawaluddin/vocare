import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vocare/common/type.dart';

class AskepViewPage extends StatefulWidget {
  final int patientId;
  final String patientName;
  final User user;

  const AskepViewPage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.user,
  });

  @override
  State<AskepViewPage> createState() => _AskepViewPageState();
}

class _AskepViewPageState extends State<AskepViewPage> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _askepData;

  @override
  void initState() {
    super.initState();
    _findAndFetchAskep();
  }

  Future<void> _findAndFetchAskep() async {
    try {
      String baseUrl = dotenv.env['API_URL'] ?? '';
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final searchUrl = Uri.parse(
        '$baseUrl/laporan?patient_id=${widget.patientId}',
      );

      final searchResponse = await http.get(
        searchUrl,
        headers: {'Authorization': 'Bearer ${widget.user.token}'},
      );

      int? foundLaporanId;

      if (searchResponse.statusCode >= 200 && searchResponse.statusCode < 300) {
        final jsonResponse = jsonDecode(searchResponse.body);
        final List<dynamic> dataList = jsonResponse['data'] ?? [];

        if (dataList.isNotEmpty) {

          final matchingReport = dataList.firstWhere((laporan) {
            final idDiLaporan = int.tryParse(laporan['patient_id'].toString());
            return idDiLaporan == widget.patientId;
          }, orElse: () => null);

          if (matchingReport != null) {
            foundLaporanId = matchingReport['id']; 
            debugPrint(
              'MATCHING ID FOUND: $foundLaporanId for Patient ${widget.patientId}',
            );
          } else {
            debugPrint(
              'Tidak ditemukan laporan dengan patient_id ${widget.patientId} dalam list.',
            );
          }
        }
      }

      if (foundLaporanId == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Belum ada data ASKEP untuk pasien ini.';
            _isLoading = false;
          });
        }
        return;
      }

      // 2. Ambil detail laporan (ID 43)
      final detailUrl = Uri.parse('$baseUrl/laporan/$foundLaporanId');

      final detailResponse = await http.get(
        detailUrl,
        headers: {
          'Authorization': 'Bearer ${widget.user.token}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (detailResponse.statusCode >= 200 && detailResponse.statusCode < 300) {
        final jsonDetail = jsonDecode(detailResponse.body);

        if (mounted) {
          setState(() {
            _askepData = jsonDetail['data'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Gagal mengambil detail ASKEP (Status: ${detailResponse.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> _parseList(dynamic data) {
    if (data == null) return [];

    if (data is List) return data;

    if (data is String) {
      if (data.trim().isEmpty || data == '[]') return [];

      try {
        final decoded = jsonDecode(data);
        if (decoded is List) return decoded;
      } catch (e) {
        return [data];
      }
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    final Color navyColor = const Color(0xFF082B54);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Data ASKEP",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              widget.patientName,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        backgroundColor: navyColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[100],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.code_off, color: Colors.grey, size: 60),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = '';
                  });
                  _findAndFetchAskep();
                },
                child: const Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      );
    }

    final List<dynamic> sdkiList = _parseList(_askepData?['SDKI']);
    final List<dynamic> sikiList = _parseList(_askepData?['SIKI']);
    final List<dynamic> slkiList = _parseList(_askepData?['SLKI']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            "SDKI ",
            sdkiList,
            Colors.red.shade50,
            Colors.red.shade900,
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            "SLKI ",
            slkiList,
            Colors.green.shade50,
            Colors.green.shade900,
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            "SIKI",
            sikiList,
            Colors.blue.shade50,
            Colors.blue.shade900,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    List<dynamic> items,
    Color bgColor,
    Color titleColor,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: items.isEmpty
                ? const Text("-", style: TextStyle(color: Colors.grey))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              item.toString().replaceAll(
                                RegExp(r'[\[\]"]'),
                                '',
                              ),
                              textAlign: TextAlign.justify,
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
