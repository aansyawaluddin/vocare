import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/page/perawat/inap/Detail/askep.dart';
import 'package:vocare/page/perawat/inap/detail/assesments.dart';
import 'package:vocare/page/perawat/inap/detail/cppt_list.dart';
import 'package:vocare/page/perawat/inap/detail/intervensi_list.dart'
    as detailIntervensi;
import 'package:vocare/page/perawat/inap/voice.dart';

class PatientDetailPage extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final User user;

  const PatientDetailPage({
    super.key,
    required this.patientData,
    required this.user,
  });

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  Future<int?> _fetchAssessmentId(int patientId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? dotenv.env['API_URL'] ?? '';

      final url = Uri.parse('$baseUrl/assesments?patient_id=$patientId');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.user.token}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (mounted) Navigator.of(context).pop();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> dataList = jsonResponse['data'] ?? [];

        if (dataList.isNotEmpty) {
          final specificAssessment = dataList.firstWhere(
            (element) => element['patient_id'] == patientId,
            orElse: () => null,
          );

          if (specificAssessment != null) {
            return specificAssessment['id'];
          }
        }
      } else {
        debugPrint(
          'Gagal mengambil assessment ID. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      debugPrint('Error fetching assessment ID: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String nama = widget.patientData['nama'] ?? 'Tanpa Nama';
    final String noRm = widget.patientData['no_rekam_medis'] ?? '-';

    final int patientId = widget.patientData['id'] ?? 0;

    final Color navyColor = const Color(0xFF082B54);
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: navyColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Detail Pasien",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: navyColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Informasi Pasien
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No. RM: $noRm',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: buttonStyle,
                onPressed: () async {
                  if (patientId == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ID Pasien tidak valid')),
                    );
                    return;
                  }
                  final int? assessmentId = await _fetchAssessmentId(patientId);

                  if (assessmentId != null && mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AssesmentsInap(
                          assessmentId: assessmentId,
                          token: widget.user.token,
                        ),
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Data Assessment belum tersedia untuk pasien ini.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                child: const Text('Lihat Assesments'),
              ),

              const SizedBox(height: 12),

              // Tombol Lihat CPPT
              ElevatedButton(
                style: buttonStyle,
                onPressed: () {
                  if (patientId != 0) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CpptListPage(
                          patientId: patientId,
                          patientName: nama,
                          user: widget.user,
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Lihat CPPT'),
              ),

              const SizedBox(height: 12),

              // Tombol Lihat Intervensi
              ElevatedButton(
                style: buttonStyle,
                onPressed: () {
                  if (patientId != 0) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            detailIntervensi.IntervensiListPage(
                              patientId: patientId,
                              patientName: nama,
                              user: widget.user,
                            ),
                      ),
                    );
                  }
                },
                child: const Text('Lihat Intervensi'),
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                style: buttonStyle,
                onPressed: () {
                  if (patientId != 0) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AskepViewPage(
                          patientId: patientId,
                          patientName: nama,
                          user: widget.user,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ID Pasien tidak valid')),
                    );
                  }
                },
                child: const Text('Lihat ASKEP'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ElevatedButton.icon(
          onPressed: () {
            if (patientId != 0) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VoicePageLaporanTambahan(
                    user: widget.user,
                    patientId: patientId.toString(),
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Laporan Baru',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF093275),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
      ),
    );
  }
}
