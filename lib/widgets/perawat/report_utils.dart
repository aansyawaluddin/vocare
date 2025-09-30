// assessment_detail_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// -------------------------
/// Helper: Debug / Logging
/// -------------------------
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

/// -------------------------
/// Parsing / Normalizing JSON
/// -------------------------
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
  // Cek key spesifik "asesmen_awal_keperawatan"
  final asesmenAwalKeperawatan = getCaseInsensitive(
    parsed,
    'asesmen_awal_keperawatan',
  );
  if (asesmenAwalKeperawatan is Map<String, dynamic>) {
    debugPrint('Menemukan root asesmen di key: asesmen_awal_keperawatan');
    return asesmenAwalKeperawatan;
  }

  // Logic yang ada: mencari key yang mengandung 'asesmen'
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
        } catch (_) {
          // Ignore parsing errors
        }
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
    // 1. Cek jika 'candidate' adalah string (data di dalam 'data' key)
    if (candidate is String) {
      final cleaned = stripCodeFences(candidate);
      final parsed = jsonDecode(cleaned);
      if (parsed is Map<String, dynamic>) {
        return normalizeParsedMap(parsed);
      }
    }

    // 2. Cek jika 'candidate' adalah Map (struktur tingkat atas)
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

      // Kasus: objek asesmen ada di key spesifik "asesmen_awal_keperawatan" di level root map
      if (candidate.containsKey('asesmen_awal_keperawatan') &&
          candidate['asesmen_awal_keperawatan'] is Map<String, dynamic>) {
        debugPrint('Menemukan root di key: asesmen_awal_keperawatan');
        return Map<String, dynamic>.from(
          candidate['asesmen_awal_keperawatan'] as Map,
        );
      }

      // Kasus: Objek asesmen ada di key "data"
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

      // Kasus: Kembalikan normalized jika tidak null
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

