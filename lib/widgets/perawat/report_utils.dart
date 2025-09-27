import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

dynamic getNestedValue(Map? root, List<String> path) {
  if (root == null || path.isEmpty) return null;

  dynamic current = root;
  for (int i = 0; i < path.length; i++) {
    if (current is! Map) return null;

    current = getCaseInsensitive(current, path[i]);
    if (current == null) return null;
  }

  return current;
}

Map<String, String> parseMultipleInfo(String? rawText) {
  if (rawText == null || rawText.trim().isEmpty) {
    return {};
  }
  return {};
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
  final rencana = extractSubMap(asesmen, ['rencana_perawatan']);
  final masalah = extractSubMap(asesmen, ['masalah_keperawatan']);
  final administrasi = extractSubMap(asesmen, ['administrasi']);

  final pendampingRaw =
      getFirstNonNull(kunjungan, ['pendamping']) ??
      getFirstNonNull(informasiUmum, ['pendamping', 'nama_pendamping']);

  return buildExtractedFieldsMap(
    asesmen: asesmen,
    informasiUmum: informasiUmum,
    kunjungan: kunjungan,
    pendamping: {'raw': pendampingRaw},
    keluhanUtamaMap: extractSubMap(asesmen, ['keluhan_utama']),
    riwayatMap: riwayatPenyakit, // Sekarang berisi pemeriksaan_sistem
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
  );
}

