import 'package:flutter/material.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/page/perawat/inap/Detail/intervensi_list.dart';
import 'package:vocare/page/perawat/inap/detail/assesments.dart';
import 'package:vocare/page/perawat/inap/detail/cppt_list.dart';
import 'package:vocare/page/perawat/inap/detail/intervensi_list.dart';
import 'package:vocare/page/perawat/inap/detail/riwayat_laporan.dart'; 
import 'package:vocare/page/perawat/inap/voice.dart';

class PatientDetailPage extends StatelessWidget {
  final Map<String, dynamic> patientData;
  final User user;

  const PatientDetailPage({
    super.key,
    required this.patientData,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final String nama = patientData['nama'] ?? 'Tanpa Nama';
    final String noRm = patientData['no_rekam_medis'] ?? '-';
    final int patientId = patientData['id'] ?? 0;
    final assessmentId = patientData['id_assesment'];

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
        title: Text("Detail Pasien", style: TextStyle(color: Colors.white)),
        backgroundColor: navyColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      // MODIFIED: `body` sekarang dibungkus dengan SingleChildScrollView agar bisa di-scroll
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
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

              // Tombol Navigasi
              ElevatedButton(
                style: buttonStyle,
                onPressed: () {
                  if (assessmentId != null && assessmentId is int) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AssesmentsInap(
                          assessmentId: assessmentId,
                          token: user.token,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ID Assessment tidak valid.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Lihat Assesments'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: buttonStyle,
                onPressed: () {
                  if (patientId != 0) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CpptListPage(
                          patientId: patientId,
                          patientName: nama,
                          user: user,
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Lihat CPPT'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: buttonStyle,
                onPressed: () {
                  if (patientId != 0) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => IntervensiListPage(
                          patientId: patientId,
                          patientName: nama,
                          user: user,
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
                        builder: (context) => DaftarRiwayatPage(
                          user: user,
                          patientId: patientId.toString(),
                          patientName: nama,
                          noRekamMedis: noRm,
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Lihat Laporan'),
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
                    user: user,
                    patientId: nama,
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
            backgroundColor: const Color(
              0xFF093275,
            ), 
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            minimumSize: const Size(
              double.infinity,
              56,
            ), 
          ),
        ),
      ),
    );
  }
}
