import 'package:flutter/material.dart';

class VocareReport2 extends StatelessWidget {
  final String reportText;
  const VocareReport2({super.key, required this.reportText});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFDFF0FF);
    const cardBorder = Color(0xFFCED7E8);
    const headingBlue = Color(0xFF0F4C81);
    const buttonSave = Color(0xFF009563);

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
            Text(
              reportText,
              style: const TextStyle(height: 1.4, fontSize: 16),
            ),
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
          'Vocare Report',
          style: TextStyle(
            color: Color(0xFF083B74),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      // Gunakan ListView agar seluruh isi bisa discroll
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 18, top: 10),
            children: [
              section('Pengkajian'),
              const SizedBox(height: 10),
              section('Diagnosa Keperawatan (SDKI)'),
              const SizedBox(height: 10),
              section('Luaran Keperawatan (SLKI)'),
              const SizedBox(height: 10),
              section('Intervensi Keperawatan (SIKI)'),
              const SizedBox(height: 10),
              section('Catatan Tambahan'),
              const SizedBox(height: 12),
              // Spacer tidak lagi diperlukan di ListView
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
                // aksi save di sini
              },
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonSave,
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
