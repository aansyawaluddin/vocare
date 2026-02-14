import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

Future<User> loginRequest(String username, String password) async {
  try {
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: '.env');
    }

    final apiBase = dotenv.env['API_URL'] ?? dotenv.env['API_BASE_URL'];
    if (apiBase == null || apiBase.isEmpty) {
      throw Exception('NO_API');
    }

    final storage = const FlutterSecureStorage();
    final apiUrl = "$apiBase/auth/login";

    final response = await http
        .post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

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
        accessToken = (responseData['access_token'] ?? responseData['token'])
            ?.toString();
        if ((accessToken == null || accessToken.isEmpty) &&
            responseData['data'] is Map) {
          accessToken =
              (responseData['data']['access_token'] ??
                      responseData['data']['token'])
                  ?.toString();
        }
      }

      if (accessToken != null && accessToken.isNotEmpty) {
        await storage.write(key: 'access_token', value: accessToken);
      }

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

      try {
        Map<String, dynamic> userMap;
        if (userJson is Map<String, dynamic>) {
          userMap = userJson;
        } else if (userJson is Map) {
          userMap = Map<String, dynamic>.from(userJson);
        } else {
          userMap = Map<String, dynamic>.from(
            json.decode(json.encode(userJson)),
          );
        }
        await storage.write(key: 'user', value: json.encode(userMap));
      } catch (e) {
        if (kDebugMode) debugPrint('Gagal menyimpan user ke storage: $e');
      }

      if (userJson is Map<String, dynamic>) {
        return User.fromJson(userJson, token: accessToken);
      } else if (userJson is Map) {
        return User.fromJson(
          Map<String, dynamic>.from(userJson),
          token: accessToken,
        );
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

  final Color _primaryColor = const Color(0xFF093275);

  bool _isLoading = false;
  bool _obscureText = true;

  void _showSnack(String msg, {Color bg = Colors.red}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
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
      _showSnack('Username dan password harus diisi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await loginRequest(username, password);

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
        errorMessage = 'Username atau password salah';
      } else {
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }
      _showSnack(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildInputGroup({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? _obscureText : false,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _primaryColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            height: size.height * 0.4,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome to VOCARE",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Sign in to continue",
                        style: TextStyle(fontSize: 14, color: _primaryColor),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 100),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(90),
                        bottomLeft: Radius.circular(90),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 30,
                        right: 30,
                        top: 40,
                        bottom: bottomPadding + 20,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 40),

                          _buildInputGroup(
                            label: "Username",
                            controller: _usernameController,
                            hint: "Masukkan Username",
                          ),

                          const SizedBox(height: 20),

                          _buildInputGroup(
                            label: "Password",
                            controller: _passwordController,
                            hint: "Masukkan Password",
                            isPassword: true,
                          ),

                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      child: Image.asset('assets/icon.png'),
                    ),

                    const SizedBox(width: 10),
                    Container(
                      width: 40,
                      height: 40,
                      child: Image.asset('assets/unhas.png'),
                    ),
                  ],
                ),
                const Text(
                  "Copyright 2026 @ VOCARE Universitas Hasanuddin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  "Penelitian Tesis",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
