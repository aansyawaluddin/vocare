import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/page/admin/grafik.dart';
import 'package:vocare/page/admin/inap.dart';
import 'package:vocare/page/admin/jalan.dart';
import 'package:vocare/page/login/login.dart';
import 'package:vocare/widgets/admin/add_user.dart';
import 'package:vocare/page/admin/pengguna.dart';
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

  Widget _buildContent(double width) {
    final navy = const Color(0xFF082B54);
    final cardBlue = const Color(0xFFDCE9FF);
    final isCompact = width < 380;

    switch (_selectedTab) {
      case 0:
        // Menambahkan padding di bawah agar konten tidak tertutup oleh navigasi
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120.0),
          child: Column(
            children: const [
              SizedBox(height: 12),
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
              SizedBox(height: 24),
            ],
          ),
        );

      case 1:
        // PENTING: Anda juga perlu menambahkan padding di bagian bawah daftar
        // di dalam widget `Pengguna` Anda, sama seperti yang dilakukan untuk tab 0.
        // Contoh: Jika `Pengguna` menggunakan ListView, tambahkan `padding: const EdgeInsets.only(bottom: 120)`.
        return Pengguna(
          key: _penggunaWidgetKey,
          navy: navy,
          cardBlue: cardBlue,
          isCompact: isCompact,
        );

      case 2:
        return const PieChartDashboard();

      case 3:
        return PasienInapAdmin(user: widget.user);

      case 4:
        return PasienJalanAdmin(user: widget.user);

      default:
        return const SizedBox.shrink();
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
        bottom: false, 
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            // HEADER
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
                        width: 44,
                        height: 20,
                        decoration: BoxDecoration(
    
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.health_and_safety,
                            color: Colors.white,
                            size: 26,
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
                                fontSize: 14,
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
                                  Future.microtask(() async {
                                    try {
                                      const storage = FlutterSecureStorage();
                                      await storage.delete(key: 'access_token');
                                      await storage.delete(key: 'user');
                                    } catch (e) {}
                                    if (mounted) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const Login()),
                                        (route) => false,
                                      );
                                    }
                                  });
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
                ],
              ),
            );

            final content = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: _buildContent(width),
            );

            return Column(
              children: [
                header,
                const SizedBox(height: 18),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(icon: Icons.upload_file, index: 0),
                  _navItem(icon: Icons.person_outline, index: 1),
                  _navItem(icon: Icons.pie_chart_outline, index: 2),
                  _navItem(icon: Icons.king_bed_outlined, index: 3),
                  _navItem(icon: Icons.directions_walk, index: 4),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _selectedTab == 1
          ? Padding(
              // Padding disesuaikan agar posisi tombol lebih baik
              padding: const EdgeInsets.only(bottom: 96.0),
              child: SizedBox(
                height: 56,
                width: MediaQuery.of(context).size.width - 72,
                child: ElevatedButton(
                  onPressed: () async {
                    final created = await AddUserDialog.show(
                      context: context,
                      isCompact: MediaQuery.of(context).size.width < 380,
                      navy: navy,
                      cardBlue: cardBlue,
                    );

                    if (created == true) {
                      setState(() {
                        _penggunaWidgetKey = UniqueKey();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text('Tambah Pengguna',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _navItem({required IconData icon, required int index}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white70,
            size: isSelected ? 26 : 22,
          ),
        ],
      ),
    );
  }
}
