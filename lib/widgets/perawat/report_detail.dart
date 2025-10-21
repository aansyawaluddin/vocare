import 'package:flutter/material.dart';

// ----------------------------------------------------------------------
// UI: STYLING & WIDGET UTAMA
// ----------------------------------------------------------------------

class _AppColors {
  const _AppColors();

  static const Color kBackground = Color.fromARGB(255, 223, 240, 255);
  static const Color kCardBorder = Color(0xFFCED7E8);
  static const Color kHeadingBlue = Color(0xFF0F4C81);
  static const Color kButtonSave = Color(0xFF009563);
  static const Color kAppBarBackground = Color(0xFFD7E2FD);

  Color get background => _AppColors.kBackground;
  Color get cardBorder => _AppColors.kCardBorder;
  Color get headingBlue => _AppColors.kHeadingBlue;
  Color get buttonSave => _AppColors.kButtonSave;
  Color get appBarBackground => _AppColors.kAppBarBackground;
}

class _AppDimensions {
  const _AppDimensions();

  static const double cardPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double labelWidth = 180.0;
}

const _AppColors _colors = _AppColors();

/// Menangani logika tampilan untuk nilai null/kosong
String _formatDisplayValue(String? value, {String? defaultIfNull}) {
  final String defaultText = defaultIfNull ?? 'Tidak ada'; // Aturan umum: "Tidak ada"
  
  if (value == null || value == 'null' || value.trim().isEmpty) {
    return defaultText;
  }
  return value;
}

/// Widget baris info dasar dengan teks default yang bisa di-override
Widget buildInfoRow(String label, String? value, {bool bold = false, String? defaultIfNull}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _AppDimensions.labelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            _formatDisplayValue(value, defaultIfNull: defaultIfNull), // Diperbarui
          ),
        ),
      ],
    ),
  );
}


Widget buildInfoCard({required Widget child}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _colors.cardBorder),
      borderRadius: BorderRadius.circular(_AppDimensions.cardRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.all(_AppDimensions.cardPadding),
    child: child,
  );
}

Widget buildSectionCard(String title, List<Widget> rows) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: buildInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _colors.headingBlue,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...rows,
          const SizedBox(height: 6),
        ],
      ),
    ),
  );
}

// ----------------------------------------------------------------------
// UI: SECTION BUILDERS (DIPAKAI DI SCREEN)
// ----------------------------------------------------------------------

Widget buildInformasiUmumSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('1. Informasi Pasien & Kunjungan', [
    buildInfoRow('No. Rekam Medis (RM)', extractedFields['no_rm']?.toString()),
    buildInfoRow('Nama Pasien', extractedFields['nama_pasien']?.toString()),
    buildInfoRow('Jenis Kelamin', extractedFields['jenis_kelamin']?.toString()),
    buildInfoRow('Tanggal Lahir', extractedFields['tanggal_lahir']?.toString()),
    buildInfoRow('Pekerjaan', extractedFields['pekerjaan']?.toString()),
    buildInfoRow(
      'Status Perkawinan',
      extractedFields['status_perkawinan']?.toString(),
    ),
    buildInfoRow('Alamat', extractedFields['alamat']?.toString()),
    Text(
      'Penanggung Jawab Pasien:',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    buildInfoRow('Nama ', extractedFields['penanggung_jawab']?.toString()),
    buildInfoRow(
      'Hubungan ',
      extractedFields['hubungan_penanggung_jawab']?.toString(),
    ),
    buildInfoRow(
      'Kontak ',
      extractedFields['kontak_penanggung_jawab']?.toString(),
    ),
    const Divider(),
    Text('Informasi Kunjungan:', style: TextStyle(fontWeight: FontWeight.w600)),
    buildInfoRow(
      'Tanggal Kunjungan',
      extractedFields['tanggal_masuk']?.toString(),
    ),
    buildInfoRow('Jam Kunjungan', extractedFields['waktu_masuk']?.toString()),
    buildInfoRow('Poli Tujuan', extractedFields['poli']?.toString()),
    // buildInfoRow('Kelas Pelayanan', extractedFields['pelayanan']?.toString()), // Dihapus (tidak ada di JSON)
    buildInfoRow('Cara Masuk', extractedFields['cara_masuk']?.toString()),
    // buildInfoRow('Pendamping', extractedFields['pendamping']?.toString()),
    // buildInfoRow(
    //  'Sumber Data Anamnesa',
    //  extractedFields['sumber_data']?.toString(),
    // ),
    // buildInfoRow('Rujukan', extractedFields['rujukan']?.toString()), // Dihapus (tidak ada di JSON)
  ]);
}

