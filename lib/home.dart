import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/page/admin/home.dart';
import 'package:vocare/page/ketua_tim/home.dart';
import 'package:vocare/page/perawat/home.dart';

void showGlobalSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: const Color(0xFF4282C2),
      duration: const Duration(seconds: 3),
    ),
  );
}

class RoleConfig {
  const RoleConfig({required this.pages});

  final List<Widget> Function(User, BuildContext) pages;

  static final Map<Role, RoleConfig> configs = {
    Role.admin: RoleConfig(
      pages: (user, thisContext) => [HomeAdminPage(user: user)],
    ),
    Role.ketuaTim: RoleConfig(
      pages: (user, thisContext) => [HomeKetuaTimPage(user: user)],
    ),
    Role.perawat: RoleConfig(
      pages: (user, thisContext) => [HomePerawatPage(user: user),],

    ),
  };
}

class Home extends StatelessWidget {
  const Home({required this.role, required this.user, super.key});

  final Role role;
  final User user;

  RoleConfig get roleConfig {
    return RoleConfig.configs[role] ??
        (throw Exception('RoleConfig tidak ditemukan untuk role: $role'));
  }

  @override
  Widget build(BuildContext context) {
    print('Home received role: $role');
    final pages = roleConfig.pages(user, context);

    if (pages.isEmpty) {
      final roleName = role.toString().split('.').last;
      return Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Center(child: Text('Belum ada halaman untuk role: $roleName')),
      );
    }

    if (pages.length == 1) {
      return Scaffold(body: pages.first);
    }
    return Scaffold(body: PageView(children: pages));
  }
}
