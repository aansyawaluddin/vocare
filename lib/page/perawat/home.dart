import 'package:flutter/material.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/page/login/login.dart';
import 'package:vocare/page/perawat/laporan.dart';
import 'package:vocare/page/perawat/laporan/upload_lab.dart';
import 'package:vocare/page/perawat/inap.dart';

class HomePerawatPage extends StatefulWidget {
  const HomePerawatPage({required this.user, super.key});
  final User user;

  @override
  State<HomePerawatPage> createState() => _HomePerawatPageState();
}

class _HomePerawatPageState extends State<HomePerawatPage> {
  int _selectedTab = 0;

  final List<String> rooms = [
    'Semua Ruangan',
    'UGD',
    'Perawatan',
    'ICU',
    'PICU/NICU',
  ];

  @override
  Widget build(BuildContext context) {
    final navy = const Color(0xFF082B54);
    final lightBackground = const Color(0xFFF3F6FA);

    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isCompact = width < 380;

            return Column(
              children: [
                // Header (fixed)
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
                                  Overlay.of(context).context.findRenderObject()
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
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Segmented control (tabs)
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedTab == 0
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Laporan',
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedTab == 1
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Pasien inap',
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: _selectedTab == 0
                        ? RiwayatLaporan(
                            user: widget.user,
                          ) // RiwayatLaporan harus punya scrolling sendiri (ListView)
                        : PasienInap(
                            user: widget.user,
                          ), // PasienInap/di dalamnya pakai LayoutBuilder; jangan wrap di scroll luar
                  ),
                ),

                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _selectedTab == 0
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child:  SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UploadLab(user: widget.user),
                        ),
                      );
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
                          'Laporan Baru',
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
            
            )
          : null,
    );
  }
}
