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

void logApiResponse(Map<String, dynamic>? apiResponse, {String tag = 'API Response (pretty)'}) {
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
      pretty = 'Status: $status\n\n${const JsonEncoder.withIndent('  ').convert(body)}';
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
  final asesmenAwalKeperawatan = getCaseInsensitive(parsed, 'asesmen_awal_keperawatan');
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

Map<String, dynamic>? extractAssessmentObject(Map<String, dynamic>? apiResponse) {
  if (apiResponse == null) return null;

  final candidate = apiResponse['data'] ??
      apiResponse['body'] ??
      apiResponse;

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
      final normalized = normalizeParsedMap(Map<String, dynamic>.from(candidate));
      
      if (normalized != null) {
        if (normalized.keys.any((k) => k.toLowerCase().contains('informasi_umum') || k.toLowerCase().contains('keluhan_utama'))) {
          return normalized;
        }
      }

      // Kasus: objek asesmen ada di key spesifik "asesmen_awal_keperawatan" di level root map
      if (candidate.containsKey('asesmen_awal_keperawatan') && candidate['asesmen_awal_keperawatan'] is Map<String, dynamic>) {
        debugPrint('Menemukan root di key: asesmen_awal_keperawatan');
        return Map<String, dynamic>.from(candidate['asesmen_awal_keperawatan'] as Map);
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
           if (dataValue.containsKey('asesmen_awal_keperawatan') && dataValue['asesmen_awal_keperawatan'] is Map<String, dynamic>) {
              debugPrint('Menemukan root di key data.asesmen_awal_keperawatan');
              return Map<String, dynamic>.from(dataValue['asesmen_awal_keperawatan'] as Map);
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

Map<String, dynamic> extractSubMap(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = getCaseInsensitive(source, key);
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
  }
  return <String, dynamic>{};
}

Map<String, dynamic> extractFieldsFromAssessment(Map<String, dynamic>? asesmen) {
  if (asesmen == null) return {};

  final informasiUmum = extractSubMap(asesmen, ['informasi_umum', 'informasi']);
  final kunjungan = extractSubMap(asesmen, ['kunjungan', 'data_kunjungan']);
  final riwayatPenyakit = extractSubMap(asesmen, ['riwayat_penyakit', 'riwayat_kesehatan']);
  final statusUmum = extractSubMap(asesmen, ['status_umum']);
  final tandaVital = <String, dynamic>{};
  final dynamic tandaVitalRaw = getCaseInsensitive(statusUmum, 'tanda_vital');
  if (tandaVitalRaw is Map<String, dynamic>) {
    tandaVital.addAll(tandaVitalRaw);
  } else {
    tandaVital.addAll(extractSubMap(asesmen, ['tanda_vital']));
  }
  final pemeriksaanFisik = extractSubMap(asesmen, ['pemeriksaan_fisik', 'pemeriksaan_sistem']);
  final alergiMap = extractSubMap(asesmen, ['alergi']);
  final asesmenNyeri = extractSubMap(asesmen, ['asesmen_nyeri']);
  final skriningGizi = extractSubMap(asesmen, ['skrining_gizi']);
  final skriningJatuh = extractSubMap(asesmen, ['skrining_risiko_jatuh']);
  final psikososial = extractSubMap(asesmen, ['status_psikososial']);
  final rencana = extractSubMap(asesmen, ['rencana_perawatan']);
  final masalah = extractSubMap(asesmen, ['masalah_keperawatan']);
  final administrasi = extractSubMap(asesmen, ['administrasi']);

  final pendampingRaw = getFirstNonNull(kunjungan, ['pendamping']) ?? getFirstNonNull(informasiUmum, ['pendamping', 'nama_pendamping']);

  return buildExtractedFieldsMap(
    asesmen: asesmen,
    informasiUmum: informasiUmum,
    kunjungan: kunjungan,
    pendamping: {'raw': pendampingRaw},
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
  );
}

Map<String, dynamic> buildExtractedFieldsMap({
  required Map<String, dynamic> asesmen,
  required Map<String, dynamic> informasiUmum,
  required Map<String, dynamic> kunjungan,
  required Map<String, dynamic> pendamping,
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
}) {
  final pendampingRaw = pendamping['raw'];
  final pendampingNama = pendampingRaw is String ? pendampingRaw : getFirstNonNull(pendamping, ['nama']);

  final alergiObat = getFirstNonNull(alergiMap, ['obat', 'alergi_obat']);
  final alergiMakanan = getFirstNonNull(alergiMap, ['makanan', 'alergi_makanan']);
  String alergiCombined = '-';
  if (alergiObat != null && alergiMakanan != null) {
    alergiCombined = '${alergiObat.toString()} / ${alergiMakanan.toString()}';
  } else if (alergiObat != null) {
    alergiCombined = alergiObat.toString();
  } else if (alergiMakanan != null) {
    alergiCombined = alergiMakanan.toString();
  }

  return {
    // 1. INFORMASI UMUM (sesuai JSON)
    'no_rm': getFirstNonNull(informasiUmum, ['no_rm', 'no_rekam_medis']),
    'kode_rm': getFirstNonNull(informasiUmum, ['kode_rm']),
    'nama_pasien': getFirstNonNull(informasiUmum, ['nama_pasien', 'nama', 'name', 'name_patient']),
    'jenis_kelamin': getFirstNonNull(informasiUmum, ['jenis_kelamin']),
    'tanggal_lahir': getFirstNonNull(informasiUmum, ['tanggal_lahir']),
    'usia': getFirstNonNull(informasiUmum, ['umur', 'usia']),
    'alamat': getFirstNonNull(informasiUmum, ['alamat']),
    'pekerjaan': getFirstNonNull(informasiUmum, ['pekerjaan']),
    'status_perkawinan': getFirstNonNull(informasiUmum, ['status_perkawinan']),
    'penanggung_jawab': getFirstNonNull(informasiUmum, ['penanggung_jawab']),
    'hubungan_penanggung_jawab': getFirstNonNull(informasiUmum, ['hubungan_penanggung_jawab']),
    'kontak_penanggung_jawab': getFirstNonNull(informasiUmum, ['kontak_penanggung_jawab']),
    'agama': getFirstNonNull(informasiUmum, ['agama']),

    // 2. KUNJUNGAN (dari kunjungan)
    'tanggal_masuk': getFirstNonNull(kunjungan, ['tanggal_masuk']) ?? getFirstNonNull(asesmen, ['tanggal_masuk']),
    'jam_masuk': getFirstNonNull(kunjungan, ['waktu_masuk', 'jam_masuk']),
    'poli': getFirstNonNull(kunjungan, ['poli']),
    'kelas': getFirstNonNull(kunjungan, ['kelas']),
    'sumber_data': getFirstNonNull(kunjungan, ['sumber_data']),
    'rujukan': getFirstNonNull(kunjungan, ['rujukan']),
    'cara_masuk': getFirstNonNull(kunjungan, ['cara_masuk']),
    'pendamping_raw': pendampingRaw,

    // PENDAMPING (map untuk UI)
    'pendamping': {
      'raw': pendampingRaw,
      'nama': pendampingNama,
      'hubungan': getFirstNonNull(kunjungan, ['hubungan_pendamping', 'hubungan']),
      'usia': getFirstNonNull(kunjungan, ['usia_pendamping']),
      'kondisi': getFirstNonNull(kunjungan, ['kondisi_pendamping']),
    },

    // 3. KELUHAN UTAMA
    'keluhan_utama': getFirstNonNull(asesmen, ['keluhan_utama']) ?? getFirstNonNull(keluhanUtamaMap, ['keluhan']),
    'durasi_keluhan': getFirstNonNull(keluhanUtamaMap, ['durasi', 'lama_keluhan']),

    // 4. RIWAYAT PENYAKIT (sesuai JSON riwayat_penyakit)
    'riwayat_penyakit_sekarang': cleanAndFormatText(getFirstNonNull(riwayatMap, ['riwayat_sekarang', 'sekarang'])?.toString()),
    'riwayat_penyakit_dahulu': cleanAndFormatText(getFirstNonNull(riwayatMap, ['riwayat_dahulu', 'dahulu', 'riwayat_penyakit_dahulu'])?.toString()),
    'riwayat_operasi': cleanAndFormatText(getFirstNonNull(riwayatMap, ['riwayat_operasi'])?.toString()),
    'riwayat_transfusi': cleanAndFormatText(getFirstNonNull(riwayatMap, ['riwayat_transfusi_darah'])?.toString()),
    'golongan_darah': getFirstNonNull(riwayatMap, ['golongan_darah', 'gol_darah', 'goldar']),

    // Alergi (gabungan obat & makanan)
    'alergi': alergiCombined,
    'gelang_alergi': getFirstNonNull(alergiMap, ['gelang_alergi']),

    // 5. STATUS GENERAL & TANDA VITAL
    'kesadaran': getFirstNonNull(statusKesadaran, ['kesadaran']),
    'gcs': getFirstNonNull(statusKesadaran, ['gcs']),
    'keadaan_umum': getFirstNonNull(statusKesadaran, ['keadaan_umum', 'keadaan']),
    // Tanda vital (sesuai field JSON contoh)
    'berat_badan': getFirstNonNull(statusGeneral, ['berat_badan_kg', 'berat_badan']),
    'tekanan_darah': getFirstNonNull(statusGeneral, ['tekanan_darah_mmHg', 'tekanan_darah', 'td']),
    'nadi': getFirstNonNull(statusGeneral, ['nadi_per_menit', 'nadi']),
    'respirasi': getFirstNonNull(statusGeneral, ['respirasi_per_menit', 'respirasi', 'rr']),
    'suhu': getFirstNonNull(statusGeneral, ['suhu_tubuh_c', 'suhu_tubuh', 'suhu']),

    // 6. PEMERIKSAAN FISIK
    'kepala': getFirstNonNull(pemeriksaanFisik, ['kepala']),
    'mata': getFirstNonNull(pemeriksaanFisik, ['mata']),
    'tht': getFirstNonNull(pemeriksaanFisik, ['tht']),
    'mulut': getFirstNonNull(pemeriksaanFisik, ['mukosa_mulut', 'mulut']),
    'leher': getFirstNonNull(pemeriksaanFisik, ['leher']),
    'thoraks': getFirstNonNull(pemeriksaanFisik, ['thoraks']),
    'jantung': getFirstNonNull(pemeriksaanFisik, ['jantung']),
    'abdomen': getFirstNonNull(pemeriksaanFisik, ['abdomen']),
    'urogenital': getFirstNonNull(pemeriksaanFisik, ['urogenital']),
    'ekstremitas': getFirstNonNull(pemeriksaanFisik, ['ekstremitas']),
    'kulit': getFirstNonNull(pemeriksaanFisik, ['kulit']),

    // 7. ASESMEN NYERI (mapping sesuai JSON)
    'jenis_nyeri': getFirstNonNull(asesmenNyeri, ['jenis']),
    'karakter_nyeri': getFirstNonNull(asesmenNyeri, ['karakter']),
    'lokasi_nyeri': getFirstNonNull(asesmenNyeri, ['lokasi']),
    'penjalaran_nyeri': getFirstNonNull(asesmenNyeri, ['penjalaran']), // mungkin null di contoh
    'intensitas_nyeri': getFirstNonNull(asesmenNyeri, ['intensitas']),
    'durasi_nyeri': getFirstNonNull(asesmenNyeri, ['durasi']),
    'faktor_pencetus_nyeri': getFirstNonNull(asesmenNyeri, ['faktor_pemicu', 'penyebab_pemicu', 'faktor_pencetus']),
    'faktor_pereda_nyeri': getFirstNonNull(asesmenNyeri, ['faktor_pereda']),
    'rekomendasi_nyeri': getFirstNonNull(asesmenNyeri, ['rekomendasi']),

    // 8. SKRINING GIZI
    'penurunan_berat_badan': getFirstNonNull(skriningGizi, ['penurunan_berat_badan']),
    'asupan_makanan': getFirstNonNull(skriningGizi, ['asupan_makanan']),
    'mna_sf': getFirstNonNull(skriningGizi, ['mna_sf']),
    'lingkar_betis': getFirstNonNull(skriningGizi, ['lingkar_betis_cm', 'lingkar_betis']),

    // 9. SKRINING RISIKO JATUH (mapping sesuai JSON)
    'skala_morse': getFirstNonNull(skriningJatuh, ['morse', 'skala_morse']),
    'riwayat_jatuh': getFirstNonNull(skriningJatuh, ['riwayat_jatuh']),
    'orientasi': getFirstNonNull(skriningJatuh, ['orientasi']),
    'alat_bantu_jalan': getFirstNonNull(skriningJatuh, ['alat_bantu_jalan']),
    'infus': getFirstNonNull(skriningJatuh, ['terpasang_infus', 'infus']),

    // 10. STATUS PSIKOSOSIAL
    'komposisi_keluarga': getFirstNonNull(psikososial, ['tinggal_dengan', 'komposisi_keluarga']),
    'komunikasi': getFirstNonNull(psikososial, ['komunikasi']),
    'kondisi_emosional': getFirstNonNull(psikososial, ['kondisi_emosional']),
    'dukungan_keluarga': getFirstNonNull(psikososial, ['dukungan_keluarga']),
    'riwayat_gangguan_jiwa': getFirstNonNull(psikososial, ['riwayat_gangguan_jiwa']),
    'agama': getFirstNonNull(psikososial, ['spiritual', 'agama']),
    'kebutuhan_spiritual': getFirstNonNull(psikososial, ['spiritual']),
    'status_ekonomi': getFirstNonNull(psikososial, ['ekonomi']),
    'pendidikan': getFirstNonNull(psikososial, ['pendidikan']),

    // 11. RENCANA PERAWATAN
    'observasi': getFirstNonNull(rencana, ['observasi']),
    'edukasi': getFirstNonNull(rencana, ['edukasi']),
    'home_care': getFirstNonNull(rencana, ['home_care']),
    'rujukan_gizi': getFirstNonNull(rencana, ['rujukan_gizi']),
    'rujukan_terapi': getFirstNonNull(rencana, ['rujukan_terapi']),
    'anjuran_kembali': getFirstNonNull(rencana, ['anjuran_kembali', 'anjuran_kontrol']),

    // 12. MASALAH KEPERAWATAN
    'diagnosa_utama': getFirstNonNull(masalah, ['utama']),
    'risiko': getFirstNonNull(masalah, ['risiko']),
    'intervensi': getFirstNonNull(masalah, ['intervensi']),

    // 13. TANDA TANGAN & ADMINISTRASI (sesuai administrasi di JSON)
    'lokasi_asesmen': getFirstNonNull(ttd, ['lokasi_asesmen']) ?? getFirstNonNull(asesmen, ['lokasi_asesmen']),
    'tanggal_asesmen': getFirstNonNull(ttd, ['tanggal_asesmen']) ?? getFirstNonNull(asesmen, ['tanggal_asesmen']),
    'perawat_pengassesmen': getFirstNonNull(ttd, ['perawat_asesmen']),
    'ttd_perawat': getFirstNonNull(ttd, ['ttd_perawat_asesmen']),
    'perawat_penanggung_jawab': getFirstNonNull(ttd, ['perawat_penanggung_jawab']),
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