import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:vocare/common/type.dart';

class UserDetailDialog extends StatefulWidget {
  const UserDetailDialog({
    super.key,
    required this.user,
    required this.isCompact,
    required this.navy,
    required this.cardBlue,
  });

  final User user;
  final bool isCompact;
  final Color navy;
  final Color cardBlue;

  static Future<bool?> show({
    required BuildContext context,
    required User user,
    required bool isCompact,
    required Color navy,
    required Color cardBlue,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserDetailDialog(
        user: user,
        isCompact: isCompact,
        navy: navy,
        cardBlue: cardBlue,
      ),
    );
  }

  @override
  State<UserDetailDialog> createState() => _UserDetailDialogState();
}

class _UserDetailDialogState extends State<UserDetailDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  bool _submitting = false;
  String? _errorMsg;

  /// Label yang tampil ke user -> nilai yang dikirim ke server
  final Map<String, String> displayToPayload = {
    'Admin': 'admin',
    'Ketua Tim': 'editor',
    'Perawat': 'user',
  };

  late String _selectedRoleDisplay;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.user.username);
    _emailCtrl = TextEditingController(text: widget.user.email);

    _selectedRoleDisplay = _roleDisplayFromEnum(widget.user.role);

    if (!displayToPayload.keys.contains(_selectedRoleDisplay)) {
      _selectedRoleDisplay = displayToPayload.keys.first;
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  String _roleDisplayFromEnum(Role role) {
    switch (role) {
      case Role.admin:
        return 'Admin';
      case Role.editor:
        return 'Ketua Tim';
      case Role.perawat:
        return 'Perawat';
    }
  }


  Future<String> _getToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (token == null) throw Exception('Token tidak ditemukan. Silakan login kembali.');
    return token;
  }

  String _safeParseServerMessage(http.Response r) {
    final contentType = r.headers['content-type'] ?? '';
    if (contentType.contains('application/json')) {
      try {
        final js = json.decode(r.body);
        if (js is Map) {
          if (js['message'] != null) return js['message'].toString();
          if (js['error'] != null) return js['error'].toString();
          if (js['detail'] != null) return js['detail'].toString();
        }
      } catch (_) {
      }
    }

    if (r.statusCode >= 500 && r.statusCode < 600) {
      return 'Terjadi kesalahan server. Silakan coba beberapa saat lagi.';
    }
    if (r.statusCode == 429) {
      return 'Terlalu banyak permintaan. Silakan coba lagi sebentar.';
    }
    if (r.statusCode == 400) return 'Permintaan tidak valid. Periksa input Anda.';
    if (r.statusCode == 401) return 'Anda tidak terautentikasi. Silakan login kembali.';
    if (r.statusCode == 403) return 'Akses ditolak.';
    if (r.statusCode == 404) return 'Sumber tidak ditemukan.';
    return 'Terjadi kesalahan (kode ${r.statusCode}). Silakan coba lagi.';
  }

  String _friendlyFromException(Object e) {
    final s = e.toString();

    if (s.contains('SocketException') || s.toLowerCase().contains('failed host lookup') || s.toLowerCase().contains('connection refused')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }

    if (s.toLowerCase().contains('timeout')) {
      return 'Waktu tunggu habis saat menghubungi server. Silakan coba lagi.';
    }

    final cleaned = s.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();

    if (RegExp(r'\b5\d{2}\b').hasMatch(cleaned)) {
      return 'Terjadi kesalahan server. Silakan coba beberapa saat lagi.';
    }

    return cleaned.isNotEmpty ? cleaned : 'Terjadi kesalahan yang tidak diketahui.';
  }

  Future<void> _saveChanges() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newPassword = _passwordCtrl.text.trim();
    if (newPassword.isNotEmpty && newPassword != _confirmPasswordCtrl.text.trim()) {
      setState(() => _errorMsg = 'Password konfirmasi tidak cocok');
      return;
    }

    final rolePayloadRaw = displayToPayload[_selectedRoleDisplay] ?? 'user';
    final rolePayload = rolePayloadRaw.trim().toLowerCase();

    const allowedRoles = ['admin', 'user', 'editor', 'ketim'];
    if (!allowedRoles.contains(rolePayload)) {
      setState(() => _errorMsg = 'Role tidak valid: $rolePayload');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMsg = null;
    });

    try {
      final token = await _getToken();
      final payload = <String, dynamic>{
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': rolePayload,
      };

      if (newPassword.isNotEmpty) payload['password'] = newPassword;

      // debug print hanya jika dalam debug mode
      if (kDebugMode) {
        // ignore: avoid_print
        print('DEBUG: update user payload = $payload');
      }

      final url = Uri.parse("${dotenv.env['API_URL']}/users/${widget.user.id}");

      final resp = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final serverMsg = _safeParseServerMessage(resp);
        throw Exception(serverMsg);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = _friendlyFromException(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus pengguna ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _submitting = true;
      _errorMsg = null;
    });

    try {
      final token = await _getToken();
      final url = Uri.parse("${dotenv.env['API_URL']}/users/${widget.user.id}");
      final resp = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (mounted) Navigator.of(context).pop(true); // sukses => true
      } else {
        final serverMsg = _safeParseServerMessage(resp);
        throw Exception(serverMsg);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMsg = _friendlyFromException(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12)],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // header
                  Row(
                    children: [
                      Expanded(
                        child: Text('Detail Pengguna',
                            style: TextStyle(fontSize: widget.isCompact ? 16 : 18, fontWeight: FontWeight.w700, color: widget.navy)),
                      ),
                      IconButton(onPressed: _submitting ? null : () => Navigator.of(context).pop(false), icon: const Icon(Icons.close)),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ID
                  Align(alignment: Alignment.centerLeft, child: Text('ID: ${widget.user.id}', style: TextStyle(fontSize: 12, color: widget.navy.withOpacity(0.7)))),
                  const SizedBox(height: 8),

                  // username
                  TextFormField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(labelText: 'Username', hintText: 'Masukkan username'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Username wajib' : null,
                  ),
                  const SizedBox(height: 12),

                  // email
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email', hintText: 'Masukkan email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email wajib';
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(v.trim())) return 'Email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // role dropdown (gunakan displayToPayload.keys)
                  DropdownButtonFormField<String>(
                    value: _selectedRoleDisplay,
                    items: displayToPayload.keys
                        .map((d) => DropdownMenuItem<String>(value: d, child: Text(d)))
                        .toList(),
                    decoration: const InputDecoration(labelText: 'Role'),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedRoleDisplay = v);
                    },
                    validator: (v) => (v == null || v.isEmpty) ? 'Pilih role' : null,
                  ),
                  const SizedBox(height: 12),

                  // password (optional)
                  Align(alignment: Alignment.centerLeft, child: Text('Ganti Password (opsional)', style: TextStyle(color: widget.navy.withOpacity(0.85), fontWeight: FontWeight.w600))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password baru', hintText: 'Biarkan kosong bila tidak ingin mengganti'),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && v.trim().length < 6) return 'Password minimal 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Konfirmasi password'),
                  ),

                  const SizedBox(height: 14),

                  if (_errorMsg != null)
                    Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13))),

                  // actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _submitting ? null : _deleteUser,
                          child: _submitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: widget.navy, padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: _submitting ? null : _saveChanges,
                          child: _submitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                              : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
