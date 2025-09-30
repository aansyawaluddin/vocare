import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vocare/common/type.dart';
import 'package:vocare/page/perawat/inap/detail_pasien.dart';

class PasienInap extends StatefulWidget {
  final User user;

  const PasienInap({super.key, required this.user});

  @override
  State<PasienInap> createState() => _PasienInapState();
}

class _PasienInapState extends State<PasienInap> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _inpatientsForUI = [];

  final Color navyColor = const Color(0xFF093275);
  final Color cardBlueColor = const Color(0xFFD7E2FD);

  @override
  void initState() {
    super.initState();
    _fetchAndProcessInpatients();
  }

  String _getBaseUrl() {
    return dotenv.env['API_URL'] ?? dotenv.env['API_BASE_URL'] ?? '';
  }

  Map<String, String> _getAuthHeaders() {
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${widget.user.token}',
    };
  }

  Future<void> _fetchAndProcessInpatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    List<Map<String, dynamic>> loadedForUI = [];

    try {
      final baseUrl = _getBaseUrl();
      if (baseUrl.isEmpty) {
        throw Exception('API base URL tidak diset (periksa .env).');
      }

      final patientsResponse = await http.get(
        Uri.parse('$baseUrl/patients/'),
        headers: _getAuthHeaders(),
      );

      if (patientsResponse.statusCode != 200) {
        throw Exception('Gagal memuat data pasien: ${patientsResponse.statusCode}');
      }

      dynamic patientsBody = jsonDecode(patientsResponse.body);

      List<dynamic> patientsData;
      if (patientsBody is Map &&
          patientsBody.containsKey('data') &&
          patientsBody['data'] is List) {
        patientsData = List<dynamic>.from(patientsBody['data']);
      } else if (patientsBody is List) {
        patientsData = List<dynamic>.from(patientsBody);
      } else {
        patientsData = [];
      }

      final List<Map<String, dynamic>> patientMaps = patientsData
          .where((e) => e != null)
          .map((e) => (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .toList();
      
      final inpatients = patientMaps.where((p) {
        final rawStatus = (p['status_rawat'] ?? p['statusRawat'] ?? p['status'] ?? '')
            .toString()
            .toLowerCase();
        return rawStatus.contains('rawat_inap') ||
            rawStatus.contains('rawat inap') ||
            rawStatus.contains('inap');
      }).toList();

      // Menggunakan seluruh data pasien untuk halaman detail
      loadedForUI = inpatients.map((patient) {
        return Map<String, dynamic>.from(patient);
      }).toList();

    } catch (e, st) {
      debugPrint('Error saat fetch pasien: $e\n$st');
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _inpatientsForUI = loadedForUI;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Terjadi kesalahan: $_error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchAndProcessInpatients,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_inpatientsForUI.isEmpty) {
      return const Center(child: Text('Belum ada data pasien rawat inap.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          width: constraints.maxWidth,
          child: PasienInapWidget(
            user: widget.user,
            inpatients: _inpatientsForUI,
            navy: navyColor,
            cardBlue: cardBlueColor,
          ),
        );
      },
    );
  }
}

class PasienInapWidget extends StatelessWidget {
  const PasienInapWidget({
    super.key,
    required this.inpatients,
    required this.navy,
    required this.cardBlue,
    required this.user,
  });

  final List<Map<String, dynamic>> inpatients;
  final Color navy;
  final Color cardBlue;
  final User user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pasien Rawat Inap :',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: inpatients.length,
            itemBuilder: (context, index) {
              final p = inpatients[index];
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
                  // MODIFIED: Navigasi ke PatientDetailPage dengan membawa seluruh data pasien
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PatientDetailPage(
                          user: user,
                          patientData: p,
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
}

class InpatientCard extends StatelessWidget {
  const InpatientCard({
    super.key,
    required this.navy,
    required this.cardBlue,
    required this.noRekamMedis,
    required this.nama,
    this.onTap,
  });

  final Color navy;
  final Color cardBlue;
  final String noRekamMedis;
  final String nama;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 70,
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(Icons.person_outline, color: Colors.white, size: 28),
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
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  height: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No. RM : $noRekamMedis',
                        style: TextStyle(
                          color: navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nama : $nama',
                        style: TextStyle(
                          color: navy.withOpacity(0.95),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
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