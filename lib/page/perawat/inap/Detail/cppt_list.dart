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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // API call is modified to fetch all CPPTs and then filter locally
    final url = Uri.parse('${_getBaseUrl()}/cppt');

    try {
      final response = await http.get(url, headers: _getAuthHeaders());

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['data'] is List) {
          final allData = List<Map<String, dynamic>>.from(body['data']);

          // Filtering the list to match the current patient ID
          final filteredList = allData.where((cppt) {
            return cppt['patient_id'].toString() == widget.patientId.toString();
          }).toList();

          setState(() {
            _cpptList = filteredList;
          });
        } else {
          setState(() {
            _cpptList = [];
          });
        }
      } else {
        throw Exception(
          'Gagal memuat daftar CPPT: Status Code ${response.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
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
        title: Text(
          "Riwayat CPPT: ${widget.patientName}",
          style: const TextStyle(color: Colors.white),
        ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Terjadi Kesalahan:\n$_error",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_cpptList.isEmpty) {
      return const Center(
        child: Text("Tidak ada riwayat CPPT untuk pasien ini."),
      );
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
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
  
  String _detectShiftFromTime() {
    final tanggal = cpptData['tanggal'];
    if (tanggal == null) return 'Tidak diketahui';

    try {
      final dt = DateTime.parse(tanggal.toString()).toLocal();
      final h = dt.hour;
      if (h >= 6 && h < 12) return 'Pagi (Shift 1)';
      if (h >= 12 && h < 18) return 'Siang (Shift 2)';
      return 'Malam (Shift 3)';
    } catch (_) {
      return 'Tidak diketahui';
    }
  }

  Color _colorForShiftLabel(String shiftLabel) {
    final s = shiftLabel.toLowerCase();
    if (s.contains('pagi') || s.contains('shift 1')) {
      return const Color(0xFF3B82F6); // biru
    }
    if (s.contains('siang') || s.contains('shift 2')) {
      return const Color(0xFF10B981); // hijau
    }
    if (s.contains('malam') || s.contains('shift 3')) {
      return const Color(0xFFF59E0B); // jingga
    }
    return const Color(0xFF6B7280); // abu-abu untuk unknown
  }

  String _formatAssessment(String? rawText) {
    if (rawText == null || rawText.isEmpty) {
      return 'Tidak ada data.';
    }

    String cleanedText = rawText.replaceAll(RegExp(r'[{}"[\]]'), '');

    List<String> items = cleanedText
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (items.isEmpty) {
      return cleanedText;
    }

    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < items.length; i++) {
      buffer.write('${i + 1}. ${items[i]}');
      if (i < items.length - 1) buffer.write('\n');
    }
    return buffer.toString();
  }

  Widget _buildDetailSection(String title, String? content) {
    final String displayContent = title == "Assessment"
        ? _formatAssessment(content)
        : (content != null && content.isNotEmpty ? content : 'Tidak ada data.');

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
          displayContent,
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
    final shiftLabel = _detectShiftFromTime();
    final shiftColor = _colorForShiftLabel(shiftLabel);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    shiftLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: shiftColor,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: shiftColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    formatDate(cpptData['tanggal']),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: shiftColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailSection("Subjective", cpptData['subjective']),
            _buildDetailSection("Objective", cpptData['objective']),
            _buildDetailSection("Assessment", cpptData['assessment']),
            _buildDetailSection("Plan", cpptData['plan']),
            _buildDetailSection("Keterangan", cpptData['keterangan']),
          ],
        ),
      ),
    );
  }
}
