import 'package:flutter/material.dart';
import 'package:vocare/widgets/border.dart';
import 'package:vocare/page/login/login.dart';
import 'package:vocare/widgets/assessment.dart';
import 'package:vocare/widgets/pengguna.dart';

class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({super.key});

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  int _selectedTab = 0;

  final List<Map<String, String>> pengguna = List.generate(
    5,
    (index) => {
      'nama': 'Budi Santoso $index',
      'jabatan': 'Perawat',
      'role': 'Admin',
    },
  );

  void _showAddPenggunaModal({
    required BuildContext context,
    required bool isCompact,
    required Color navy,
    required Color cardBlue,
  }) {
    final _formKey = GlobalKey<FormState>();
    final namaCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final jabatanCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String? selectedRole;

    showDialog(
      context: context,
      builder: (ctx) {
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
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Heading
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tambah Pengguna',
                          style: TextStyle(
                            fontSize: isCompact ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: navy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Nama (pakai widget reusable)
                      AppTextFormField(
                        controller: namaCtrl,
                        label: 'Nama',
                        hint: 'Masukkan Nama Lengkap',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama wajib'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Email
                      AppTextFormField(
                        controller: emailCtrl,
                        label: 'Email',
                        hint: 'Masukkan Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Email wajib';
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(v.trim()))
                            return 'Email tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Jabatan
                      AppTextFormField(
                        controller: jabatanCtrl,
                        label: 'Jabatan',
                        hint: 'Masukkan Jabatan',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Jabatan wajib'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Role (dropdown) - gunakan decoration yang sama
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        items: ['Admin', 'Perawat', 'Dokter', 'User']
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                        decoration: appInputDecoration(label: 'Role', hint: ''),
                        onChanged: (v) => selectedRole = v,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Pilih role' : null,
                      ),
                      const SizedBox(height: 12),

                      // Password
                      AppTextFormField(
                        controller: passwordCtrl,
                        label: 'Password',
                        hint: 'Masukkan Password',
                        obscureText: true,
                        validator: (v) => (v == null || v.trim().length < 6)
                            ? 'Password minimal 6 karakter'
                            : null,
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              // tambahkan pengguna ke list
                              setState(() {
                                pengguna.add({
                                  'nama': namaCtrl.text.trim(),
                                  'jabatan': jabatanCtrl.text.trim(),
                                  'role': selectedRole ?? 'User',
                                });
                              });
                              Navigator.of(ctx).pop();
                            }
                          },
                          child: const Text(
                            'Submit',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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
      },
    );
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
                                        'Welcome Admin',
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

                      // Content: show based on active tab
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: _selectedTab == 0
                            ? PenggunaWidget(
                                pengguna: pengguna,
                                navy: navy,
                                cardBlue: cardBlue,
                                isCompact: isCompact,
                              )
                            : AssessmentWidget(),
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
      bottomNavigationBar: _selectedTab == 0
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      _showAddPenggunaModal(
                        context: context,
                        isCompact: MediaQuery.of(context).size.width < 380,
                        navy: navy,
                        cardBlue: cardBlue,
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
