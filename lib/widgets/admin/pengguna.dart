import 'package:flutter/material.dart';
import 'package:vocare/common/type.dart';

class PenggunaWidget extends StatelessWidget {
  const PenggunaWidget({
    super.key,
    required this.pengguna,
    required this.navy,
    required this.cardBlue,
    this.isCompact = false,
  });

  final List<User> pengguna;
  final Color navy;
  final Color cardBlue;
  final bool isCompact;

  String _roleLabel(Role role) {
    switch (role) {
      case Role.admin:
        return 'admin';
      case Role.ketuaTim:
        return 'ketuaTim';
      case Role.perawat:
        return 'perawat';
    }
  }

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
          children: pengguna.map((u) {
            final nama = (u.username.trim().isNotEmpty) ? u.username : '-';
            final role = _roleLabel(u.role);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ReportCard(
                navy: navy,
                cardBlue: cardBlue,
                perawat: nama,
                role: role,
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
    required this.role,
    this.isCompact = false,
  });

  final Color navy;
  final Color cardBlue;
  final String perawat;
  final String role;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: isCompact ? 48 : 58,
          height: isCompact ? 80 : 65,
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