Map<String, dynamic> buildExtractedFieldsMap({
  required Map<String, dynamic> asesmen,
  required Map<String, dynamic> informasiUmum,
  required Map<String, dynamic> kunjungan,
  required Map<String, dynamic> pendamping,
  required Map<String, dynamic> keluhanUtamaMap,
  required Map<String, dynamic>
  riwayatMap, // Ini sekarang adalah Pemeriksaan Sistem (riwayat_penyakit, nafsu_makan, dll)
  required Map<String, dynamic> alergiMap,
  required Map<String, dynamic> statusGeneral, // Tanda Vital
  required Map<String, dynamic> statusKesadaran, // Status Umum & Kesadaran
  required Map<String, dynamic>
  pemeriksaanFisik, // Pemeriksaan Fisik (Per Sistem)
  required Map<String, dynamic> asesmenNyeri,
  required Map<String, dynamic> skriningGizi,
  required Map<String, dynamic> skriningJatuh,
  required Map<String, dynamic> psikososial,
  required Map<String, dynamic> rencana,
  required Map<String, dynamic> masalah,
  required Map<String, dynamic> ttd,
}) {
  final pendampingRaw = pendamping['raw'];
  final pendampingNama = pendampingRaw is String
      ? pendampingRaw
      : getFirstNonNull(pendamping, ['nama']);

  // Logika gabungan alergi disederhanakan karena JSON hanya memiliki 'alergi' di root 'asesmen_awal_keperawatan'
  final alergiRaw =
      getFirstNonNull(asesmen, ['alergi']) ??
      getFirstNonNull(alergiMap, ['obat', 'makanan', 'alergi']);
  final String alergiCombined =
      cleanAndFormatText(alergiRaw?.toString()) ?? '-';

  // Ekstraksi nested Kondisi Sosial (dari Status Psikososial)
  final kondisiSosialRaw = getCaseInsensitive(psikososial, 'kondisi_sosial');
  final Map<String, dynamic> kondisiSosial =
      kondisiSosialRaw is Map<String, dynamic> ? kondisiSosialRaw : {};

  // Ekstraksi Pemeriksaan Fisik
  final pfKeys = {
    'kepala': getFirstNonNull(pemeriksaanFisik, [
      'kepala',
      'kepala_dan_mata',
    ]), // Gabung kepala dan mata
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
    // 1. INFORMASI UMUM (Sesuai JSON)
    'no_rm': getFirstNonNull(informasiUmum, ['nomor_rekam_medis', 'no_rm']),
    'nama_pasien': getFirstNonNull(informasiUmum, [
      'nama_lengkap',
      'nama_pasien',
      'nama',
    ]),
    'jenis_kelamin': getFirstNonNull(informasiUmum, ['jenis_kelamin']),
    'tanggal_lahir': getFirstNonNull(informasiUmum, ['tanggal_lahir']),
    'usia': getFirstNonNull(informasiUmum, [
      'usia',
    ]), // Tidak ada di JSON, biarkan null
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
    'agama': getFirstNonNull(informasiUmum, ['agama']),

    // 2. KUNJUNGAN (Sesuai JSON)
    'tanggal_masuk': getFirstNonNull(kunjungan, [
      'tanggal_kunjungan',
      'tanggal_masuk',
      'tanggal',
    ]),
    'jam_kunjungan': getFirstNonNull(kunjungan, [
      'jam_kunjungan',
      'jam_masuk',
      'waktu',
    ]),
    'poli': getFirstNonNull(kunjungan, ['tujuan_poli', 'poli']),
    'kelas': getFirstNonNull(kunjungan, ['kelas_pelayanan', 'kelas']),
    'sumber_data': getFirstNonNull(kunjungan, [
      'sumber_data_anamnesa',
      'sumber_data',
    ]),
    'rujukan': getFirstNonNull(kunjungan, ['rujukan']),
    'cara_masuk': getFirstNonNull(kunjungan, ['cara_masuk']),
    'pendamping_raw': pendampingRaw,

    // PENDAMPING (mapping dari data_kunjungan/informasi_umum)
    'pendamping': {
      'raw': pendampingRaw,
      'nama': pendampingNama,
      'hubungan': getFirstNonNull(informasiUmum, [
        'hubungan_penanggung_jawab',
      ]), // Ambil dari PJ jika pendamping sama
      'usia': getFirstNonNull(kunjungan, ['usia_pendamping']),
      'kondisi': getFirstNonNull(kunjungan, ['kondisi_pendamping']),
    },

    // 3. KELUHAN UTAMA (Sesuai JSON)
    'keluhan_utama':
        getFirstNonNull(asesmen, ['keluhan_utama']) ??
        getFirstNonNull(keluhanUtamaMap, ['keluhan']),
    'durasi_keluhan': getFirstNonNull(keluhanUtamaMap, [
      'durasi',
      'lama_keluhan',
    ]),

    // 4. RIWAYAT & SISTEM (Sesuai JSON riwayat_penyakit & pemeriksaan_sistem)
    // riwayatMap sekarang adalah 'pemeriksaan_sistem'
    'riwayat_penyakit_sekarang': cleanAndFormatText(
      getFirstNonNull(riwayatMap, ['riwayat_penyakit'])?.toString(),
    ), // Hanya ada 1 field riwayat_penyakit di JSON
    'riwayat_penyakit_dahulu': cleanAndFormatText(
      getFirstNonNull(riwayatMap, ['riwayat_penyakit'])?.toString(),
    ), // Gunakan riwayat_penyakit yang sama
    'riwayat_operasi': cleanAndFormatText(
      getFirstNonNull(riwayatMap, ['riwayat_operasi'])?.toString(),
    ),
    'riwayat_transfusi': cleanAndFormatText(
      getFirstNonNull(riwayatMap, ['riwayat_transfusi_darah'])?.toString(),
    ),
    'golongan_darah': getFirstNonNull(riwayatMap, ['golongan_darah']),

    // Field baru dari Pemeriksaan Sistem
    'nafsu_makan': getFirstNonNull(riwayatMap, ['nafsu_makan'])?.toString(),
    'perubahan_berat_badan': getFirstNonNull(riwayatMap, [
      'perubahan_berat_badan',
    ])?.toString(),

    // Alergi (gabungan obat & makanan)
    'alergi': alergiCombined,
    'gelang_alergi': getFirstNonNull(alergiMap, [
      'gelang_alergi',
    ]), // Tidak ada di JSON
    // 5. STATUS GENERAL & TANDA VITAL (Sesuai JSON)
    // Tinggi/Berat Badan di Pemeriksaan Fisik
    'tinggi_badan': getFirstNonNull(pemeriksaanFisik, [
      'tinggi_badan,',
      'tinggi_badan_cm',
    ])?.toString(),
    'berat_badan': getFirstNonNull(pemeriksaanFisik, [
      'berat_badan',
      'berat_badan_kg',
    ])?.toString(),

    'kesadaran': getFirstNonNull(pemeriksaanFisik, [
      'tingkat_kesadaran',
      'kesadaran',
    ])?.toString(),
    'gcs': getFirstNonNull(statusKesadaran, ['gcs']),
    'keadaan_umum': getFirstNonNull(statusKesadaran, [
      'keadaan_umum',
      'keadaan',
    ]),

    // Tanda vital (sesuai field JSON contoh)
    'tekanan_darah': getFirstNonNull(statusGeneral, ['tekanan_darah', 'td']),
    'nadi': getFirstNonNull(statusGeneral, ['denyut_nadi', 'nadi']),
    'respirasi': getFirstNonNull(statusGeneral, [
      'laju_pernapasan',
      'respirasi',
    ]),
    'suhu': getFirstNonNull(statusGeneral, ['suhu_tubuh_c', 'suhu']),

    // 6. PEMERIKSAAN FISIK (Sesuai JSON)
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

    // 7. ASESMEN NYERI (mapping sesuai JSON)
    'jenis_nyeri': getFirstNonNull(asesmenNyeri, [
      'jenis',
    ]), // Tidak ada di JSON
    'karakter_nyeri': getFirstNonNull(asesmenNyeri, ['sifat', 'karakter']),
    'lokasi_nyeri': getFirstNonNull(asesmenNyeri, ['lokasi']),
    'penjalaran_nyeri': getFirstNonNull(asesmenNyeri, ['penjalaran']),
    'skor': getFirstNonNull(asesmenNyeri, ['skala', 'intensitas', 'skor']),
    'durasi_nyeri': getFirstNonNull(asesmenNyeri, [
      'durasi',
    ]), // Tidak ada di JSON
    'faktor_pencetus_nyeri': getFirstNonNull(asesmenNyeri, [
      'pemicu',
      'faktor_pemicu',
    ]),
    'faktor_pereda_nyeri': getFirstNonNull(asesmenNyeri, [
      'penurun',
      'faktor_pereda',
    ]),
    'rekomendasi_nyeri': getFirstNonNull(asesmenNyeri, [
      'rekomendasi',
    ]), // Tidak ada di JSON
    // 8. SKRINING GIZI (Sesuai JSON)
    'penurunan_berat_badan': getFirstNonNull(skriningGizi, [
      'penurunan_berat_badan',
    ]), // Tidak ada di JSON
    'asupan_makanan': getFirstNonNull(skriningGizi, [
      'asupan_makanan',
    ]), // Tidak ada di JSON
    'mna_sf': getFirstNonNull(skriningGizi, ['skor', 'mna_sf']),
    'lingkar_betis': getFirstNonNull(skriningGizi, [
      'lingkar_betis',
    ]), // Tidak ada di JSON
    'kategori_gizi': getFirstNonNull(skriningGizi, ['kategori']),

    // 9. SKRINING RISIKO JATUH (Sesuai JSON)
    'skala_morse': getFirstNonNull(skriningJatuh, ['skor', 'skala_morse']),
    'riwayat_jatuh': getFirstNonNull(skriningJatuh, [
      'riwayat_jatuh_1_tahun',
      'riwayat_jatuh',
    ]),
    'orientasi': getFirstNonNull(skriningJatuh, [
      'orientasi',
    ]), // Tidak ada di JSON
    'alat_bantu_jalan': getFirstNonNull(skriningJatuh, [
      'penggunaan_alat_bantu',
      'alat_bantu_jalan',
    ]),
    'infus': getFirstNonNull(skriningJatuh, [
      'terpasang_infus',
      'infus',
    ]), // Tidak ada di JSON
    'kategori_jatuh': getFirstNonNull(skriningJatuh, ['kategori']),

    // 10. STATUS PSIKOSOSIAL (Sesuai JSON)
    'komposisi_keluarga': getFirstNonNull(psikososial, [
      'komposisi_keluarga',
    ]), // Tidak ada di JSON
    'bahasa_sehari_hari': getFirstNonNull(psikososial, ['bahasa_sehari_hari']),
    'komunikasi': getFirstNonNull(psikososial, [
      'status_komunikasi',
      'komunikasi',
    ]),
    'kondisi_emosional': getFirstNonNull(psikososial, [
      'status_emosional',
      'kondisi_emosional',
    ]),
    'dukungan_keluarga': getFirstNonNull(psikososial, [
      'dukungan_keluarga',
    ]), // Tidak ada di JSON
    'riwayat_gangguan_jiwa': getFirstNonNull(psikososial, [
      'gangguan_jiwa',
      'riwayat_gangguan_jiwa',
    ]),
    'agama': getFirstNonNull(psikososial, [
      'spiritual',
      'agama',
    ]), // Tidak ada di JSON
    'kebutuhan_spiritual': getFirstNonNull(psikososial, [
      'kebutuhan_ibadah',
      'kebutuhan_spiritual',
    ]),
    'status_ekonomi': getFirstNonNull(kondisiSosial, [
      'ekonomi',
      'status_ekonomi',
    ]),
    'pendidikan': getFirstNonNull(kondisiSosial, ['pendidikan', 'pendidikan']),
    'pemahaman_perawatan': getFirstNonNull(psikososial, [
      'pemahaman_rencana_perawatan',
    ]),

    // 11. RENCANA PERAWATAN (Sesuai JSON)
    'observasi': getFirstNonNull(rencana, ['observasi']), // Tidak ada di JSON
    'edukasi': getFirstNonNull(asesmen, ['edukasi']), // Ambil dari root
    'home_care': getFirstNonNull(rencana, ['home_care']),
    'rujukan': getFirstNonNull(rencana, ['rujukan']), // Gunakan rujukan tunggal
    // 12. MASALAH KEPERAWATAN (Sesuai JSON)
    'masalah_keperawatan_list': getFirstNonNull(asesmen, [
      'masalah_keperawatan',
    ]), // Ambil array dari root
    'diagnosa_utama': getFirstNonNull(masalah, ['utama']), // Tidak ada di JSON
    'risiko': getFirstNonNull(masalah, ['risiko']), // Tidak ada di JSON
    // 13. TANDA TANGAN & ADMINISTRASI (Sesuai JSON)
    'lokasi_asesmen':
        getFirstNonNull(ttd, ['lokasi_asesmen']) ??
        getFirstNonNull(asesmen, ['lokasi_asesmen']),
    'tanggal_asesmen':
        getFirstNonNull(ttd, ['tanggal_asesmen']) ??
        getFirstNonNull(asesmen, ['tanggal_asesmen']),
    'perawat_pengassesmen':
        getFirstNonNull(ttd, ['perawat_asesmen']) ??
        getFirstNonNull(asesmen, ['perawat']), // Ambil dari root
    'ttd_perawat': getFirstNonNull(ttd, ['ttd_perawat_asesmen']),
    'perawat_penanggung_jawab': getFirstNonNull(ttd, [
      'perawat_penanggung_jawab',
    ]),
    'ttd_dokter': getFirstNonNull(ttd, ['ttd_perawat_penanggung_jawab']),
  };
}

dynamic getPendampingValue(dynamic pendamping, String key) {
  if (pendamping is Map) {
    return pendamping[key]?.toString();
  } else if (pendamping is String && key == 'nama') {
    return pendamping;
  }
  return null;
}
