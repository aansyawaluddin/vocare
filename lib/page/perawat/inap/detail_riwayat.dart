import 'package:flutter/material.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/page/perawat/inap/voice.dart';

class DetaiRiwayatPage extends StatelessWidget {
  final String reportText;
  final User user;
  const DetaiRiwayatPage({super.key, required this.reportText, required this.user});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFDFF0FF);
    const cardBorder = Color(0xFFCED7E8);
    const headingBlue = Color(0xFF0F4C81);
    const buttonTambah = Color(0xFF093275);

    Widget section(String title) {
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
            Text(reportText, style: const TextStyle(height: 1.4, fontSize: 16)),
            const SizedBox(height: 12),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: background,
        centerTitle: true,
        title: const Text(
          'Daftar Laporan',
          style: TextStyle(
            color: Color(0xFF083B74),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 18, top: 10),
            children: [
              Text(
                'Tn. Andi (RM: 1234)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0XFF093275),
                ),
              ),
              const SizedBox(height:5 ),
              section('29/08/2025 14:30'),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => VoicePageLaporanInap(user: user),
                  ),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Laporan Baru',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonTambah,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
