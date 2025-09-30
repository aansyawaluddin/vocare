import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/page/admin/riwayat_laporan.dart';

class PasienInapAdminWidget extends StatefulWidget {
  const PasienInapAdminWidget({
    super.key,
    required this.inpatients,
    required this.navy,
    required this.cardBlue,
    required this.role,
    required this.user,
    this.isCompact = false,
  });
  final List<Map<String, dynamic>> inpatients;
  final Color navy;
  final Color cardBlue;
  final bool isCompact;
  final String role;
  final User user;

  @override
  State<PasienInapAdminWidget> createState() => _PasienInapAdminWidgetState();
}

class _PasienInapAdminWidgetState extends State<PasienInapAdminWidget> {
  String? _selectedRoom;

  @override
  void initState() {
    super.initState();
  }

  bool get _isKetua {
    final r = widget.role.toLowerCase();
    return r.contains('ketua');
  }

  List<Map<String, dynamic>> get _visiblePatients {
    if (_selectedRoom == null || _selectedRoom == 'Semua Ruangan') {
      return widget.inpatients;
    }

    final selectedLower = _selectedRoom!.toLowerCase();
    return widget.inpatients
        .where((p) =>
            (p['room'] ?? '').toString().toLowerCase() == selectedLower)
        .toList();
  }

  Future<bool> _changeStatusToPulang(String patientId) async {
    final baseUrl = dotenv.env['API_URL'] ?? '';
    if (baseUrl.isEmpty) {
      debugPrint('API_URL belum di-set di .env');
      return false;
    }

    final url = Uri.parse('$baseUrl/patients/$patientId');

    final body = jsonEncode({'status_rawat': 'rawat_jalan'});

    try {
      final resp = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.user.token}',
        },
        body: body,
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // Update state lokal (pastikan widget masih mounted)
        if (mounted) {
          setState(() {
            for (var p in widget.inpatients) {
              final id = (p['id'] ?? '').toString();
              if (id == patientId) {
                p['status_rawat'] = 'rawat_jalan';
              }
            }
          });
        }
        return true;
      } else {
        debugPrint('Gagal update status: ${resp.statusCode} ${resp.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error saat memanggil API: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final navy = widget.navy;
    final cardBlue = widget.cardBlue;
    final isCompact = widget.isCompact;

    final visible = _visiblePatients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Pasien Rawat Inap :',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.w700,
            fontSize: isCompact ? 14 : 16,
          ),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'Tidak ada pasien',
                style: TextStyle(color: navy.withOpacity(0.8)),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final p = visible[index];
                final id = p['id']?.toString() ?? '-';
                final nama = p['nama']?.toString() ?? '-';
                final noRm = p['no_rekam_medis']?.toString() ?? '-';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InpatientCard(
                    key: ValueKey('inpatient_$id'),
                    navy: navy,
                    cardBlue: cardBlue,
                    noRekamMedis: noRm,
                    nama: nama,
                    jenisKelamin: p['jenis_kelamin']?.toString() ?? '-',
                    statusRawat: p['status_rawat']?.toString() ?? '-',
                    isCompact: isCompact,
                    onTap: () => _onPatientTap(context, id, nama, noRm),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _onPatientTap(BuildContext context, String id, String nama, String noRm) {
    final pageContext = context;

    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Pilihan untuk $nama'),
          content: Text('Pilih aksi untuk pasien No. RM $noRm'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); 
                Navigator.of(pageContext).push(
                  MaterialPageRoute(
                    builder: (context) => DaftarRiwayatAdminPage(
                      user: widget.user,
                      patientId: id,
                      patientName: nama,
                      noRekamMedis: noRm,
                    ),
                  ),
                );
              },
              child: const Text('Lihat Riwayat'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final confirm = await showDialog<bool>(
                  context: pageContext,
                  builder: (c) => AlertDialog(
                    title: const Text('Konfirmasi Pulangkan'),
                    content: Text('Apakah Anda yakin ingin memindahkan $nama menjadi pulang?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(c).pop(true),
                        child: const Text('Ya, Pulangkan'),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return; // batal

                showDialog(
                  context: pageContext,
                  barrierDismissible: false,
                  builder: (c) => const Center(child: CircularProgressIndicator()),
                );

                final success = await _changeStatusToPulang(id);

                if (!mounted) return;

                Navigator.of(pageContext, rootNavigator: true).pop();

                ScaffoldMessenger.of(pageContext).showSnackBar( 
                  SnackBar(
                    content: Text(
                      success
                          ? 'Status pasien berhasil diubah menjadi pulang.'
                          : 'Gagal mengubah status pasien.',
                    ),
                  ),
                );
              },
              child: const Text('Tandai Pulang'),
            ),
          ],
        );
      },
    );
  }
}

class InpatientCard extends StatelessWidget {
  const InpatientCard({
    super.key,
    required this.navy,
    required this.cardBlue,
    required this.noRekamMedis,
    required this.nama,
    required this.jenisKelamin,
    required this.statusRawat,
    this.isCompact = false,
    this.onTap,
  });

  final Color navy;
  final Color cardBlue;
  final String noRekamMedis;
  final String nama;
  final String jenisKelamin;
  final String statusRawat;
  final bool isCompact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardHeight = isCompact ? 100.0 : 120.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: cardHeight,
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              Icons.article_outlined,
              color: Colors.white,
              size: isCompact ? 26 : 28,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipPath(
            clipper: RightArrowClipper(),
            child: Material(
              color: cardBlue,
              child: InkWell(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                  height: cardHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No. RM : $noRekamMedis',
                        style: TextStyle(
                          color: navy,
                          fontWeight: FontWeight.w700,
                          fontSize: isCompact ? 12 : 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nama : $nama',
                        style: TextStyle(
                          color: navy.withOpacity(0.95),
                          fontSize: isCompact ? 11 : 12,
                        ),
                      ),
                      Text(
                        'Jenis Kelamin : $jenisKelamin',
                        style: TextStyle(
                          color: navy.withOpacity(0.95),
                          fontSize: isCompact ? 11 : 12,
                        ),
                      ),
                      Text(
                        'Status Rawat : $statusRawat',
                        style: TextStyle(
                          color: navy.withOpacity(0.9),
                          fontSize: isCompact ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RightArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - 18, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - 18, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}