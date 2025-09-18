import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/page/login/login.dart';
import 'package:vocare/widgets/admin/add_user.dart';
import 'package:vocare/widgets/admin/pengguna.dart';
import 'package:vocare/widgets/admin/assessment.dart';

class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({required this.user, super.key});
  final User user;

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  List<User> users = [];
  bool isLoading = true;
  String? error;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // api fetchUsers
  Future<void> fetchUsers() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoading = true;
        error = null;
      });

      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');

      if (token == null) {
        throw Exception('No access token found');
      }

      final response = await http.get(
        Uri.parse("${dotenv.env['API_URL']}/user/"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = json.decode(response.body);
        final parsed = data
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();

        if (!mounted) return;
        setState(() {
          users = parsed;
          isLoading = false;
        });
      } else {
        final msg =
            'Failed to fetch users: ${response.statusCode} - ${response.body}';
        if (!mounted) return;
        setState(() {
          error = msg;
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // api createUser
  Future<void> createUser({
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
        if (js is Map && js['message'] != null) {
          serverMsg = js['message'].toString();
        }
      } catch (_) {}
      throw Exception(
        'Gagal menambahkan pengguna: ${resp.statusCode} - $serverMsg',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final navy = const Color(0xFF082B54);
    final lightBackground = const Color(0xFFF3F6FA);
    final cardBlue = const Color(0xFFDCE9FF);

    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isCompact = width < 380;

            return Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: navy,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(22),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: isCompact ? 40 : 44,
                                  height: isCompact ? 40 : 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.health_and_safety,
                                      color: Colors.white,
                                      size: isCompact ? 22 : 26,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'vocare',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Welcome ${widget.user.username}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.95),
                                          fontSize: isCompact ? 13 : 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTapDown: (TapDownDetails details) async {
                                    final RenderBox overlay =
                                        Overlay.of(
                                              context,
                                            )!.context.findRenderObject()
                                            as RenderBox;
                                    await showMenu(
                                      color: const Color(0xFFD7E2FD),
                                      context: context,
                                      position: RelativeRect.fromRect(
                                        details.globalPosition &
                                            const Size(40, 40),
                                        Offset.zero & overlay.size,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      items: [
                                        PopupMenuItem(
                                          child: const Text(
                                            "Logout",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF093275),
                                            ),
                                          ),
                                          onTap: () {
                                            Future.delayed(
                                              Duration.zero,
                                              () => Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const Login(),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white24,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedTab = 0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _selectedTab == 0
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            26,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Pengguna',
                                            style: TextStyle(
                                              color: _selectedTab == 0
                                                  ? navy
                                                  : Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedTab = 1),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _selectedTab == 1
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            26,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Assessment',
                                            style: TextStyle(
                                              color: _selectedTab == 1
                                                  ? navy
                                                  : Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: _selectedTab == 0
                            ? (isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : (error != null
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 24,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Error: $error',
                                                style: TextStyle(color: navy),
                                              ),
                                            ),
                                          )
                                        : PenggunaWidget(
                                            pengguna: users,
                                            navy: navy,
                                            cardBlue: cardBlue,
                                            isCompact: isCompact,
                                          )))
                            : AssessmentWidget(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                if (isLoading) const Center(child: CircularProgressIndicator()),
              ],
            );
          },
        ),
      ),

      bottomNavigationBar: _selectedTab == 0
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      final created = await AddUserDialog.show(
                        context: context,
                        isCompact: MediaQuery.of(context).size.width < 380,
                        navy: navy,
                        cardBlue: cardBlue,
                        onCreate:
                            ({
                              required String username,
                              required String email,
                              required String password,
                              required String role,
                            }) async {
                              await createUser(
                                username: username,
                                email: email,
                                password: password,
                                role: role,
                              );
                            },
                      );

                      if (created == true) await fetchUsers();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Tambah Pengguna',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
