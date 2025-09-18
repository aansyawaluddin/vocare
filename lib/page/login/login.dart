import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

Future<User> login(String username, String password) async {
  try {
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: '.env');
    }

    final apiBase = dotenv.env['API_URL'];
    if (apiBase == null || apiBase.isEmpty) {
      throw Exception('NO_API');
    }

    final storage = FlutterSecureStorage();
    final apiUrl = "$apiBase/auth/login";

    final response = await http
        .post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.body == null || response.body.isEmpty) {
      if (response.statusCode == 401) throw Exception('invalid_credentials');
      throw Exception('Response kosong dari server');
    }

    dynamic responseData;
    try {
      responseData = json.decode(response.body);
    } catch (e) {
      throw Exception('Response tidak valid dari server');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      String? accessToken;
      if (responseData is Map) {
        accessToken =
            (responseData['access_token'] ?? responseData['token'])
                ?.toString() ??
            (responseData['data'] is Map
                ? (responseData['data']['access_token'] ??
                          responseData['data']['token'])
                      ?.toString()
                : null);
      }

      if (accessToken != null && accessToken.isNotEmpty) {
        await storage.write(key: 'access_token', value: accessToken);
      }

      // ambil object user dari berbagai struktur
      dynamic userJson;
      if (responseData is Map) {
        userJson =
            responseData['user'] ??
            (responseData['data'] is Map
                ? responseData['data']['user']
                : null) ??
            responseData;
      } else {
        userJson = responseData;
      }

      if (userJson == null) {
        throw Exception('Response tidak berisi informasi user');
      }

      if (userJson is Map<String, dynamic>) {
        return User.fromJson(userJson);
      } else if (userJson is Map) {
        return User.fromJson(Map<String, dynamic>.from(userJson));
      } else {
        throw Exception('Format user tidak valid');
      }
    } else if (response.statusCode == 401) {
      throw Exception('invalid_credentials');
    } else {
      final msg = (responseData is Map && responseData['message'] != null)
          ? responseData['message'].toString()
          : 'Terjadi kesalahan (${response.statusCode})';
      throw Exception(msg);
    }
  } on SocketException {
    throw Exception('Server Bermasalah');
  } on TimeoutException {
    throw Exception('Tidak Ada Jaringan');
  } on FormatException {
    throw Exception('Response tidak valid dari server');
  }
}

class _LoginState extends State<Login> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('username dan password harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await login(username, password);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Home(role: user.role, user: user),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      var errorMessage = e.toString();
      if (errorMessage.contains('invalid_credentials')) {
        errorMessage = 'username atau password salah';
      } else {
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    final double formMaxWidth = math.min(480, screenWidth * 0.7);

    final double fieldHeight = math.max(48, screenHeight * 0.06);
    final double buttonHeight = math.max(48, screenHeight * 0.07);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: fieldHeight,
                    width: double.infinity,
                    child: TextField(
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFA7A7A7),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFA7A7A7),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFA7A7A7),
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFA7A7A7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: fieldHeight,
                    width: double.infinity,
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFA7A7A7),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFA7A7A7),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFA7A7A7),
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFA7A7A7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: buttonHeight,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF093275),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size(double.infinity, buttonHeight),
                        disabledBackgroundColor: const Color(0xFF093275),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
