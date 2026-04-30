import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/page/admin/riwayat_laporan.dart';

class PasienJalanAdminWidget extends StatefulWidget {
  const PasienJalanAdminWidget({
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
  State<PasienJalanAdminWidget> createState() => _PasienJalanWidgetState();
}

class _PasienJalanWidgetState extends State<PasienJalanAdminWidget> {
  String? _selectedRoom;
  // Menyimpan data pasien secara lokal agar bisa diupdate/dihapus langsung di UI
  late List<Map<String, dynamic>> _localPatients;

  @override
  void initState() {
    super.initState();
    // Salin data dari parent ke state lokal
    _localPatients = List<Map<String, dynamic>>.from(widget.inpatients);
  }

  // Update local data jika parent mengirim data baru
  @override
  void didUpdateWidget(covariant PasienJalanAdminWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inpatients != oldWidget.inpatients) {
      _localPatients = List<Map<String, dynamic>>.from(widget.inpatients);
    }
  }

  bool get _isKetua {
    final r = widget.role.toLowerCase();
    return r.contains('ketua');
  }

  List<Map<String, dynamic>> get _visiblePatients {
    if (_selectedRoom == null || _selectedRoom == 'Semua Ruangan') {
      return _localPatients;
    }

    final selectedLower = _selectedRoom!.toLowerCase();
    return _localPatients
        .where(
          (p) => (p['room'] ?? '').toString().toLowerCase() == selectedLower,
        )
        .toList();
  }

  // <-- FUNGSI PINDAH KE RAWAT INAP (PUT) -->
  Future<bool> _changeStatusToInap(String patientId) async {
    final baseUrl = dotenv.env['API_URL'] ?? '';
    if (baseUrl.isEmpty) {
      debugPrint('API_URL belum di-set di .env');
      return false;
    }

    final url = Uri.parse('$baseUrl/patients/$patientId');
    // Mengubah status menjadi rawat inap
    final body = jsonEncode({'status_rawat': 'rawat_inap'});

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
        if (mounted) {
          setState(() {
            // Hapus dari daftar rawat jalan secara lokal
            _localPatients.removeWhere(
              (p) => (p['id'] ?? '').toString() == patientId,
            );
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

  // <-- FUNGSI HAPUS PASIEN (DELETE) -->
  Future<bool> _deletePatient(String patientId) async {
    final baseUrl = dotenv.env['API_URL'] ?? dotenv.env['API_BASE_URL'] ?? '';
    if (baseUrl.isEmpty) {
      debugPrint('API URL belum di-set di .env');
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/patients/$patientId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.user.token}',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          setState(() {
            // Hapus dari daftar secara lokal
            _localPatients.removeWhere(
              (p) => (p['id'] ?? '').toString() == patientId,
            );
          });
        }
        return true;
      } else {
        debugPrint('Gagal menghapus pasien: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Terjadi kesalahan saat hapus: $e');
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
          'Pasien Rawat Jalan :',
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
                'Tidak ada pasien di ruangan ini',
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
                    onMoveToInpatient: () => _confirmMoveToInpatient(id, nama),
                    onDelete: () => _confirmDelete(id, nama),
                    onTap: () {
                      Navigator.of(context).push(
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
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // --- DIALOG KONFIRMASI PINDAH RAWAT INAP ---
  void _confirmMoveToInpatient(String id, String nama) async {
    final pageContext = context;
    final confirm = await showDialog<bool>(
      context: pageContext,
      builder: (c) => AlertDialog(
        title: const Text('Konfirmasi Pindah'),
        content: Text('Pindahkan pasien "$nama" ke Rawat Inap?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Ya, Pindahkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: pageContext,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    final success = await _changeStatusToInap(id);

    if (!mounted) return;
    Navigator.of(pageContext, rootNavigator: true).pop(); // Tutup loading

    ScaffoldMessenger.of(pageContext).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Pasien berhasil dipindahkan ke Rawat Inap.'
              : 'Gagal memindahkan pasien.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  // --- DIALOG KONFIRMASI HAPUS ---
  void _confirmDelete(String id, String nama) async {
    final pageContext = context;
    final confirm = await showDialog<bool>(
      context: pageContext,
      builder: (c) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus data pasien "$nama"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: pageContext,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    final success = await _deletePatient(id);

    if (!mounted) return;
    Navigator.of(pageContext, rootNavigator: true).pop(); // Tutup loading

    ScaffoldMessenger.of(pageContext).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Data pasien berhasil dihapus.'
              : 'Gagal menghapus data pasien.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
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
    this.onDelete,
    this.onMoveToInpatient,
  });

  final Color navy;
  final Color cardBlue;
  final String noRekamMedis;
  final String nama;
  final String jenisKelamin;
  final String statusRawat;
  final bool isCompact;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onMoveToInpatient;

  @override
  Widget build(BuildContext context) {
    // Sedikit diperbesar agar teks dan ikon memiliki ruang bernapas yang lega
    final cardHeight = isCompact ? 110.0 : 125.0;

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
                child: SizedBox(
                  height: cardHeight,
                  child: Stack(
                    children: [
                      // --- BAGIAN TEKS INFORMASI ---
                      Positioned(
                        left: 14,
                        top: 12,
                        bottom: 12,
                        // Sisakan ruang 50px di kanan agar teks tidak menabrak ikon
                        right: 50,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'No. RM : $noRekamMedis',
                              style: TextStyle(
                                color: navy,
                                fontWeight: FontWeight.w700,
                                fontSize: isCompact ? 12 : 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nama : $nama',
                              style: TextStyle(
                                color: navy.withOpacity(0.95),
                                fontSize: isCompact ? 11 : 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Jenis Kelamin : $jenisKelamin',
                              style: TextStyle(
                                color: navy.withOpacity(0.95),
                                fontSize: isCompact ? 11 : 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Status Rawat : $statusRawat',
                              style: TextStyle(
                                color: navy.withOpacity(0.9),
                                fontSize: isCompact ? 11 : 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // --- TOMBOL PINDAH INAP (POJOK KANAN ATAS) ---
                      if (onMoveToInpatient != null)
                        Positioned(
                          right: 24, // Jarak dari tepi panah
                          top: 8,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onMoveToInpatient,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.hotel,
                                  color: navy,
                                  size: isCompact ? 22 : 24,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // --- TOMBOL HAPUS (POJOK KANAN BAWAH) ---
                      if (onDelete != null)
                        Positioned(
                          right: 24,
                          bottom: 8,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onDelete,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red[700],
                                  size: isCompact ? 22 : 24,
                                ),
                              ),
                            ),
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
