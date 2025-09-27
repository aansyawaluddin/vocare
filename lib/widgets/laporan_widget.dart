import 'package:flutter/material.dart';

class LaporanWidget extends StatelessWidget {
  const LaporanWidget({
    super.key,
    required this.reports,
    required this.navy,
    required this.cardBlue,
    this.isCompact = false,
  });

  final List<Map<String, String>> reports;
  final Color navy;
  final Color cardBlue;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.maxHeight.isFinite;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Laporan :',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.w700,
                fontSize: isCompact ? 14 : 16,
              ),
            ),
            const SizedBox(height: 12),
            if (hasBoundedHeight)
              Expanded(
                child: ListView.separated(
                  itemCount: reports.length,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final r = reports[idx];
                    return ReportCard(
                      navy: navy,
                      cardBlue: cardBlue,
                      name: r['name'] ?? '-',
                      date: r['date'] ?? '-',
                    );
                  },
                ),
              )
            else
              // Parent tidak memberi batas -> ListView jangan coba scroll sendiri
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reports.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final r = reports[idx];
                  return ReportCard(
                    navy: navy,
                    cardBlue: cardBlue,
                    name: r['name'] ?? '-',
                    date: r['date'] ?? '-',
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.navy,
    required this.cardBlue,
    required this.name,
    required this.date,
  });

  final Color navy;
  final Color cardBlue;
  final String name;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(Icons.article_outlined, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipPath(
            clipper: RightArrowClipper(),
            child: Container(
              color: cardBlue,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pasien: $name',
                    style: TextStyle(color: navy, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tanggal: $date',
                    style: TextStyle(
                      color: navy.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RightArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - 18, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - 18, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