String cleanAndFormatText(String? text) {
  if (text == null || text.trim().isEmpty || text.toLowerCase() == 'null') {
    return '-';
  }

  return text
      .replaceAll(RegExp(r'riwayat_\w+:\s*', multiLine: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^,\s*'), '')
      .replaceAll(RegExp(r',\s*$'), '')
      .trim();
}

/// Extract fields dari object asesmen (memakai fallback dan parsing rencana_asuhan)
Map<String, dynamic> extractFieldsFromAssessment(
  Map<String, dynamic>? asesmen,
) {
  if (asesmen == null) return {};

  final informasiUmum = extractSubMap(asesmen, ['informasi_umum', 'informasi']);
  final kunjungan = extractSubMap(asesmen, ['kunjungan', 'data_kunjungan']);

  // Perbaikan: Pisahkan Pemeriksaan Sistem dan Pemeriksaan Fisik
  final pemeriksaanSistem = extractSubMap(asesmen, [
    'pemeriksaan_sistem',
    'riwayat_kesehatan',
  ]); // Ini berisi riwayat penyakit, nafsu makan, dll.
  final riwayatPenyakit = pemeriksaanSistem; // Alias untuk kemudahan

  final statusUmum = extractSubMap(asesmen, ['status_umum']);

  final tandaVital = <String, dynamic>{};
  final dynamic tandaVitalRaw = getCaseInsensitive(statusUmum, 'tanda_vital');
  if (tandaVitalRaw is Map<String, dynamic>) {
    tandaVital.addAll(tandaVitalRaw);
  } else {
    tandaVital.addAll(extractSubMap(asesmen, ['tanda_vital']));
  }

  // Pemeriksaan Fisik (Body System)
  final pemeriksaanFisik = extractSubMap(asesmen, ['pemeriksaan_fisik']);

  final alergiMap = extractSubMap(asesmen, ['alergi']);
  final asesmenNyeri = extractSubMap(asesmen, ['asesmen_nyeri']);
  final skriningGizi = extractSubMap(asesmen, ['skrining_gizi']);
  final skriningJatuh = extractSubMap(asesmen, ['skrining_risiko_jatuh']);
  final psikososial = extractSubMap(asesmen, ['status_psikososial']);
  final rencana = extractSubMap(asesmen, ['rencana_perawatan', 'rencana']);
  final masalah = extractSubMap(asesmen, ['masalah_keperawatan']);
  final administrasi = extractSubMap(asesmen, ['administrasi']);
  final rencanaAsuhanRaw = getFirstNonNull(asesmen, [
    'rencana_asuhan_keperawatan',
  ]);

  // Normalize rencana_asuhan menjadi List<String>
  List<String> rencanaAsuhanList = [];
  if (rencanaAsuhanRaw is List) {
    rencanaAsuhanList = rencanaAsuhanRaw
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  } else if (rencanaAsuhanRaw is String && rencanaAsuhanRaw.trim().isNotEmpty) {
    rencanaAsuhanList = rencanaAsuhanRaw
        .split(RegExp(r'\r?\n|;|,|-'))
        .map((e) => e.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  } else {
    // fallback: kosong
    rencanaAsuhanList = <String>[];
  }

  return buildExtractedFieldsMap(
    asesmen: asesmen,
    informasiUmum: informasiUmum,
    kunjungan: kunjungan,
    keluhanUtamaMap: extractSubMap(asesmen, ['keluhan_utama']),
    riwayatMap: riwayatPenyakit,
    alergiMap: alergiMap,
    statusGeneral: tandaVital,
    statusKesadaran: statusUmum,
    pemeriksaanFisik: pemeriksaanFisik,
    asesmenNyeri: asesmenNyeri,
    skriningGizi: skriningGizi,
    skriningJatuh: skriningJatuh,
    psikososial: psikososial,
    rencana: rencana,
    masalah: masalah,
    ttd: administrasi,
    rencana_asuhan: rencanaAsuhanList,
  );
}

Map<String, dynamic> buildExtractedFieldsMap({
  required Map<String, dynamic> asesmen,
  required Map<String, dynamic> informasiUmum,
  required Map<String, dynamic> kunjungan,
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
  required dynamic rencana_asuhan,
}) {
  final alergiRaw =
      getFirstNonNull(asesmen, ['alergi']) ??
      getFirstNonNull(alergiMap, ['obat', 'makanan', 'alergi']);
  final String alergiCombined =
      cleanAndFormatText(alergiRaw?.toString()) ?? '-';

  final kondisiSosialRaw = getCaseInsensitive(psikososial, 'kondisi_sosial');
  final Map<String, dynamic> kondisiSosial =
      kondisiSosialRaw is Map<String, dynamic> ? kondisiSosialRaw : {};

  final pfKeys = {
    'kepala': getFirstNonNull(pemeriksaanFisik, ['kepala', 'kepala_dan_mata']),
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
    'kulit': getFirstNonNull(pemeriksaanFisik, ['kulit']),
  };

  return {
    // INFORMASI UMUM
    'no_rm': getFirstNonNull(informasiUmum, [
      'no_rekam_medis',
      'no_rm',
      'nomor_rekam_medis',
      'nomor_identitas',
      'no_identitas',
    ]),
    'nama_pasien': getFirstNonNull(informasiUmum, [
      'nama_lengkap',
      'nama_pasien',
      'nama',
    ]),
    'jenis_kelamin': getFirstNonNull(informasiUmum, ['jenis_kelamin']),
    'tanggal_lahir': getFirstNonNull(informasiUmum, ['tanggal_lahir']),
    'alamat': getFirstNonNull(informasiUmum, ['alamat']),
    'pekerjaan': getFirstNonNull(informasiUmum, ['pekerjaan']),
    'status_perkawinan': getFirstNonNull(informasiUmum, ['status_perkawinan']),
    'penanggung_jawab': getFirstNonNull(informasiUmum, ['penanggung_jawab']),
    'hubungan_penanggung_jawab': getFirstNonNull(informasiUmum, [
      'hubungan_penanggung_jawab',
    ]),
    'kontak_penanggung_jawab': getFirstNonNull(informasiUmum, [
      'kontak_penanggung_jawab',
    ]),

    // KUNJUNGAN
    'tanggal_masuk': getFirstNonNull(kunjungan, [
      'tanggal_kunjungan',
      'tanggal_masuk',
      'tanggal',
    ]),
    'waktu_masuk': getFirstNonNull(kunjungan, [
      'jam_kunjungan',
      'jam_masuk',
      'waktu_masuk',
      'waktu_kunjungan',
    ]),
    'poli': getFirstNonNull(kunjungan, [
      'tujuan_poli',
      'poli',
      'poliklinik_tujuan',
    ]),
    'pelayanan': getFirstNonNull(kunjungan, [
      'pelayanan',
      'kelas',
      'pelayanan_digunakan',
      'kelas_pelayanan',
    ]),
    'pendamping': getFirstNonNull(kunjungan, ['pendamping']),
    'sumber_data': getFirstNonNull(kunjungan, [
      'sumber_data_anamnesa',
      'sumber_data',
    ]),
    'rujukan': getFirstNonNull(kunjungan, ['rujukan', 'asal_rujukan']),
    'cara_masuk': getFirstNonNull(kunjungan, ['cara_masuk']),

    // KELUHAN UTAMA
    'keluhan_utama':
        getFirstNonNull(asesmen, ['keluhan_utama']) ??
        getFirstNonNull(keluhanUtamaMap, ['keluhan']),
    'durasi_keluhan': getFirstNonNull(keluhanUtamaMap, [
      'durasi',
      'lama_keluhan',
    ]),

    // RIWAYAT & SISTEM
    'riwayat_penyakit_sekarang': cleanAndFormatText(
      getFirstNonNull(riwayatMap, ['riwayat_penyakit'])?.toString(),
    ),
    'riwayat_penyakit_dahulu': cleanAndFormatText(
      getFirstNonNull(riwayatMap, ['riwayat_penyakit'])?.toString(),
    ),
    'riwayat_operasi': cleanAndFormatText(
      getFirstNonNull(riwayatMap, ['riwayat_operasi'])?.toString(),
    ),
    'riwayat_transfusi': cleanAndFormatText(
      getFirstNonNull(riwayatMap, [
        'riwayat_transfusi_darah',
        'riwayat_transfusi',
      ])?.toString(),
    ),
    'golongan_darah': getFirstNonNull(riwayatMap, ['golongan_darah']),
    'nafsu_makan': getFirstNonNull(riwayatMap, ['nafsu_makan'])?.toString(),
    'perubahan_berat_badan': getFirstNonNull(riwayatMap, [
      'perubahan_berat_badan',
    ])?.toString(),

    // Alergi
    'alergi': alergiCombined,
    'gelang_alergi': getFirstNonNull(alergiMap, ['gelang_alergi']),

    // STATUS & TANDA VITAL
    'kesadaran': getFirstNonNull(pemeriksaanFisik, [
      'tingkat_kesadaran',
      'kesadaran',
    ])?.toString(),
    'gcs': getFirstNonNull(statusKesadaran, ['gcs']),
    'keadaan_umum': getFirstNonNull(statusKesadaran, [
      'keadaan_umum',
      'keadaan',
    ]),
    'tekanan_darah': getFirstNonNull(statusGeneral, ['tekanan_darah', 'td']),
    'nadi': getFirstNonNull(statusGeneral, ['denyut_nadi', 'nadi']),
    'respirasi': getFirstNonNull(statusGeneral, [
      'laju_pernapasan',
      'respirasi',
    ]),
    'suhu': getFirstNonNull(statusGeneral, ['suhu_tubuh_c', 'suhu']),

    // PEMERIKSAAN FISIK
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

    // ASESMEN NYERI
    'karakter_nyeri': getFirstNonNull(asesmenNyeri, ['sifat', 'karakter']),
    'lokasi_nyeri': getFirstNonNull(asesmenNyeri, ['lokasi']),
    'faktor_pencetus_nyeri': getFirstNonNull(asesmenNyeri, [
      'pemicu',
      'faktor_pemicu',
      'pencetus',
    ]),
    'faktor_penghilang_nyeri': getFirstNonNull(asesmenNyeri, [
      'penghilang',
      'faktor_penghilang',
    ]),
    'skala': getFirstNonNull(asesmenNyeri, ['skala_nyeri', 'skala']),

    // SKRINING GIZI
    'skor_gizi': getFirstNonNull(skriningGizi, ['skor', 'skor_gizi']),
    'tinggi_badan': getFirstNonNull(skriningGizi, [
      'tinggi_badan',
      'tinggi_badan_cm',
    ])?.toString(),
    'berat_badan': getFirstNonNull(skriningGizi, [
      'berat_badan',
      'berat_badan_kg',
    ])?.toString(),
    'IMT': getFirstNonNull(skriningGizi, ['IMT'])?.toString(),
    'penurunan_berat_badan': getFirstNonNull(skriningGizi, [
      'penurunan_berat_badan',
      'penurunan_berat',
      'perubahan_berat',
    ])?.toString(),
    'status_gizi': getFirstNonNull(skriningGizi, ['status_gizi']),

    // SKRINING JATUH
    'skala_morse': getFirstNonNull(skriningJatuh, ['skor', 'skala_morse']),
    'riwayat_jatuh': getFirstNonNull(skriningJatuh, [
      'riwayat_jatuh_1_tahun',
      'riwayat_jatuh',
    ]),
    'orientasi': getFirstNonNull(skriningJatuh, ['orientasi']),
    'alat_bantu_jalan': getFirstNonNull(skriningJatuh, [
      'penggunaan_alat_bantu',
      'alat_bantu_jalan',
    ]),
    'infus': getFirstNonNull(skriningJatuh, ['terpasang_infus', 'infus']),
    'kategori_jatuh': getFirstNonNull(skriningJatuh, ['kategori']),

    // PSIKOSOSIAL
    'komposisi_keluarga': getFirstNonNull(psikososial, ['komposisi_keluarga']),
    'bahasa_sehari_hari': getFirstNonNull(psikososial, [
      'bahasa_sehari_hari',
      'bahasa',
    ]),
    'komunikasi': getFirstNonNull(psikososial, [
      'status_komunikasi',
      'komunikasi',
    ]),
    'kondisi_emosional': getFirstNonNull(psikososial, [
      'status_emosional',
      'kondisi_emosional',
    ]),
    'dukungan_keluarga': getFirstNonNull(psikososial, ['dukungan_keluarga']),
    'riwayat_gangguan_jiwa': getFirstNonNull(psikososial, [
      'gangguan_jiwa',
      'riwayat_gangguan_jiwa',
    ]),
    'kebutuhan_spiritual': getFirstNonNull(psikososial, [
      'kebutuhan_ibadah',
      'kebutuhan_spiritual',
    ]),
    'status_ekonomi': getFirstNonNull(kondisiSosial, [
      'ekonomi',
      'status_ekonomi',
    ]),
    'pendidikan': getFirstNonNull(kondisiSosial, [
      'kondisi_sosial',
      'pendidikan',
    ]),
    'pemahaman_perawatan': getFirstNonNull(psikososial, [
      'pemahaman_rencana_perawatan',
    ]),

    // RENCANA PERAWATAN
    'observasi': getFirstNonNull(rencana, ['observasi']),
    'edukasi': getFirstNonNull(asesmen, ['edukasi']),
    'home_care': getFirstNonNull(rencana, ['home_care']),
    'rujukan': getFirstNonNull(rencana, ['rujukan']),

    // MASALAH KEPERAWATAN
    'masalah_keperawatan_list': getFirstNonNull(asesmen, [
      'masalah_keperawatan',
    ]),
    'diagnosa_utama': getFirstNonNull(masalah, ['utama']),
    'risiko': getFirstNonNull(masalah, ['risiko']),

    // ADMINISTRASI
    'lokasi_asesmen':
        getFirstNonNull(ttd, ['lokasi_asesmen']) ??
        getFirstNonNull(asesmen, ['lokasi_asesmen']),
    'tanggal_asesmen':
        getFirstNonNull(ttd, ['tanggal_asesmen']) ??
        getFirstNonNull(asesmen, ['tanggal_asesmen']),
    'perawat_pengassesmen':
        getFirstNonNull(ttd, ['perawat_asesmen']) ??
        getFirstNonNull(asesmen, ['perawat']),
    'ttd_perawat': getFirstNonNull(ttd, ['ttd_perawat_asesmen']),
    'perawat_penanggung_jawab': getFirstNonNull(ttd, [
      'perawat_penanggung_jawab',
    ]),
    'ttd_dokter': getFirstNonNull(ttd, ['ttd_perawat_penanggung_jawab']),

    // RENCANA ASUHAN LIST (selalu tersedia sebagai List<String>)
    'rencana_asuhan_list': (rencana_asuhan is List)
        ? rencana_asuhan
              .map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList()
        : <String>[],
  };
}
