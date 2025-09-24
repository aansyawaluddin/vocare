import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vocare/common/type.dart';
import 'package:vocare/widgets/inap_widget.dart';

class PasienInap extends StatefulWidget {
  final User user;

  const PasienInap({super.key, required this.user});

  @override
  State<PasienInap> createState() => _PasienInapState();
}

class _PasienInapState extends State<PasienInap> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, String>> _inpatientsForUI = [];
  List<String> _rooms = ['Semua Ruangan'];

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

    try {
      final patientsResponse = await http.get(
        Uri.parse('${_getBaseUrl()}/patients/'),
        headers: _getAuthHeaders(),
      );
      debugPrint('patientsResponse.statusCode: ${patientsResponse.statusCode}');
      debugPrint('patientsResponse.body: ${patientsResponse.body}');

      if (patientsResponse.statusCode != 200) {
        throw Exception(
          'Gagal memuat data pasien: ${patientsResponse.statusCode}',
        );
      }

      dynamic patientsBody = jsonDecode(patientsResponse.body);
      List<dynamic> patientsData =
          (patientsBody is Map && patientsBody.containsKey('data'))
          ? patientsBody['data']
          : patientsBody;

      debugPrint('patientsData length: ${patientsData.length}');
      if (patientsData.isNotEmpty)
        debugPrint('patientsData[0]: ${patientsData[0].toString()}');

      final List<Map<String, dynamic>> patientMaps = patientsData
          .where((e) => e != null)
          .map(
            (e) =>
                (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{},
          )
          .toList();

      if (patientMaps.isNotEmpty) {
        debugPrint('patientMaps[0] keys: ${patientMaps[0].keys.toList()}');
        debugPrint('patientMaps[0] raw: ${patientMaps[0].toString()}');
      }

      final inpatients = patientMaps.where((p) {
        final status =
            (p['status_rawat'] ?? p['statusRawat'] ?? p['status'] ?? '')
                .toString()
                .toLowerCase();
        return status.contains('rawat_inap') ||
            status.contains('rawat inap') ||
            status.contains('inap');
      }).toList();

      String extractId(Map<String, dynamic> patient) {
        final candidates = [
          patient['id'],
          patient['patient_id'],
          patient['uuid'],
          patient['_id'],
          patient['no_rekam_medis'],
        ];
        if (patient.containsKey('attributes') && patient['attributes'] is Map) {
          final attr = Map<String, dynamic>.from(patient['attributes']);
          candidates.addAll([
            attr['id'],
            attr['patient_id'],
            attr['uuid'],
            attr['_id'],
          ]);
        }
        for (var c in candidates) if (c != null) return c.toString();
        return '-';
      }

      _inpatientsForUI = inpatients.map((patient) {
        return {
          'id': extractId(patient),
          'no_rekam_medis':
              (patient['no_rekam_medis'] ??
                      patient['noRekamMedis'] ??
                      patient['rm'] ??
                      patient['rekam_medis'])
                  ?.toString() ??
              '-',
          'nama': (patient['nama'] ?? patient['name'])?.toString() ?? '-',
          'jenis_kelamin':
              (patient['jenis_kelamin'] ??
                      patient['jenisKelamin'] ??
                      patient['gender'])
                  ?.toString() ??
              '-',
          'status_rawat':
              (patient['status_rawat'] ??
                      patient['statusRawat'] ??
                      patient['status'])
                  ?.toString() ??
              '-',
          'room':
              (patient['room'] ?? patient['ruangan'] ?? patient['ward'])
                  ?.toString() ??
              'ICU',
        };
      }).toList();

      debugPrint(
        '_inpatientsForUI[0]: ${_inpatientsForUI.isNotEmpty ? _inpatientsForUI[0].toString() : 'empty'}',
      );

      final roomsFromData = _inpatientsForUI
          .map((p) => p['room'])
          .toSet()
          .toList();
      setState(() {
        _rooms = ['Semua Ruangan', ...roomsFromData.cast<String>()];
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          child: Text(
            'Terjadi kesalahan: $_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_inpatientsForUI.isEmpty) {
      return const Center(child: Text('Belum ada data pasien rawat inap.'));
    }

    return PasienInapWidget(
      user: widget.user,
      rooms: _rooms,
      inpatients: _inpatientsForUI,
      navy: navyColor,
      cardBlue: cardBlueColor,
      role: 'perawat',
    );
  }
}
