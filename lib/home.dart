import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/page/admin/home.dart';

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

class RoleConfig{
  const RoleConfig({
    required this.pages,
  });

    final List<Widget> Function(User, BuildContext) pages;

  static final Map<Role, RoleConfig> configs = {
    Role.admin: RoleConfig(
      pages: (user, thisContext) => [
        HomeAdminPage(
          user: user,
        ),
      ],
    ),
      'ketua_tim': RoleConfig(
        pages: (user, context) => [
          HomePage(user: user),
        ],
      ),
      'perawat': RoleConfig(
        pages: (user, context) => [
          HomePage(user: user),
        ],
      ),
    };
}