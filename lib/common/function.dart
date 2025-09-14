import 'package:vocare/common/type.dart';

String roleToString(Role role) {
  switch (role) {
    case Role.admin:
      return 'admin';
    case Role.ketuaTim:
      return 'ketua_tim';
    case Role.perawat:
      return 'perawat';
  }
}