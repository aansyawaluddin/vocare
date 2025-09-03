import 'package:flutter/material.dart';
import 'package:vocare/page/voice.dart';
import 'package:vocare/widgets/inap.dart';
import 'package:vocare/widgets/laporan.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTab = 0; // 0 = Laporan, 1 = Pasien inap

  final List<String> rooms = [
    'Semua Ruangan',
    'UGD',
    'Perawatan',
    'ICU',
    'PICU/NICU',
  ];

  final List<Map<String, String>> reports = List.generate(
    5,
    (index) => {'name': 'Budi Santoso', 'date': '30 Agustus 2025'},
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

                                Container(
                                  width: isCompact ? 36 : 40,
                                  height: isCompact ? 36 : 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white24,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
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
                            ? LaporanWidget(
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

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 18),
        child: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const VoicePage()),
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
        ),
      ),
    );
  }
}
