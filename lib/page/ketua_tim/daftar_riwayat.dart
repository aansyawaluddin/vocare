import 'package:flutter/material.dart';
import 'package:vocare/page/ketua_tim/detail_riwayat.dart';

class DaftarRiwayatPage extends StatelessWidget {
  final String reportText;
  const DaftarRiwayatPage({super.key, required this.reportText});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFDFF0FF);
    const cardBorder = Color(0xFFCED7E8);
    const headingBlue = Color(0xFF0F4C81);
    const buttonTambah = Color(0xFF093275);

    // ubah fungsi section supaya menerima onTap
    Widget section(BuildContext context, String title, VoidCallback onTap) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
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
                Text(reportText,
                    style: const TextStyle(height: 1.4, fontSize: 16)),
                const SizedBox(height: 12),
              ],
            ),
          ),
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
              const Text(
                'Tn. Aan (RM: 1234)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0XFF093275),
                ),
              ),
              const SizedBox(height: 5),
              section(
                context,
                '29/08/2025 14:30',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetaiRiwayatPage(
                        reportText: reportText,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              section(
                context,
                '28/08/2025 10:00',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetaiRiwayatPage(
                        reportText: reportText,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              section(
                context,
                '27/08/2025 08:15',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetaiRiwayatPage(
                        reportText: reportText,
                      ),
                    ),
                  );
                },
              ),
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
                // Navigator.of(context).push(
                //   MaterialPageRoute(
                //     builder: (context) => const VoicePageLaporan(),
                //   ),
                // );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Form Kepulangan',
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
