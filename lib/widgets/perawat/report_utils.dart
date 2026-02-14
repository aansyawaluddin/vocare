import 'dart:convert';
import 'package:flutter/foundation.dart';

void debugPrintFull(String? message, {int chunkSize = 1000}) {
  if (message == null) {
    debugPrint('null');
    return;
  }
  if (message.length <= chunkSize) {
    debugPrint(message);
    return;
  }
  final pattern = RegExp('.{1,$chunkSize}', dotAll: true);
  for (final match in pattern.allMatches(message)) {
    debugPrint(match.group(0));
  }
}

void logApiResponse(
  Map<String, dynamic>? apiResponse, {
  String tag = 'API Response (pretty)',
}) {
  if (apiResponse == null) {
    debugPrint('API Response: null');
    return;
  }

  try {
    final status = apiResponse['statusCode'] ?? '';
    final body = apiResponse['body'] ?? apiResponse['data'] ?? apiResponse;
    final String pretty;

    if (body is String) {
      pretty = 'Status: $status\n\n${stripCodeFences(body)}';
    } else {
      pretty =
          'Status: $status\n\n${const JsonEncoder.withIndent('  ').convert(body)}';
    }

    debugPrintFull('--- $tag ---\n$pretty\n--- end ---');
  } catch (e) {
    debugPrint('Gagal men-serialize apiResponse: $e');
    debugPrintFull('Raw apiResponse.toString(): ${apiResponse.toString()}');
  }
}

String stripCodeFences(String s) {
  return s
      .replaceAll(RegExp(r'```json', multiLine: true), '')
      .replaceAll('```', '')
      .trim();
}

dynamic getCaseInsensitive(Map? map, String key) {
  if (map == null) return null;

  for (final entry in map.entries) {
    if (entry.key.toString().toLowerCase() == key.toLowerCase()) {
      return entry.value;
    }
  }
  return null;
}

dynamic getFirstNonNull(Map? map, List<String> keys) {
  if (map == null) return null;

  for (final key in keys) {
    final value = getCaseInsensitive(map, key);
    if (value != null) return value;
  }
  return null;
}

Map<String, dynamic>? normalizeParsedMap(Map<String, dynamic> parsed) {
  final asesmenAwalKeperawatan = getCaseInsensitive(
    parsed,
    'asesmen_awal_keperawatan',
  );
  if (asesmenAwalKeperawatan is Map<String, dynamic>) {
    debugPrint('Menemukan root asesmen di key: asesmen_awal_keperawatan');
    return asesmenAwalKeperawatan;
  }

  for (final entry in parsed.entries) {
    if (entry.key.toLowerCase().contains('asesmen')) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        debugPrint('Menemukan root asesmen di key: ${entry.key}');
        return Map<String, dynamic>.from(value);
      } else if (value is String) {
        try {
          final cleaned = stripCodeFences(value);
          final parsedChild = jsonDecode(cleaned);
          if (parsedChild is Map<String, dynamic>) {
            debugPrint('Menemukan root asesmen (string) di key: ${entry.key}');
            return Map<String, dynamic>.from(parsedChild);
          }
        } catch (_) {}
      }
    }
  }

  if (parsed.containsKey('informasi_umum') || parsed.containsKey('informasi')) {
    return parsed;
  }

  return parsed;
}

