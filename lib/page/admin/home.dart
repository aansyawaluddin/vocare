import 'package:flutter/material.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/page/login/login.dart';
import 'package:vocare/widgets/admin/add_user.dart';
import 'package:vocare/widgets/admin/pengguna.dart';
import 'package:vocare/widgets/admin/file.dart';

class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({required this.user, super.key});
  final User user;

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  int _selectedTab = 0;

  Key _penggunaWidgetKey = UniqueKey();

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

            // HEADER (sama tampilan seperti sebelumya)
            final header = Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              Overlay.of(context)!.context.findRenderObject()
                                  as RenderBox;
                          await showMenu(
                            color: const Color(0xFFD7E2FD),
                            context: context,
                            position: RelativeRect.fromRect(
                              details.globalPosition & const Size(40, 40),
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
                                        builder: (context) => const Login(),
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
                          child: const Icon(Icons.person, color: Colors.white),
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
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(26),
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
                            onTap: () => setState(() => _selectedTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(26),
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
            );

            final content = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: _selectedTab == 0
                  ? Pengguna(
                      key: _penggunaWidgetKey,
                      navy: navy,
                      cardBlue: cardBlue,
                      isCompact: isCompact,
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: const [
                          SizedBox(height: 8),
                          UploadFileWidget(
                            apiPath: '/pdf/process-assesmen',
                            title: 'Upload Assessment',
                          ),
                          SizedBox(height: 12),
                          UploadFileWidget(
                            apiPath: '/pdf/process-permenkes',
                            title: 'Upload Permenkes',
                          ),
                          SizedBox(height: 12),
                          UploadFileWidget(
                            apiPath: '/pdf/process-siki-slki-sdki',
                            title: 'Upload SIKI/SKLI/SDKI',
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
            );

            return Column(
              children: [
                header,
                const SizedBox(height: 18),
                Expanded(child: content),
                const SizedBox(height: 24),
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
                      );

                      // jika dialog successful mengembalikan true, recreate Pengguna
                      if (created == true) {
                        setState(() {
                          _penggunaWidgetKey = UniqueKey();
                        });
                      }
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
