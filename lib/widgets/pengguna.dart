import 'package:flutter/material.dart';

class PenggunaWidget extends StatelessWidget {
  const PenggunaWidget({
    super.key,
    required this.pengguna,
    required this.navy,
    required this.cardBlue,
    this.isCompact = false,
  });

  final List<Map<String, String>> pengguna;
  final Color navy;
  final Color cardBlue;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    if (pengguna.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Belum ada pengguna',
            style: TextStyle(color: navy.withOpacity(0.9)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Column(
          children: pengguna.map((r) {
            final nama = (r['perawat']?.trim().isNotEmpty == true)
                ? r['perawat']
                : (r['nama']?.trim().isNotEmpty == true ? r['nama'] : '-');
            final jabatan = (r['jabatan']?.trim().isNotEmpty == true)
                ? r['jabatan']
                : '-';
            final role = (r['role']?.trim().isNotEmpty == true)
                ? r['role']
                : '-';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ReportCard(
                navy: navy,
                cardBlue: cardBlue,
                perawat: nama ?? '-',
                jabatan: jabatan ?? '-',
                role: role ?? '-',
                isCompact: isCompact,
              ),
            );
          }).toList(),
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
    required this.jabatan,
    required this.role,
    this.isCompact = false,
  });

  final Color navy;
  final Color cardBlue;
  final String perawat;
  final String jabatan;
  final String role;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: isCompact ? 48 : 58,
          height: isCompact ? 80 : 90,
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Image.asset(
              'assets/pengguna.png',
              width: isCompact ? 24 : 28,
              height: isCompact ? 24 : 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.person,
                  color: Colors.white,
                  size: isCompact ? 20 : 24,
                );
              },
            ),
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
                    'Nama: $perawat',
                    style: TextStyle(color: navy, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Jabatan: $jabatan',
                    style: TextStyle(
                      color: navy.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Role: $role',
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
