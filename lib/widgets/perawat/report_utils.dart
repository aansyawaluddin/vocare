import 'dart:convert';
import 'package:flutter/foundation.dart';

// HELPER: DEBUG & LOGGING

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

// HELPER: PARSING / NORMALIZING JSON

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

String? cleanAndFormatText(String? text) {
  if (text == null || text.trim().isEmpty || text.toLowerCase() == 'null') {
    return null; // Diubah dari '-' menjadi null
  }

  return text
      .replaceAll(RegExp(r'riwayat_\w+:\s*', multiLine: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^,\s*'), '')
      .replaceAll(RegExp(r',\s*$'), '')
      .trim();
}

// LOGIC: EKSTRAKSI DATA DARI JSON

/// Extract fields dari object asesmen (memakai fallback dan parsing rencana_asuhan)
Map<String, dynamic> extractFieldsFromAssessment(
  Map<String, dynamic>? asesmen,
) {
  if (asesmen == null) return {};

  final informasiUmum = extractSubMap(asesmen, ['informasi_umum', 'informasi']);
  final kunjungan = extractSubMap(asesmen, ['kunjungan', 'data_kunjungan']);

  // Perbaikan: Arahkan 'riwayatMap' ke 'informasi_tambahan' sesuai JSON
  final riwayatMap = extractSubMap(asesmen, [
    'informasi_tambahan',
    'riwayat_kesehatan',
    'pemeriksaan_sistem',
  ]);

  final pemeriksaanFisik = extractSubMap(asesmen, ['pemeriksaan_fisik']);

  // Perbaikan: Ekstrak Tanda Vital dari dalam 'pemeriksaan_fisik'
  final tandaVital = <String, dynamic>{};
  final dynamic tandaVitalRaw = getCaseInsensitive(
    pemeriksaanFisik,
    'tanda_vital',
  );
  if (tandaVitalRaw is Map<String, dynamic>) {
    tandaVital.addAll(tandaVitalRaw);
  } else {
    // Fallback ke logika lama jika tidak ditemukan
    final statusUmum = extractSubMap(asesmen, ['status_umum']);
    final dynamic tandaVitalRaw2 = getCaseInsensitive(
      statusUmum,
      'tanda_vital',
    );
    if (tandaVitalRaw2 is Map<String, dynamic>) {
      tandaVital.addAll(tandaVitalRaw2);
    } else {
      tandaVital.addAll(extractSubMap(asesmen, ['tanda_vital']));
    }
  }

  // Ekstrak Tanda Vital dari status_umum (jika ada, sebagai fallback)
  final statusUmum = extractSubMap(asesmen, ['status_umum']);

  final alergiMap = extractSubMap(asesmen, ['alergi']);
  final asesmenNyeri = extractSubMap(asesmen, ['asesmen_nyeri']);
  final skriningGizi = extractSubMap(asesmen, ['skrining_gizi']);
  final skriningJatuh = extractSubMap(asesmen, ['skrining_risiko_jatuh']);
  final psikososial = extractSubMap(asesmen, ['status_psikososial']);
  final administrasi = extractSubMap(asesmen, ['administrasi']);

  // Perbaikan: Ekstrak objek 'edukasi' dan 'rencana_asuhan_keperawatan'
  final edukasiMap = extractSubMap(asesmen, ['edukasi']);
  final rencanaPerawatanMap = extractSubMap(asesmen, ['rencana_perawatan']);
  final rencanaAsuhanString = getFirstNonNull(rencanaPerawatanMap, [
    'rencana_asuhan_keperawatan',
  ])?.toString();

  // // Ambil string 'rencana' dari dalam 'rencana_asuhan_keperawatan'
  // final rencanaAsuhanRaw = getFirstNonNull(rencanaAsuhanMap, ['rencana']);

  // Normalize rencana_asuhan menjadi List<String>
  // List<String> rencanaAsuhanList = [];
  // if (rencanaAsuhanRaw is List) {
  //  ... (logika list dikomentari)
  // }

  return buildExtractedFieldsMap(
    asesmen: asesmen,
    informasiUmum: informasiUmum,
    kunjungan: kunjungan,
    keluhanUtamaMap: extractSubMap(asesmen, ['keluhan_utama']),
    riwayatMap: riwayatMap, // Ini sekarang adalah 'informasi_tambahan'
    alergiMap: alergiMap,
    statusGeneral: tandaVital,
    statusKesadaran: pemeriksaanFisik, // 'kesadaran' ada di 'pemeriksaan_fisik'
    pemeriksaanFisik: pemeriksaanFisik,
    asesmenNyeri: asesmenNyeri,
    skriningGizi: skriningGizi,
    skriningJatuh: skriningJatuh,
    psikososial: psikososial,
    // rencana: rencanaAsuhanMap, // Menggunakan ini untuk 'rencana_keterangan'
    rencana: extractSubMap(asesmen, [
      'rencana_asuhan_keperawatan',
    ]), // Fallback, meski rencana_perawatan lebih spesifik
    masalah: extractSubMap(asesmen, ['masalah_keperawatan']),
    ttd: administrasi,
    rencana_asuhan: rencanaAsuhanString,
    edukasi: edukasiMap, // Mengirim map edukasi
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
  required String? rencana_asuhan,
  required Map<String, dynamic> edukasi, // Tambahkan ini
}) {
  // Perbaikan: Ambil alergi dari 'riwayatMap' (informasi_tambahan)
  final alergiRaw =
      getFirstNonNull(asesmen, ['alergi']) ??
      getFirstNonNull(riwayatMap, ['alergi']) ?? // Ditambahkan
      getFirstNonNull(alergiMap, ['obat', 'makanan', 'alergi']);
  
  // Perbaikan: Tipe diubah menjadi String? dan hapus ?? '-'
  final String? alergiCombined =
      cleanAndFormatText(alergiRaw?.toString());

  final kondisiSosialRaw = getCaseInsensitive(psikososial, 'kondisi_sosial');
  final Map<String, dynamic> kondisiSosial =
      kondisiSosialRaw is Map<String, dynamic> ? kondisiSosialRaw : {};

  final pfKeys = {
    'kepala': getFirstNonNull(pemeriksaanFisik, [
      'head_eyes_ears_nose_throat',
      'kepala',
      'kepala_dan_mata',
    ]), // Ditambahkan
    'mata': getFirstNonNull(pemeriksaanFisik, ['mata']),
    'tht': getFirstNonNull(pemeriksaanFisik, ['tht']),
    'mulut': getFirstNonNull(pemeriksaanFisik, ['mulut']),
    'leher': getFirstNonNull(pemeriksaanFisik, ['leher']),
    'thoraks': getFirstNonNull(pemeriksaanFisik, [
      'thorak_dan_payudara', // Diganti
      'thoraks',
    ]),
    'jantung': getFirstNonNull(pemeriksaanFisik, ['jantung']),
    'abdomen': getFirstNonNull(pemeriksaanFisik, ['abdomen']),
    'urogenital': getFirstNonNull(pemeriksaanFisik, ['urogenital']),
    'ekstremitas': getFirstNonNull(pemeriksaanFisik, ['ekstremitas']),
    'kulit': getFirstNonNull(pemeriksaanFisik, [
      'integumen',
      'kulit',
    ]), // Ditambahkan
  };

  return {
    // INFORMASI UMUM
    'no_rm': getFirstNonNull(informasiUmum, [
      'nomor_rekam_medis',
      'no_rekam_medis',
      'no_rm',
      'nomor_identitas',
      'no_identitas',
    ]),
    'nama_pasien': getFirstNonNull(informasiUmum, [
      'nama', // Dipindahkan ke atas
      'nama_lengkap',
      'nama_pasien',
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
      'tanggal', // Ditambahkan
      'tanggal_kunjungan',
      'tanggal_masuk',
    ]),
    'waktu_masuk': getFirstNonNull(kunjungan, [
      'waktu', // Ditambahkan
      'jam_kunjungan',
      'jam_masuk',
      'waktu_masuk',
      'waktu_kunjungan',
    ]),
    'poli': getFirstNonNull(kunjungan, [
      'ruang', // Ditambahkan
      'tujuan_poli',
      'tujuan',
      'poli',
      'poliklinik_tujuan',
    ]),
    'pelayanan': getFirstNonNull(kunjungan, [
      'pelayanan',
      'kelas',
      'pelayanan_digunakan',
      'kelas_pelayanan',
      'tempat',
    ]),
    'pendamping': getFirstNonNull(kunjungan, [
      'dengan_siapa',
      'pendamping',
    ]), // Ditambahkan
    'sumber_data': getFirstNonNull(kunjungan, [
      'sumber_informasi', // Ditambahkan
      'sumber_data_anamnesa',
      'sumber_data',
    ]),
    'rujukan': getFirstNonNull(kunjungan, ['rujukan', 'asal_rujukan']),
    'cara_masuk': getFirstNonNull(kunjungan, ['cara_masuk', 'sarana_masuk']),

    // KELUHAN UTAMA
    'keluhan_utama':
        getFirstNonNull(asesmen, ['keluhan_utama']) ??
        getFirstNonNull(keluhanUtamaMap, ['keluhan']),
    'durasi_keluhan': getFirstNonNull(keluhanUtamaMap, [
      'durasi',
      'lama_keluhan',
    ]),

    // Alergi
    'alergi': alergiCombined, // Sekarang bisa null
    'gelang_alergi': getFirstNonNull(alergiMap, ['gelang_alergi']),

    // STATUS & TANDA VITAL
    'kesadaran': getFirstNonNull(statusKesadaran, [
      // Diambil dari pemeriksaanFisik
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
    // 'keterangan_nyeri': getFirstNonNull(asesmenNyeri, ['keterangan']), // Dihapus
    'faktor_pencetus_nyeri': getFirstNonNull(asesmenNyeri, [
      'pencetus', // Sesuai JSON baru
      'pemicu',
      'faktor_pemicu',
    ]),
    'faktor_penghilang_nyeri': getFirstNonNull(asesmenNyeri, [
      'penghilang', // Sesuai JSON baru
      'faktor_penghilang',
    ]),
    'skala': getFirstNonNull(asesmenNyeri, [
      'skala', // Sesuai JSON baru
      'skala_nyeri',
    ]),

    // SKRINING GIZI
    'skor_gizi': getFirstNonNull(skriningGizi, [
      'skor_screening',
      'skor',
      'skor_gizi',
    ]), // Ditambahkan
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
    'skala_morse': getFirstNonNull(skriningJatuh, [
      'skor',
      'skala_morse',
      'skrining_risiko_jatuh',
    ]),
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
    'kategori_jatuh': getFirstNonNull(skriningJatuh, [
      'keterangan',
      'kategori',
    ]), // Ditambahkan
    // PSIKOSOSIAL
    'komposisi_keluarga': getFirstNonNull(psikososial, ['komposisi_keluarga']),
    'bahasa_sehari_hari': getFirstNonNull(psikososial, [
      'bahasa', // Prioritas baru
      'bahasa_sehari_hari',
    ]),
    'komunikasi': getFirstNonNull(psikososial, [
      'komunikasi',
      'status_komunikasi',
    ]),
    'kondisi_emosional': getFirstNonNull(psikososial, [
      'status_emosional', // Prioritas baru
      'status_emosi',
      'kondisi_emosional',
    ]),
    'dukungan_keluarga': getFirstNonNull(psikososial, ['dukungan_keluarga']),
    'riwayat_gangguan_jiwa': getFirstNonNull(psikososial, [
      'gangguan_jiwa',
      'riwayat_gangguan_jiwa',
    ]),
    'kebutuhan_spiritual': getFirstNonNull(psikososial, [
      'kebutuhan_ibadah', // Prioritas baru
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
      'pemahaman',
      'pemahaman_perawatan', // Prioritas baru
    ]),

    // RENCANA PERAWATAN (Bagian 11)
    'edukasi_topik': getFirstNonNull(edukasi, ['topik']), // Ditambahkan
    'edukasi_keterangan': getFirstNonNull(edukasi, [
       'keterangan',
    ]), // Ditambahkan
    'home_care': getFirstNonNull(rencana, ['home_care']),
    'rencana_keterangan': getFirstNonNull(rencana, [
       'keterangan',
    ]), // Ditambahkan (untuk rujukan)

    // MASALAH KEPERAWATAN
    'masalah_keperawatan_list': getFirstNonNull(asesmen, [
      'masalah_keperawatan',
    ]),
    // 'diagnosa_utama': getFirstNonNull(masalah, ['utama']),
    // 'risiko': getFirstNonNull(masalah, ['risiko']),

    // ADMINISTRASI
    // 'lokasi_asesmen': ... (dikomentari di kode Anda)
    // 'tanggal_asesmen': ...
    // 'perawat_pengassesmen': ...
    // 'ttd_perawat': ...
    // 'perawat_penanggung_jawab': ...
    // 'ttd_dokter': ...

    // RENCANA ASUHAN STRING
    'rencana_asuhan_string': cleanAndFormatText(rencana_asuhan),

    // 'rencana_asuhan_list': ... (dikomentari di kode Anda)
  };
}