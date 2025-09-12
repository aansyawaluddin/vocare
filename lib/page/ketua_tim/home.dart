import 'package:flutter/material.dart';
import 'package:vocare/login.dart';
import 'package:vocare/widgets/inap.dart';
import 'package:vocare/widgets/pasien.dart';

class HomeKetuaTimPage extends StatefulWidget {
  const HomeKetuaTimPage({super.key});

  @override
  State<HomeKetuaTimPage> createState() => _HomeKetuaTimPageState();
}

class _HomeKetuaTimPageState extends State<HomeKetuaTimPage> {
  int _selectedTab = 0;

  final List<String> rooms = [
    'Semua Ruangan',
    'UGD',
    'Perawatan',
    'ICU',
    'PICU/NICU',
  ];

  final List<Map<String, String>> reports = List.generate(
    5,
    (index) => {'perawat': 'Budi Santoso', 'kamar': 'Ruangan IGD'},
  );

  final List<Map<String, String>> inpatients = List.generate(6, (index) {
    return {
      'name': 'Nama Pasien ${index + 1}',
      'room': index % 3 == 0 ? 'UGD' : (index % 3 == 1 ? 'Perawatan' : 'ICU'),
      'condition': 'Stabil',
      'lastAction': '29/08/2025 14:30',
    };
  });

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
                      // Header
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
                                        'Welcome Aan',
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
                                            ).context.findRenderObject()
                                            as RenderBox;
                                    await showMenu(
                                      color: Color(0xFFD7E2FD),
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
                                            'Perawat',
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

                      // Content: show based on active tab
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: _selectedTab == 0
                            ? PasienWidget(
                                reports: reports,
                                navy: navy,
                                cardBlue: cardBlue,
                                isCompact: isCompact,
                              )
                            : PasienInapWidget(
                                rooms: rooms,
                                inpatients: inpatients,
                                navy: navy,
                                cardBlue: cardBlue,
                                isCompact: isCompact,
                              ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