Map<String, dynamic>? extractAssessmentObject(
  Map<String, dynamic>? apiResponse,
) {
  if (apiResponse == null) return null;

  final candidate = apiResponse['data'] ?? apiResponse['body'] ?? apiResponse;

  try {
    if (candidate is String) {
      final cleaned = stripCodeFences(candidate);
      final parsed = jsonDecode(cleaned);
      if (parsed is Map<String, dynamic>) {
        return normalizeParsedMap(parsed);
      }
    }

    if (candidate is Map) {
      final normalized = normalizeParsedMap(
        Map<String, dynamic>.from(candidate),
      );

      if (normalized != null) {
        if (normalized.keys.any(
          (k) =>
              k.toLowerCase().contains('informasi_umum') ||
              k.toLowerCase().contains('keluhan_utama'),
        )) {
          return normalized;
        }
      }

      if (candidate.containsKey('asesmen_awal_keperawatan') &&
          candidate['asesmen_awal_keperawatan'] is Map<String, dynamic>) {
        debugPrint('Menemukan root di key: asesmen_awal_keperawatan');
        return Map<String, dynamic>.from(
          candidate['asesmen_awal_keperawatan'] as Map,
        );
      }

      if (candidate.containsKey('data')) {
        final dataValue = candidate['data'];
        if (dataValue is String) {
          final cleaned = stripCodeFences(dataValue);
          final parsed = jsonDecode(cleaned);
          if (parsed is Map<String, dynamic>) {
            return normalizeParsedMap(parsed);
          }
        } else if (dataValue is Map<String, dynamic>) {
          if (dataValue.containsKey('asesmen_awal_keperawatan') &&
              dataValue['asesmen_awal_keperawatan'] is Map<String, dynamic>) {
            debugPrint('Menemukan root di key data.asesmen_awal_keperawatan');
            return Map<String, dynamic>.from(
              dataValue['asesmen_awal_keperawatan'] as Map,
            );
          }
          return normalizeParsedMap(dataValue);
        }
      }

      return normalized;
    }
  } catch (e) {
    debugPrint('Gagal ekstrak assessment object: $e');
  }

  return null;
}

Map<String, dynamic> extractSubMap(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final value = getCaseInsensitive(source, key);
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
  }
  return <String, dynamic>{};
}