Widget buildKeluhanUtamaSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('2. Keluhan Utama', [
    buildInfoRow(
      'Keluhan Utama',
      extractedFields['keluhan_utama']?.toString(),
      bold: true,
    ),
  ]);
}

Widget buildRiwayatKesehatanSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('3. Alergi', [
    // Judul disesuaikan
    // buildInfoRow(
    //  'Riwayat Penyakit Dahulu',
    //  extractedFields['riwayat_penyakit_dahulu'],
    // ),
    // buildInfoRow(
    //  'Riwayat Operasi',
    //  extractedFields['riwayat_operasi']?.toString(),
    // ),
    // buildInfoRow(
    //  'Riwayat Transfusi Darah',
    //  extractedFields['riwayat_transfusi']?.toString(),
    // ),
    // const Divider(), // Dihapus
    // buildInfoRow('Nafsu Makan', extractedFields['nafsu_makan']?.toString()), // Dihapus
    // buildInfoRow(
    //  'Perubahan Berat Badan',
    //  extractedFields['perubahan_berat_badan']?.toString(),
    // ), // Dihapus
    // const Divider(),
    buildInfoRow('Alergi', extractedFields['alergi']?.toString(), bold: true),
    // const Divider(), // Dihapus
    // Text(
    //  'Pemeriksanaan Sistem:',
    //  style: TextStyle(fontWeight: FontWeight.w600),
    // ), // Dihapus
  ]);
}

Widget buildStatusGeneralSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('4. Status General & Tanda Vital', [
    buildInfoRow('Tingkat Kesadaran', extractedFields['kesadaran']?.toString()),
    const Divider(),
    Text('Tanda Vital:', style: TextStyle(fontWeight: FontWeight.w600)),
    buildInfoRow('Tekanan Darah', extractedFields['tekanan_darah']?.toString()),
    buildInfoRow('Denyut Nadi', extractedFields['nadi']?.toString()),
    buildInfoRow('Laju Pernapasan', extractedFields['respirasi']?.toString()),
    buildInfoRow('Suhu', extractedFields['suhu']?.toString()),
  ]);
}

Widget buildPemeriksaanFisikSection(Map<String, dynamic> extractedFields) {
  const String defaultText = 'Normal'; // Aturan khusus untuk bagian ini

  return buildSectionCard('5. Pemeriksaan Fisik (Per Sistem)', [
    buildInfoRow(
      'Kepala, Mata, THT',
      extractedFields['kepala']?.toString(),
      defaultIfNull: defaultText, // Diterapkan
    ), // Label digabung
    buildInfoRow(
      'Mulut', 
      extractedFields['mulut']?.toString(),
      defaultIfNull: defaultText, // Diterapkan
    ),
    buildInfoRow(
      'Leher', 
      extractedFields['leher']?.toString(),
      defaultIfNull: defaultText, // Diterapkan
    ),
    buildInfoRow(
      'Thorak & Payudara', 
      extractedFields['thoraks']?.toString(),
      defaultIfNull: defaultText, // Diterapkan
    ),
    buildInfoRow(
      'Jantung', 
      extractedFields['jantung']?.toString(),
      defaultIfNull: defaultText, // Diterapkan
    ),
    buildInfoRow(
      'Abdomen', 
      extractedFields['abdomen']?.toString(),
      defaultIfNull: defaultText, // Diterapkan
    ),
    buildInfoRow(
      'Urogenital', 
      extractedFields['urogenital']?.toString(),
      defaultIfNull: defaultText, // Diterapkan
    ),
    buildInfoRow(
      'Ekstremitas', 
      extractedFields['ekstremitas']?.toString(),
      defaultIfNull: defaultText, // Diterapkan
    ),
    buildInfoRow(
      'Kulit (Integumen)',
      extractedFields['kulit']?.toString(),
      defaultIfNull: defaultText, // Diterapkan
    ), // Label diubah
  ]);
}


