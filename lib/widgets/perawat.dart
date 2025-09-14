import 'package:flutter/material.dart';

class PerawatWidget extends StatelessWidget {
  const PerawatWidget({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perawat :',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.w700,
            fontSize: isCompact ? 14 : 16,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: reports
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ReportCard(
                    navy: navy,
                    cardBlue: cardBlue,
                    perawat: r['perawat']!,
                    kamar: r['kamar']!,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.navy,
    required this.cardBlue,
    required this.perawat,
    required this.kamar,
  });

  final Color navy;
  final Color cardBlue;
  final String perawat;
  final String kamar;

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
        const SizedBox(width: 0),
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
                    'Nama: $perawat',
                    style: TextStyle(color: navy, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kamar: $kamar',
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
