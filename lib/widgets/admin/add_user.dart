import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({
    super.key,
    required this.isCompact,
    required this.navy,
    required this.cardBlue,
  });

  final bool isCompact;
  final Color navy;
  final Color cardBlue;

  static Future<bool?> show({
    required BuildContext context,
    required bool isCompact,
    required Color navy,
    required Color cardBlue,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddUserDialog(
        isCompact: isCompact,
        navy: navy,
        cardBlue: cardBlue,
      ),
    );
  }

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final namaCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  String selectedRole = 'Perawat';
  bool submitting = false;
  String? errorMsg;

  final Map<String, String> roleMap = {
    'Admin': 'admin',
    'Perawat': 'user', 
    'Ketua Tim': 'ketim',
  };

  Future<void> _createUserOnServer({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (token == null) {
      throw Exception('No access token found. Silakan login ulang.');
    }

    final body = json.encode({
      'username': username,
      'email': email,
      'password': password,
      'role': role,
    });

    final resp = await http.post(
      Uri.parse("${dotenv.env['API_URL']}/auth/register"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return;
    } else {
      String serverMsg = resp.body;
      try {
        final js = json.decode(resp.body);
        if (js is Map && js['message'] != null) serverMsg = js['message'].toString();
      } catch (_) {}
      throw Exception('Gagal menambahkan pengguna: ${resp.statusCode} - $serverMsg');
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final rolePayload = roleMap[selectedRole] ?? 'user';

    setState(() {
      submitting = true;
      errorMsg = null;
    });

    try {
      await _createUserOnServer(
        username: namaCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
        role: rolePayload,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Tambah Pengguna',
                        style: TextStyle(
                          fontSize: widget.isCompact ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: widget.navy,
                        )),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: namaCtrl,
                    decoration: const InputDecoration(labelText: 'Username', hintText: 'Masukkan Username'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Username wajib' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', hintText: 'Masukkan Email'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email wajib';
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(v.trim())) return 'Email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: roleMap.keys.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    decoration: const InputDecoration(labelText: 'Role'),
                    onChanged: (v) {
                      if (v != null) setState(() => selectedRole = v);
                    },
                    validator: (v) => (v == null || v.isEmpty) ? 'Pilih role' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(labelText: 'Password', hintText: 'Masukkan Password'),
                    obscureText: true,
                    validator: (v) => (v == null || v.trim().length < 6) ? 'Password minimal 6 karakter' : null,
                  ),
                  const SizedBox(height: 18),
                  if (errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.navy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: submitting ? null : _submit,
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                            )
                          : const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: submitting ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