String? cleanAndFormatText(String? text) {
  if (text == null || text.trim().isEmpty || text.toLowerCase() == 'null') {
    return null;
  }

  return text
      .replaceAll(RegExp(r'riwayat_\w+:\s*', multiLine: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^,\s*'), '')
      .replaceAll(RegExp(r',\s*$'), '')
      .trim();
}

Map<String, dynamic> extractFieldsFromAssessment(
  Map<String, dynamic>? asesmen,
) {
  if (asesmen == null) return {};

  final informasiUmum = extractSubMap(asesmen, ['informasi_umum', 'informasi']);

  final kunjunganRaw = extractSubMap(asesmen, ['kunjungan', 'data_kunjungan']);
  final kunjungan = kunjunganRaw.isNotEmpty ? kunjunganRaw : informasiUmum;

  final penanggungJawabMap = extractSubMap(informasiUmum, ['penanggung_jawab']);

  final riwayatMap = extractSubMap(asesmen, [
    'informasi_tambahan',
    'riwayat_kesehatan',
    'pemeriksaan_sistem',
  ]);

  final pemeriksaanFisik = extractSubMap(asesmen, ['pemeriksaan_fisik']);

  final tandaVital = <String, dynamic>{};
  final dynamic tandaVitalRaw = getCaseInsensitive(
    pemeriksaanFisik,
    'tanda_vital',
  );
  if (tandaVitalRaw is Map<String, dynamic>) {
    tandaVital.addAll(tandaVitalRaw);
  } else {
    tandaVital.addAll(extractSubMap(asesmen, ['tanda_vital']));
  }

  final alergiMap = extractSubMap(asesmen, ['alergi']);
  final asesmenNyeri = extractSubMap(asesmen, ['asesmen_nyeri']);
  final skriningGizi = extractSubMap(asesmen, ['skrining_gizi']);
  final skriningJatuh = extractSubMap(asesmen, ['skrining_risiko_jatuh']);
  final psikososial = extractSubMap(asesmen, ['status_psikososial']);
  final administrasi = extractSubMap(asesmen, ['administrasi']);
  final edukasiMap = extractSubMap(asesmen, ['edukasi']);
  final rencanaPerawatanMap = extractSubMap(asesmen, ['rencana_perawatan']);

  final rencanaAsuhanString = getFirstNonNull(rencanaPerawatanMap, [
    'rencana_asuhan_keperawatan',
  ])?.toString();

  return buildExtractedFieldsMap(
    asesmen: asesmen,
    informasiUmum: informasiUmum,
    kunjungan: kunjungan,
    penanggungJawabMap: penanggungJawabMap,
    keluhanUtamaMap: extractSubMap(asesmen, ['keluhan_utama']),
    riwayatMap: riwayatMap,
    alergiMap: alergiMap,
    statusGeneral: tandaVital,
    statusKesadaran: pemeriksaanFisik,
    pemeriksaanFisik: pemeriksaanFisik,
    asesmenNyeri: asesmenNyeri,
    skriningGizi: skriningGizi,
    skriningJatuh: skriningJatuh,
    psikososial: psikososial,
    rencana: extractSubMap(asesmen, ['rencana_asuhan_keperawatan']),
    masalah: extractSubMap(asesmen, ['masalah_keperawatan']),
    ttd: administrasi,
    rencana_asuhan: rencanaAsuhanString,
    edukasi: edukasiMap,
  );
}

Map<String, dynamic> buildExtractedFieldsMap({
  required Map<String, dynamic> asesmen,
  required Map<String, dynamic> informasiUmum,
  required Map<String, dynamic> kunjungan,
  required Map<String, dynamic> penanggungJawabMap,
  required Map<String, dynamic> keluhanUtamaMap,
  required Map<String, dynamic> riwayatMap,
  required Map<String, dynamic> alergiMap,
  required Map<String, dynamic> statusGeneral,
  required Map<String, dynamic> statusKesadaran,
  required Map<String, dynamic> pemeriksaanFisik,
  required Map<String, dynamic> asesmenNyeri,
  required Map<String, dynamic> skriningGizi,
  required Map<String, dynamic> skriningJatuh,
  required Map<String, dynamic> psikososial,
  required Map<String, dynamic> rencana,
  required Map<String, dynamic> masalah,
  required Map<String, dynamic> ttd,
  required String? rencana_asuhan,
  required Map<String, dynamic> edukasi,
}) {
  final alergiRaw =
      getFirstNonNull(asesmen, ['alergi']) ??
      getFirstNonNull(riwayatMap, ['alergi']) ??
      getFirstNonNull(alergiMap, ['obat', 'makanan', 'alergi']);
  final String? alergiCombined = cleanAndFormatText(alergiRaw?.toString());

  final kondisiSosialRaw = getCaseInsensitive(psikososial, 'kondisi_sosial');
  final Map<String, dynamic> kondisiSosial =
      kondisiSosialRaw is Map<String, dynamic> ? kondisiSosialRaw : {};

  final pfKeys = {
    'kepala': getFirstNonNull(pemeriksaanFisik, [
      'head_eyes_ears_nose_throat',
      'kepala',
      'kepala_dan_mata',
    ]),
    'mata': getFirstNonNull(pemeriksaanFisik, ['mata']),
    'tht': getFirstNonNull(pemeriksaanFisik, ['tht']),
    'mulut': getFirstNonNull(pemeriksaanFisik, ['mulut']),
    'leher': getFirstNonNull(pemeriksaanFisik, ['leher']),
    'thoraks': getFirstNonNull(pemeriksaanFisik, [
      'thorak_dan_payudara',
      'thoraks',
    ]),
    'jantung': getFirstNonNull(pemeriksaanFisik, ['jantung']),
    'abdomen': getFirstNonNull(pemeriksaanFisik, ['abdomen']),
    'urogenital': getFirstNonNull(pemeriksaanFisik, ['urogenital']),
    'ekstremitas': getFirstNonNull(pemeriksaanFisik, ['ekstremitas']),
    'kulit': getFirstNonNull(pemeriksaanFisik, ['integumen', 'kulit']),
  };

  return {
    'no_rm': getFirstNonNull(informasiUmum, ['nomor_rekam_medis', 'no_rm']),
    'nama_pasien': getFirstNonNull(informasiUmum, [
      'nama_lengkap',
      'nama',
      'nama_pasien',
    ]),
    'jenis_kelamin': getFirstNonNull(informasiUmum, ['jenis_kelamin']),
    'tanggal_lahir': getFirstNonNull(informasiUmum, ['tanggal_lahir']),
    'alamat': getFirstNonNull(informasiUmum, ['alamat']),
    'pekerjaan': getFirstNonNull(informasiUmum, ['pekerjaan']),
    'status_perkawinan': getFirstNonNull(informasiUmum, ['status_perkawinan']),

    'pj_nama': getFirstNonNull(informasiUmum, [
      'penanggung_jawab', 
      'nama_penanggung_jawab',
      'nama_pj',
    ]),
    'pj_hubungan': getFirstNonNull(informasiUmum, [
      'pendamping', 
      'hubungan',
      'hubungan_pj',
    ]),
    'pj_telepon': getFirstNonNull(informasiUmum, [
      'kontak_penanggung_jawab',
      'nomor_hp_pj',
      'telepon_pj',
    ]),

    'tanggal_masuk': getFirstNonNull(kunjungan, [
      'tanggal_masuk',
      'tanggal',
      'tanggal_kunjungan',
    ]),
    'waktu_masuk': getFirstNonNull(kunjungan, [
      'waktu_masuk',
      'waktu',
      'jam_masuk',
      'waktu_kunjungan'
    ]),
    'poli': getFirstNonNull(kunjungan, [
      'poliklinik_tujuan',
      'poli_tujuan',
      'poli',
      'tujuan_poli'
    ]),
    'cara_masuk': getFirstNonNull(kunjungan, ['cara_masuk']),

    'keluhan_utama':
        getFirstNonNull(asesmen, ['keluhan_utama']) ??
        getFirstNonNull(keluhanUtamaMap, ['keluhan']),
    'durasi_keluhan': getFirstNonNull(keluhanUtamaMap, ['durasi']),
    'alergi': alergiCombined,
    'kesadaran': getFirstNonNull(statusKesadaran, [
      'kesadaran',
      'tingkat_kesadaran',
    ])?.toString(),
    'tekanan_darah': getFirstNonNull(statusGeneral, ['tekanan_darah', 'td']),
    'nadi': getFirstNonNull(statusGeneral, ['denyut_nadi', 'nadi']),
    'respirasi': getFirstNonNull(statusGeneral, [
      'laju_pernapasan',
      'respirasi',
    ]),
    'suhu': getFirstNonNull(statusGeneral, ['suhu_tubuh_c', 'suhu']),

    'kepala': pfKeys['kepala'],
    'mata': pfKeys['mata'],
    'tht': pfKeys['tht'],
    'mulut': pfKeys['mulut'],
    'leher': pfKeys['leher'],
    'thoraks': pfKeys['thoraks'],
    'jantung': pfKeys['jantung'],
    'abdomen': pfKeys['abdomen'],
    'urogenital': pfKeys['urogenital'],
    'ekstremitas': pfKeys['ekstremitas'],
    'kulit': pfKeys['kulit'],

    'karakter_nyeri': getFirstNonNull(asesmenNyeri, ['sifat', 'karakter']),
    'lokasi_nyeri': getFirstNonNull(asesmenNyeri, ['lokasi']),
    'faktor_pencetus_nyeri': getFirstNonNull(asesmenNyeri, [
      'pencetus',
      'faktor_pencetus',
    ]),
    'faktor_penghilang_nyeri': getFirstNonNull(asesmenNyeri, [
      'penghilang',
      'faktor_penghilang',
    ]),
    'skala': getFirstNonNull(asesmenNyeri, ['skala', 'skala_nyeri']),

    'skor_gizi': getFirstNonNull(skriningGizi, ['skor', 'skor_gizi']),
    'tinggi_badan': getFirstNonNull(skriningGizi, ['tinggi_badan'])?.toString(),
    'berat_badan': getFirstNonNull(skriningGizi, ['berat_badan'])?.toString(),
    'IMT': getFirstNonNull(skriningGizi, ['IMT'])?.toString(),
    'penurunan_berat_badan': getFirstNonNull(skriningGizi, [
      'penurunan_berat_badan',
    ])?.toString(),
    'status_gizi': getFirstNonNull(skriningGizi, ['status_gizi']),
    'skala_morse': getFirstNonNull(skriningJatuh, ['skor', 'skala_morse']),
    'kategori_jatuh': getFirstNonNull(skriningJatuh, [
      'kategori',
      'keterangan',
    ]),
    'alat_bantu_jalan': getFirstNonNull(skriningJatuh, ['alat_bantu_jalan']),

    'bahasa_sehari_hari': getFirstNonNull(psikososial, ['bahasa']),
    'komunikasi': getFirstNonNull(psikososial, [
      'komunikasi_dan_interaksi',
      'komunikasi',
    ]),
    'kondisi_emosional': getFirstNonNull(psikososial, ['status_emosional']),
    'kebutuhan_spiritual': getFirstNonNull(psikososial, ['kebutuhan_ibadah']),
    'pemahaman_perawatan': getFirstNonNull(psikososial, [
      'pemahaman',
      'pemahaman_pasien',
    ]),

    'masalah_keperawatan_list': getFirstNonNull(asesmen, [
      'masalah_keperawatan',
    ]),
    'rencana_asuhan_string': cleanAndFormatText(rencana_asuhan),
  };
}
