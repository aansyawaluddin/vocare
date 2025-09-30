import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:vocare/common/type.dart';
import 'package:vocare/widgets/admin/detail_user.dart';

class Pengguna extends StatefulWidget {
  const Pengguna({
    super.key,
    required this.navy,
    required this.cardBlue,
    this.isCompact = false,
  });

  final Color navy;
  final Color cardBlue;
  final bool isCompact;

  @override
  State<Pengguna> createState() => _PenggunaState();
}

class _PenggunaState extends State<Pengguna> {
  late Future<List<User>> _futureUsers;

  @override
  void initState() {
    super.initState();
    _futureUsers = fetchUsers();
  }

  Future<List<User>> fetchUsers() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (token == null) throw Exception('No access token found.');

    final resp = await http.get(
      Uri.parse("${dotenv.env['API_URL']}/users/"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final List<dynamic> data = json.decode(resp.body);
      return data.map((j) => User.fromJson(j as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Gagal mengambil pengguna');
    }
  }

  String _roleLabel(Role role) {
    switch (role) {
      case Role.admin:
        return 'Admin';
      case Role.editor:
        return 'Ketua Tim';
      case Role.perawat:
        return 'Perawat';
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _futureUsers = fetchUsers();
    });
    await _futureUsers;
  }

  Future<void> _openDetail(User u) async {
    final changed = await UserDetailDialog.show(
      context: context,
      user: u,
      isCompact: widget.isCompact,
      navy: widget.navy,
      cardBlue: widget.cardBlue,
    );

    if (changed == true) {
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Perubahan tersimpan.'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: _futureUsers,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Error: ${snap.error}', style: TextStyle(color: widget.navy))),
          );
        } else {
          final pengguna = snap.data ?? [];
          if (pengguna.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Belum ada pengguna', style: TextStyle(color: widget.navy.withOpacity(0.9)))),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24, top: 0),
              itemCount: pengguna.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final u = pengguna[i];
                final nama = (u.username.trim().isNotEmpty) ? u.username : '-';
                final role = _roleLabel(u.role);

                return InkWell(
                  onTap: () => _openDetail(u),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    child: ReportCard(
                      navy: widget.navy,
                      cardBlue: widget.cardBlue,
                      perawat: nama,
                      role: role,
                      isCompact: widget.isCompact,
                    ),
                  ),
                );
              },
            ),
          );
        }
      },
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
          decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(10)),
          child: Center(
            child: Image.asset(
              'assets/pengguna.png',
              width: isCompact ? 24 : 28,
              height: isCompact ? 24 : 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.person, color: Colors.white, size: isCompact ? 20 : 24);
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
                  Text('Nama: $perawat', style: TextStyle(color: navy, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Role: $role', style: TextStyle(color: navy.withOpacity(0.8), fontSize: 12)),
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
