import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vocare/common/type.dart';

class CpptListPage extends StatefulWidget {
  final int patientId;
  final String patientName;
  final User user;

  const CpptListPage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.user,
  });

  @override
  State<CpptListPage> createState() => _CpptListPageState();
}

class _CpptListPageState extends State<CpptListPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _cpptList = [];

  @override
  void initState() {
    super.initState();
    _fetchCpptList();
  }

  String _getBaseUrl() {
    return dotenv.env['API_URL'] ?? dotenv.env['API_BASE_URL'] ?? '';
  }

  Map<String, String> _getAuthHeaders() {
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${widget.user.token}',
    };
  }

  Future<void> _fetchCpptList() async {
    final url = Uri.parse('${_getBaseUrl()}/cppt?patient_id=${widget.patientId}');
    
    try {
      final response = await http.get(url, headers: _getAuthHeaders());
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['data'] is List) {
          setState(() {
            _cpptList = List<Map<String, dynamic>>.from(body['data']);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Gagal memuat daftar CPPT: Status Code ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final Color navyColor = const Color(0xFF082B54);
    return Scaffold(
      appBar: AppBar(
        title: Text("Riwayat CPPT: ${widget.patientName}", style: const TextStyle(color: Colors.white)),
        backgroundColor: navyColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("Terjadi Kesalahan:\n$_error", textAlign: TextAlign.center),
      ));
    }

    if (_cpptList.isEmpty) {
      return const Center(child: Text("Tidak ada riwayat CPPT untuk pasien ini."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _cpptList.length,
      itemBuilder: (context, index) {
        final cppt = _cpptList[index];
        return CpptDetailCard(cpptData: cppt);
      },
    );
  }
}

class CpptDetailCard extends StatelessWidget {
  final Map<String, dynamic> cpptData;

  const CpptDetailCard({super.key, required this.cpptData});
  
  String formatDate(String? iso) {
    if (iso == null) return 'Tanggal tidak tersedia';
    try {
      final dt = DateTime.parse(iso).toLocal(); // Convert to local time
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildDetailSection(String title, String? content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF082B54),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content ?? 'Tidak ada data.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withOpacity(0.7),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tanggal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF082B54).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)
              ),
              child: Text(
                formatDate(cpptData['tanggal']),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF082B54),
                  fontSize: 14,
                ),
              ),
            ),
            const Divider(height: 24),

            _buildDetailSection("Assessment", cpptData['assessment']),
            _buildDetailSection("Keterangan", cpptData['keterangan']),
            _buildDetailSection("Objective", cpptData['objective']),
            _buildDetailSection("Plan", cpptData['plan']),
            _buildDetailSection("Subjective", cpptData['subjective']),
          ],
        ),
      ),
    );
  }
}