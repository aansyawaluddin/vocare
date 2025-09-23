
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
    if (candidate is String) {
      final cleaned = stripCodeFences(candidate);
      final parsed = jsonDecode(cleaned);
      if (parsed is Map<String, dynamic>) {
        return normalizeParsedMap(parsed);
      }
    }

    if (candidate is Map) {
      if (candidate.containsKey('data') && candidate['data'] is String) {
        try {
          final cleaned = stripCodeFences(candidate['data'] as String);
          final parsed = jsonDecode(cleaned);
          if (parsed is Map<String, dynamic>) {
            return normalizeParsedMap(parsed);
          }
        } catch (_) {
          // Ignore parsing errors
        }
      }

      if (candidate['data'] is Map) {
        final inner = candidate['data'] as Map;
        if (inner.containsKey('data') && inner['data'] is String) {
          try {
            final cleaned = stripCodeFences(inner['data'] as String);
            final parsed = jsonDecode(cleaned);
            if (parsed is Map<String, dynamic>) {
              return normalizeParsedMap(parsed);
            }
          } catch (_) {
            // Ignore parsing errors
          }
        }
        return normalizeParsedMap(Map<String, dynamic>.from(inner));
      }
      return normalizeParsedMap(Map<String, dynamic>.from(candidate));
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

  Map<String, String> result = {};
  
  final patterns = {
    'riwayat_penyakit_sekarang': RegExp(r'(.+?)(?=,?\s*riwayat_penyakit_dahulu:|,?\s*riwayat_operasi:|,?\s*riwayat_transfusi|,?\s*riwayat_alergi|,?\s*gelang_alergi|$)', dotAll: true),
    'riwayat_penyakit_dahulu': RegExp(r'riwayat_penyakit_dahulu:\s*(.*?)(?=,?\s*riwayat_operasi:|,?\s*riwayat_transfusi|,?\s*riwayat_alergi|,?\s*gelang_alergi|$)', dotAll: true),
    'riwayat_operasi': RegExp(r'riwayat_operasi:\s*(.*?)(?=,?\s*riwayat_transfusi|,?\s*riwayat_alergi|,?\s*gelang_alergi|$)', dotAll: true),
    'riwayat_transfusi_darah': RegExp(r'riwayat_transfusi_darah:\s*(.*?)(?=,?\s*riwayat_alergi|,?\s*gelang_alergi|$)', dotAll: true),
    'riwayat_alergi': RegExp(r'riwayat_alergi:\s*(.*?)(?=,?\s*gelang_alergi|$)', dotAll: true),
    'gelang_alergi': RegExp(r'gelang_alergi:\s*(.*?)$', dotAll: true),
  };

  for (final entry in patterns.entries) {
    final match = entry.value.firstMatch(rawText);
    if (match != null && match.group(1) != null) {
      String extractedText = match.group(1)!.trim();
      extractedText = extractedText.replaceAll(RegExp(r'^${entry.key}:\s*'), '');
      result[entry.key] = extractedText;
    }
  }

  if (result.isEmpty) {
    final parts = rawText.split(',');
    if (parts.isNotEmpty) {
      result['riwayat_penyakit_sekarang'] = parts.first.trim();
      
      for (int i = 1; i < parts.length; i++) {
        final part = parts[i].trim().toLowerCase();
        if (part.contains('tidak ada') && part.contains('operasi')) {
          result['riwayat_operasi'] = 'Tidak ada';
        } else if (part.contains('tidak ada') && part.contains('transfusi')) {
          result['riwayat_transfusi_darah'] = 'Tidak ada';
        } else if (part.contains('tidak ada') && part.contains('alergi')) {
          result['riwayat_alergi'] = 'Tidak ada alergi obat maupun makanan';
        }
      }
    }
  }

  return result;
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

Map<String, dynamic> extractFieldsFromAssessment(Map<String, dynamic>? asesmen) {
  if (asesmen == null) return {};

  final informasiUmum = extractSubMap(asesmen, ['informasi_umum', 'informasi']);
  final keluhanUtamaMap = extractSubMap(asesmen, ['keluhan_utama']);
  final riwayatMap = extractSubMap(asesmen, ['riwayat_kesehatan']);
  final statusGeneral = extractSubMap(asesmen, ['status_general']);
  final pemeriksaanFisik = extractSubMap(asesmen, ['pemeriksaan_fisik']);
  final asesmenNyeri = extractSubMap(asesmen, ['asesmen_nyeri']);
  final skriningGizi = extractSubMap(asesmen, ['skrining_gizi']);
  final skriningJatuh = extractSubMap(asesmen, ['skrining_risiko_jatuh']);
  final psikososial = extractSubMap(asesmen, ['status_psikososial']);
  final rencana = extractSubMap(asesmen, ['rencana_perawatan']);
  final masalah = extractSubMap(asesmen, ['masalah_keperawatan']);
  final ttd = extractSubMap(asesmen, ['ttd']);

  final riwayatRaw = getFirstNonNull(riwayatMap, ['riwayat_penyakit_sekarang', 'riwayat_penyakit', 'sekarang'])
      ?? getFirstNonNull(asesmen, ['riwayat_penyakit_sekarang', 'riwayat_penyakit']);
  
  final parsedRiwayat = parseMultipleInfo(riwayatRaw?.toString());

  return buildExtractedFieldsMap(
    asesmen: asesmen,
    informasiUmum: informasiUmum,
    keluhanUtamaMap: keluhanUtamaMap,
    riwayatMap: riwayatMap,
    parsedRiwayat: parsedRiwayat,
    statusGeneral: statusGeneral,
    pemeriksaanFisik: pemeriksaanFisik,
    asesmenNyeri: asesmenNyeri,
    skriningGizi: skriningGizi,
    skriningJatuh: skriningJatuh,
    psikososial: psikososial,
    rencana: rencana,
    masalah: masalah,
    ttd: ttd,
  );
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

Map<String, dynamic> buildExtractedFieldsMap({
  required Map<String, dynamic> asesmen,
  required Map<String, dynamic> informasiUmum,
  required Map<String, dynamic> keluhanUtamaMap,
  required Map<String, dynamic> riwayatMap,
  required Map<String, String> parsedRiwayat,
  required Map<String, dynamic> statusGeneral,
  required Map<String, dynamic> pemeriksaanFisik,
  required Map<String, dynamic> asesmenNyeri,
  required Map<String, dynamic> skriningGizi,
  required Map<String, dynamic> skriningJatuh,
  required Map<String, dynamic> psikososial,
  required Map<String, dynamic> rencana,
  required Map<String, dynamic> masalah,
  required Map<String, dynamic> ttd,
}) {
  final pendampingRaw = getFirstNonNull(informasiUmum, ['pendamping', 'nama_pendamping', 'pendamping_pasien']);
  Map<String, dynamic>? pendampingMap;
  
  if (pendampingRaw is Map) {
    pendampingMap = Map<String, dynamic>.from(pendampingRaw);
  }

  return {
    'no_rm': getFirstNonNull(informasiUmum, ['no_rm', 'no_rekam_medis', 'nomor_rm', 'no']),
    'kode_rm': getFirstNonNull(informasiUmum, ['kode_rm', 'kode_rekam_medis', 'kode']),
    'nama_pasien': getFirstNonNull(informasiUmum, ['nama_pasien', 'nama', 'nama_lengkap']),
    'jenis_kelamin': getFirstNonNull(informasiUmum, ['jenis_kelamin', 'gender', 'sex', 'jenis kelamin']),
    'tanggal_lahir': getFirstNonNull(informasiUmum, ['tanggal_lahir', 'ttl', 'tgl_lahir', 'tanggal lahir']),
    'usia': getFirstNonNull(informasiUmum, ['usia', 'umur', 'age']),
    'tanggal_masuk': getFirstNonNull(informasiUmum, ['tanggal_masuk', 'tgl_masuk', 'tanggal_masuk_pasien']),
    'jam_masuk': getFirstNonNull(informasiUmum, ['jam_masuk', 'waktu_masuk', 'jam']),
    'cara_masuk': getFirstNonNull(informasiUmum, ['cara_masuk', 'cara masuk', 'mode_masuk']),
    'rujukan': getFirstNonNull(informasiUmum, ['rujukan', 'rujukan_dari']),
    'kelas_perawatan': getFirstNonNull(informasiUmum, ['kelas_perawatan', 'kelas']),
    'sumber_data': getFirstNonNull(informasiUmum, ['sumber_data', 'sumber']),
    'alamat': getFirstNonNull(informasiUmum, ['alamat', 'address', 'alamat_pasien']),
    'pekerjaan': getFirstNonNull(informasiUmum, ['pekerjaan', 'pekerjaan_pasien', 'pekerjaan_terakhir']),
    'status_perkawinan': getFirstNonNull(informasiUmum, ['status_perkawinan', 'status', 'perkawinan']),
    'penanggung_jawab': getFirstNonNull(informasiUmum, ['penanggung_jawab', 'penanggungjawab', 'nama_penanggung_jawab']),
    'hubungan_penanggung_jawab': getFirstNonNull(informasiUmum, ['hubungan_penanggung_jawab', 'hubungan', 'hubungan_penanggung']),
    'kontak_penanggung_jawab': getFirstNonNull(informasiUmum, ['kontak_penanggung_jawab', 'kontak', 'telepon_penanggung_jawab', 'no_telp']),
    'agama': getFirstNonNull(informasiUmum, ['agama', 'religion']),
    
    'pendamping': {
      'raw': pendampingRaw,
      'nama': pendampingMap != null 
          ? getFirstNonNull(pendampingMap, ['nama', 'nama_pendamping', 'penanggung_jawab'])
          : (pendampingRaw is String ? pendampingRaw : null),
      'hubungan': pendampingMap != null
          ? getFirstNonNull(pendampingMap, ['hubungan', 'hubungan_penanggung_jawab', 'peran'])
          : getFirstNonNull(informasiUmum, ['hubungan_penanggung_jawab', 'hubungan']),
    },

    'keluhan_utama': getFirstNonNull(keluhanUtamaMap, ['keluhan', 'keluhan_utama', 'chief_complaint']) 
        ?? getFirstNonNull(asesmen, ['keluhan', 'keluhan_utama']),
    'durasi_keluhan': getFirstNonNull(keluhanUtamaMap, ['durasi', 'durasi_keluhan', 'lama_keluhan']),

    'riwayat_penyakit_sekarang': cleanAndFormatText(
      parsedRiwayat['riwayat_penyakit_sekarang'] ?? 
      getFirstNonNull(riwayatMap, ['riwayat_penyakit_sekarang', 'riwayat_penyakit', 'sekarang'])?.toString()
    ),
    'riwayat_penyakit_dahulu': cleanAndFormatText(
      parsedRiwayat['riwayat_penyakit_dahulu'] ?? 
      getFirstNonNull(riwayatMap, ['riwayat_penyakit_dahulu', 'riwayat_dahulu', 'riwayat'])?.toString()
    ),
    'riwayat_operasi': cleanAndFormatText(
      parsedRiwayat['riwayat_operasi'] ?? 
      getFirstNonNull(riwayatMap, ['riwayat_operasi', 'operasi'])?.toString()
    ),
    'riwayat_transfusi': cleanAndFormatText(
      parsedRiwayat['riwayat_transfusi_darah'] ?? 
      getFirstNonNull(riwayatMap, ['riwayat_transfusi_darah', 'riwayat_transfusi', 'transfusi'])?.toString()
    ),
    'pengobatan_teratur': getFirstNonNull(riwayatMap, ['pengobatan_teratur', 'obat_teratur', 'medikasi']),
    'alergi': cleanAndFormatText(
      parsedRiwayat['riwayat_alergi'] ?? 
      getFirstNonNull(riwayatMap, ['alergi', 'alergi_obat', 'alergi_makanan'])?.toString()
    ),

    'berat_badan': getNestedValue(statusGeneral, ['berat_badan']) 
        ?? getNestedValue(asesmen, ['status_general', 'tanda_vital', 'berat_badan'])
        ?? getFirstNonNull(asesmen, ['berat_badan', 'berat']),
    'tekanan_darah': getNestedValue(statusGeneral, ['tekanan_darah'])
        ?? getNestedValue(asesmen, ['status_general', 'tanda_vital', 'tekanan_darah'])
        ?? getFirstNonNull(asesmen, ['tekanan_darah', 'td']),
    'nadi': getNestedValue(statusGeneral, ['nadi'])
        ?? getNestedValue(asesmen, ['status_general', 'tanda_vital', 'nadi'])
        ?? getFirstNonNull(asesmen, ['nadi', 'denyut_nadi']),
    'respirasi': getNestedValue(statusGeneral, ['respirasi'])
        ?? getNestedValue(asesmen, ['status_general', 'tanda_vital', 'respirasi'])
        ?? getFirstNonNull(asesmen, ['respirasi', 'rr']),
    'suhu': getNestedValue(statusGeneral, ['suhu'])
        ?? getNestedValue(asesmen, ['status_general', 'tanda_vital', 'suhu'])
        ?? getFirstNonNull(asesmen, ['suhu', 'temperature']),
    'kesadaran': getFirstNonNull(statusGeneral, ['kesadaran', 'kesadaran_pasien'])
        ?? getFirstNonNull(asesmen, ['kesadaran'])
        ?? getNestedValue(statusGeneral, ['gcs']),
    'gcs': getFirstNonNull(statusGeneral, ['gcs', 'skor_gcs']) ?? getNestedValue(statusGeneral, ['gcs']),
    'keadaan_umum': getFirstNonNull(statusGeneral, ['keadaan_umum', 'keadaan', 'kondisi_umum']),
    'golongan_darah': getFirstNonNull(statusGeneral, ['golongan_darah', 'gol_darah', 'goldar']),

    'kepala': getFirstNonNull(pemeriksaanFisik, ['kepala', 'kepala_leher', 'kepala_dan_leher']),
    'mata': getFirstNonNull(pemeriksaanFisik, ['mata', 'okular', 'pupil']),
    'tht': getFirstNonNull(pemeriksaanFisik, ['tht', 'telinga_hidung_tenggorokan']),
    'mulut': getFirstNonNull(pemeriksaanFisik, ['mulut', 'mukosa', 'oral', 'mukosa_mulut']),
    'leher': getFirstNonNull(pemeriksaanFisik, ['leher', 'cervical']),
    'thoraks': getFirstNonNull(pemeriksaanFisik, ['thoraks', 'thorax', 'paru']),
    'jantung': getFirstNonNull(pemeriksaanFisik, ['jantung', 'cardiac', 'pemeriksaan_jantung']),
    'abdomen': getFirstNonNull(pemeriksaanFisik, ['abdomen', 'perut']),
    'urogenital': getFirstNonNull(pemeriksaanFisik, ['urogenital', 'genital', 'urin']),
    'ekstremitas': getFirstNonNull(pemeriksaanFisik, ['ekstremitas', 'extremitas', 'anggota_badan']),
    'kulit': getFirstNonNull(pemeriksaanFisik, ['kulit', 'derma', 'skin']),

    'jenis_nyeri': getFirstNonNull(asesmenNyeri, ['jenis', 'jenis_nyeri', 'ada_nyeri']),
    'karakter_nyeri': getFirstNonNull(asesmenNyeri, ['karakter', 'karakter_nyeri']),
    'lokasi_nyeri': getFirstNonNull(asesmenNyeri, ['lokasi', 'lokasi_nyeri']),
    'penjalaran_nyeri': getFirstNonNull(asesmenNyeri, ['penjalaran', 'menjalar', 'menjalar_ke']),
    'intensitas_nyeri': getFirstNonNull(asesmenNyeri, ['intensitas', 'skor', 'skala', 'nilai_nyeri']),
    'durasi_nyeri': getFirstNonNull(asesmenNyeri, ['durasi', 'lama', 'durasi_nyeri']),
    'faktor_pencetus_nyeri': getFirstNonNull(asesmenNyeri, ['faktor_pencetus', 'pencetus']),
    'faktor_pereda_nyeri': getFirstNonNull(asesmenNyeri, ['faktor_pereda', 'pereda']),

    'penurunan_berat_badan': getFirstNonNull(skriningGizi, ['penurunan_berat_badan', 'penurunan_berat']),
    'asupan_makanan': getFirstNonNull(skriningGizi, ['asupan_makanan', 'asupan']),
    'mna_sf': getFirstNonNull(skriningGizi, ['mna_sf', 'mna']),
    'lingkar_betis': getFirstNonNull(skriningGizi, ['lingkar_betis', 'tb_betis']),

    'skala_morse': getFirstNonNull(skriningJatuh, ['skala_morse', 'morse', 'skor_morse']),
    'riwayat_jatuh': getFirstNonNull(skriningJatuh, ['riwayat_jatuh', 'jatuh']),
    'orientasi': getFirstNonNull(skriningJatuh, ['orientasi', 'orientasi_pasien']),
    'alat_bantu_jalan': getFirstNonNull(skriningJatuh, ['alat_bantu_jalan', 'walker', 'tongkat']),
    'infus': getFirstNonNull(skriningJatuh, ['infus', 'ada_infus']),

    'komposisi_keluarga': getFirstNonNull(psikososial, ['komposisi_keluarga', 'komposisi']),
    'komunikasi': getFirstNonNull(psikososial, ['komunikasi', 'komunikasi_pasien']),
    'kondisi_emosional': getFirstNonNull(psikososial, ['kondisi_emosional', 'emosi', 'emosional']),
    'dukungan_keluarga': getFirstNonNull(psikososial, ['dukungan_keluarga', 'dukungan']),
    'riwayat_gangguan_jiwa': getFirstNonNull(psikososial, ['riwayat_gangguan_jiwa', 'gangguan_jiwa']),
    'kebutuhan_spiritual': getFirstNonNull(psikososial, ['kebutuhan_spiritual', 'spiritual']),
    'status_ekonomi': getFirstNonNull(psikososial, ['status_ekonomi', 'ekonomi']),
    'pendidikan': getFirstNonNull(psikososial, ['pendidikan', 'pendidikan_terakhir']),

    'observasi': getFirstNonNull(rencana, ['observasi', 'lama_observasi', 'observasi_hari']),
    'edukasi': getFirstNonNull(rencana, ['edukasi', 'pendidikan_pasien']),
    'home_care': getFirstNonNull(rencana, ['home_care', 'homecare']),
    'rujukan_rencana': getFirstNonNull(rencana, ['rujukan', 'rujukan_ke']),
    'anjuran_kembali': getFirstNonNull(rencana, ['anjuran_kembali', 'kapan_kembali']),

    'diagnosa_utama': getFirstNonNull(masalah, ['diagnosa_utama', 'diagnosa', 'masalah_utama']),
    'risiko': getFirstNonNull(masalah, ['risiko', 'risiko_dehidrasi', 'risiko_jatuh']),
    'intervensi': getFirstNonNull(masalah, ['intervensi', 'tindakan', 'terapi']),

    'perawat_pengassesmen': getFirstNonNull(ttd, ['perawat_pengassesmen', 'perawat']),
    'ttd_perawat': getFirstNonNull(ttd, ['ttd_perawat', 'ttd']),
    'perawat_penanggung_jawab': getFirstNonNull(ttd, ['perawat_penanggung_jawab', 'penanggung_jawab']),
    'ttd_dokter': getFirstNonNull(ttd, ['ttd_dokter']),
    'tanggal_assesmen': getFirstNonNull(ttd, ['tanggal_assesmen', 'tanggal_assessment', 'tanggal']),
  };
}

String? getPendampingValue(dynamic pendamping, String key) {
  if (pendamping is Map) {
    return pendamping[key]?.toString();
  } else if (pendamping is String && key == 'nama') {
    return pendamping;
  }
  return null;
}