Widget buildAsesmenNyeriSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('6. Asesmen Nyeri', [
    buildInfoRow('Lokasi', extractedFields['lokasi_nyeri']?.toString()),
    buildInfoRow(
      'Sifat (Karakter)',
      extractedFields['karakter_nyeri']?.toString(),
    ),
    buildInfoRow(
      'Faktor Pencetus',
      extractedFields['faktor_pencetus_nyeri']?.toString(),
    ),
    buildInfoRow(
      'Faktor Penghilang',
      extractedFields['faktor_penghilang_nyeri']?.toString(),
    ),
    buildInfoRow(
      'Skala Nyeri',
      extractedFields['skala']?.toString(),
      bold: true,
    ),
  ]);
}

Widget buildSkriningGiziSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('7. Skrining Gizi', [
    // buildInfoRow('Skor', extractedFields['skor_gizi']?.toString()),
    buildInfoRow('Tinggi Badan', extractedFields['tinggi_badan']?.toString()),
    buildInfoRow('Berat Badan', extractedFields['berat_badan']?.toString()),
    buildInfoRow('IMT', extractedFields['IMT']?.toString()),
    // buildInfoRow(
    //  'Penurunan Berat Badan',
    //  extractedFields['penurunan_berat_badan']?.toString(),
    // ), // Dihapus
    buildInfoRow(
      'Status Gizi',
      extractedFields['status_gizi']?.toString(),
      bold: true,
    ),
  ]);
}

Widget buildSkriningRisikoJatuhSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('9. Skrining Risiko Jatuh', [
    buildInfoRow('Skor', extractedFields['skala_morse']?.toString()),
    buildInfoRow(
      'Kategori',
      extractedFields['kategori_jatuh']?.toString(),
      bold: true,
    ),
    // buildInfoRow(
    //  'Riwayat Jatuh 1 Tahun',
    //  extractedFields['riwayat_jatuh']?.toString(),
    // ), // Dihapus
    // buildInfoRow(
    //  'Penggunaan Alat Bantu',
    //  extractedFields['alat_bantu_jalan']?.toString(),
    // ), // Dihapus
  ]);
}

Widget buildStatusPsikososialSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('10. Status Psikososial, Spiritual & Edukasi', [
    buildInfoRow(
      'Bahasa Sehari-hari',
      extractedFields['bahasa_sehari_hari']?.toString(),
    ),
    buildInfoRow(
      'Status Komunikasi',
      extractedFields['komunikasi']?.toString(), // Akan tampil 'Tidak ada'
    ),
    buildInfoRow(
      'Status Emosional',
      extractedFields['kondisi_emosional']?.toString(),
    ),
    const Divider(),
    Text('Spiritual & Edukasi:', style: TextStyle(fontWeight: FontWeight.w600)),
    buildInfoRow(
      'Kebutuhan Ibadah',
      extractedFields['kebutuhan_spiritual']?.toString(),
    ),
    buildInfoRow(
      'Pemahaman Rencana Perawatan',
      extractedFields['pemahaman_perawatan']?.toString(),
    ),
  ]);
}

// Widget buildRencanaPerawatanSection(Map<String, dynamic> extractedFields) {
//  return buildSectionCard('11. Rencana Perawatan & Edukasi', [
//    ... (dikomentari di kode Anda)
//  ]);
// }

Widget buildMasalahKeperawatanSection(Map<String, dynamic> extractedFields) {
  final List<dynamic> masalahList =
      extractedFields['masalah_keperawatan_list'] is List
          ? extractedFields['masalah_keperawatan_list'] as List<dynamic>
          : [];

  final String masalahDisplay;
  if (masalahList.isEmpty) {
    masalahDisplay = 'Tidak ada'; // Terapkan aturan default di sini
  } else {
    masalahDisplay = masalahList.map((e) => e.toString()).join(', ');
  }

  return buildSectionCard('11. Masalah Keperawatan', [
    buildInfoRow('Daftar Masalah', masalahDisplay, bold: true),
  ]);
}

Widget buildRencanaAsuhanSection(Map<String, dynamic> extractedFields) {
 return buildSectionCard('12. Rencana Asuhan Keperawatan', [
   buildInfoRow(
     'Rencana Asuhan',
     extractedFields['rencana_asuhan_string']?.toString(),
     bold: true,
   ),
 ]);
}


// ----------------------------------------------------------------------
// UI: WIDGET INTERAKTIF (RENCANA ASUHAN EDITOR)
// ----------------------------------------------------------------------

// class RencanaAsuhanEditor extends StatefulWidget {
//  ... (dikomentari di kode Anda)
// }

// class _RencanaAsuhanEditorState extends State<RencanaAsuhanEditor> {
//  ... (dikomentari di kode Anda)
// }