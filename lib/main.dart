import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/page/login/login.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vocare/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('id_ID', null);

  final storage = const FlutterSecureStorage();
  User? initialUser;

  final token = await storage.read(key: 'access_token');
  final userJsonStr = await storage.read(key: 'user');

  if (token != null && token.isNotEmpty && userJsonStr != null && userJsonStr.isNotEmpty) {
    try {
      final Map<String, dynamic> userMap = Map<String, dynamic>.from(json.decode(userJsonStr));
      initialUser = User.fromJson(userMap, token: token);
    } catch (e) {
      initialUser = null;
    }
  }

  runApp(MyApp(initialUser: initialUser));
}

class MyApp extends StatelessWidget {
  final User? initialUser;
  const MyApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: initialUser != null
          ? Home(role: initialUser!.role, user: initialUser!)
          : const Login(),
    );
  }
}
