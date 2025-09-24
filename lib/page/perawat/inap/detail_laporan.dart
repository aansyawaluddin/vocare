import 'package:flutter/material.dart';
import 'package:vocare/common/type.dart';

class DetaiRiwayatPage extends StatelessWidget {
  final Laporan laporan;
  final User user;
  final String? patientName;
  final String? noRekamMedis;
  final String? patientId;

  const DetaiRiwayatPage({
    super.key,
    required this.laporan,
    required this.user,
    this.patientName,
    this.noRekamMedis,
    this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFDFF0FF);
    const cardBorder = Color(0xFFCED7E8);
    const headingBlue = Color(0xFF0F4C81);
    const buttonTambah = Color(0xFF093275);

    String _safe(String? value) {
      if (value == null) return '-';
      if (value.trim().isEmpty) return '-';
      return value;
    }

    /// Membersihkan string dari API dan mengubahnya menjadi List<String>.
    List<String> _formatContentToList(String? content) {
      if (content == null) return [];
      final String trimmed = content.trim();
      if (trimmed.isEmpty || trimmed == '{}') return [];

      String cleaned = trimmed;

      // Jika string dibungkus kurung kurawal, hapus yang paling luar
      if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
        cleaned = cleaned.substring(1, cleaned.length - 1);
      }

      // split berdasarkan koma (sederhana). Jika formatnya lebih kompleks (json), sebaiknya parse JSON.
      List<String> parts = cleaned.split(',');

      List<String> formatted = [];
      for (var part in parts) {
        var item = part.trim();

        // Hapus tanda kutip yang tersisa
        item = item.replaceAll('"', '');

        // Jika item dalam format key:value (mis. key: value), ambil value setelah ':' agar lebih bersih
        if (item.contains(':')) {
          final idx = item.indexOf(':');
          final possibleValue = item.substring(idx + 1).trim();
          if (possibleValue.isNotEmpty) {
            item = possibleValue.replaceAll('"', '');
          }
        }

        if (item.isNotEmpty) {
          formatted.add(item);
        }
      }

      return formatted;
    }

    Widget section(String title, List<String> items, {String fallback = 'Tidak ada data'}) {
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
        margin: const EdgeInsets.only(bottom: 12),
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
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(
                fallback,
                style: const TextStyle(height: 1.5, fontSize: 15),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• ${entry.value}',
                          style: const TextStyle(height: 1.5, fontSize: 15),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      );
    }

    final String sdkiRaw = _safe(laporan.sdki);
    final String sikiRaw = _safe(laporan.siki);
    final String slkiRaw = _safe(laporan.slki);
    final String tindakanRaw = _safe(laporan.tindakanLanjutan);

    final sdkiItems = _formatContentToList(sdkiRaw == '-' ? null : sdkiRaw);
    final sikiItems = _formatContentToList(sikiRaw == '-' ? null : sikiRaw);
    final slkiItems = _formatContentToList(slkiRaw == '-' ? null : slkiRaw);
    final tindakanItems = _formatContentToList(tindakanRaw == '-' ? null : tindakanRaw);

    final String pasienName = patientName ?? '-';
    final String pasienRM = noRekamMedis ?? '-';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: background,
        centerTitle: true,
        title: const Text(
          'Detail Laporan',
          style: TextStyle(
            color: Color(0xFF083B74),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 18, top: 10),
            children: [
              Text(
                '$pasienName (RM: $pasienRM)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0XFF093275),
                ),
              ),
              const SizedBox(height: 6),
              section('SDKI', sdkiItems),
              section('SIKI', sikiItems),
              section('SLKI', slkiItems),
              section('Tindakan Lanjutan', tindakanItems),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
