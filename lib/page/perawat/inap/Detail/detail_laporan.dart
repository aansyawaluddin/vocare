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

    String _safe(String? value) {
      if (value == null) return '-';
      if (value.trim().isEmpty) return '-';
      return value;
    }

    List<MapEntry<String, String>> _parseLabeledContent(String? content) {
      if (content == null) return [];
      String s = content.trim();
      if (s.isEmpty || s == '{}') return [];

      s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

      final reg = RegExp(r'([A-Za-zÀ-ÿ0-9\s]+?):', multiLine: true);
      final matches = reg.allMatches(s).toList();

      if (matches.isEmpty) {
        var only = s;
        only = only.replaceAll(RegExp(r'^[\(\)\s]+|[\(\)\s]+$'), '').trim();
        if (only.isNotEmpty) return [MapEntry('', only)];
        return [];
      }

      final List<MapEntry<String, String>> result = [];

      if (matches.first.start > 0) {
        var prefix = s.substring(0, matches.first.start).trim();
        prefix = prefix.replaceAll(RegExp(r'^[\(\)\s]+|[\(\)\s]+$'), '').trim();
        if (prefix.isNotEmpty) {
          result.add(MapEntry('', prefix));
        }
      }

      for (var i = 0; i < matches.length; i++) {
        final label = matches[i].group(1)!.trim();
        final startValue = matches[i].end;
        final endValue = (i + 1 < matches.length) ? matches[i + 1].start : s.length;
        var value = s.substring(startValue, endValue).trim();
        value = value.replaceAll(RegExp(r'^[\(\)\s]+|[\(\)\s]+$'), '').replaceAll('"', '').trim();

        if (value.isNotEmpty) {
          result.add(MapEntry(label, value));
        }
      }
      debugPrint('[_parseLabeledContent] original="$s" parsed=$result');

      return result;
    }

    Widget sectionLabeled(
      String title,
      String? rawContent, {
      String fallback = 'Tidak ada data',
    }) {
      final entries = _parseLabeledContent(rawContent);

      const baseTextStyle = TextStyle( fontSize: 15, color: Colors.black);

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
                fontSize: 16,
                color: headingBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text(fallback, style: baseTextStyle)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entries.map((entry) {
                  final label = entry.key;
                  final value = entry.value;
                  if (label.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        value,
                        style: baseTextStyle,
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RichText(
                      text: TextSpan(
                        style: baseTextStyle,
                        children: [
                          const TextSpan(text: '• '),
                          TextSpan(
                            text: '$label: ',
                            style: baseTextStyle.copyWith(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: value,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      );
    }

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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0XFF093275),
                ),
              ),
              const SizedBox(height: 6),

              sectionLabeled('SDKI', _safe(laporan.sdki)),
              sectionLabeled('SIKI', _safe(laporan.siki)),
              sectionLabeled('SLKI', _safe(laporan.slki)),
              sectionLabeled(
                'Tindakan Lanjutan',
                _safe(laporan.tindakanLanjutan),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
