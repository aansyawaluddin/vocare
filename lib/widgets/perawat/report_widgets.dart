import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

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
  static const double labelWidth =
      180.0; // Disesuaikan agar label lebih panjang
}

const _AppColors _colors = _AppColors();

Widget buildInfoRow(String label, String? value, {bool bold = false}) {
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
        Expanded(child: Text(_formatDisplayValue(value))),
      ],
    ),
  );
}

String _formatDisplayValue(String? value) {
  if (value == null || value == 'null' || value.trim().isEmpty) {
    return '-';
  }
  return value;
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

// ----------------------- Section Builders (MODIFIED) -----------------------

Widget buildInformasiUmumSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('1. Informasi Pasien & Kunjungan', [
    // Informasi Umum Pasien
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

    const Divider(),
    Text('Informasi Kunjungan:', style: TextStyle(fontWeight: FontWeight.w600)),
    // Informasi Kunjungan
    buildInfoRow(
      'Tanggal Kunjungan',
      extractedFields['tanggal_kunjungan']?.toString(),
    ),
    buildInfoRow('Jam Kunjungan', extractedFields['jam_kunjungan']?.toString()),
    buildInfoRow('Poli Tujuan', extractedFields['poli']?.toString()),
    buildInfoRow('Kelas Pelayanan', extractedFields['kelas']?.toString()),
    buildInfoRow('Cara Masuk', extractedFields['cara_masuk']?.toString()),
    buildInfoRow(
      'Sumber Data Anamnesa',
      extractedFields['sumber_data']?.toString(),
    ),
    buildInfoRow('Rujukan', extractedFields['rujukan']?.toString()),
  ]);
}

Widget buildPengantarPendampingSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('2. Penanggung Jawab & Pendamping', [
    // Penanggung Jawab
    Text(
      'Penanggung Jawab Pasien:',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    buildInfoRow('Nama PJ', extractedFields['penanggung_jawab']?.toString()),
    buildInfoRow(
      'Hubungan PJ',
      extractedFields['hubungan_penanggung_jawab']?.toString(),
    ),
    buildInfoRow(
      'Kontak PJ',
      extractedFields['kontak_penanggung_jawab']?.toString(),
    ),

    const Divider(),
    // Pendamping (dari data kunjungan)
    Text(
      'Informasi Pendamping:',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    buildInfoRow(
      'Nama Pendamping',
      extractedFields['pendamping']['nama']?.toString(),
    ),
    buildInfoRow(
      'Hubungan',
      extractedFields['hubungan_penanggung_jawab']?.toString(),
    ),
  ]);
}

Widget buildKeluhanUtamaSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('3. Keluhan Utama', [
    buildInfoRow(
      'Keluhan Utama',
      extractedFields['keluhan_utama']?.toString(),
      bold: true,
    ),
  ]);
}

Widget buildRiwayatKesehatanSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('4. Riwayat & Pemeriksaan Sistem', [
    // Riwayat Penyakit (dari pemeriksaan_sistem)
    buildInfoRow(
      'Riwayat Penyakit Dahulu',
      extractedFields['riwayat_penyakit_dahulu']?.toString(),
    ),
    buildInfoRow(
      'Riwayat Operasi',
      extractedFields['riwayat_operasi']?.toString(),
    ),
    buildInfoRow(
      'Riwayat Transfusi Darah',
      extractedFields['riwayat_transfusi']?.toString(),
    ),

    const Divider(),
    // Pemeriksaan Sistem Tambahan (dari pemeriksaan_sistem)
    Text('Sistem Tubuh:', style: TextStyle(fontWeight: FontWeight.w600)),
    buildInfoRow('Nafsu Makan', extractedFields['nafsu_makan']?.toString()),
    buildInfoRow(
      'Perubahan Berat Badan',
      extractedFields['perubahan_berat_badan']?.toString(),
    ),

    const Divider(),
    // Alergi
    Text('Alergi:', style: TextStyle(fontWeight: FontWeight.w600)),
    buildInfoRow('Alergi', extractedFields['alergi']?.toString(), bold: true),
  ]);
}

Widget buildStatusGeneralSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('5. Status General, Antropometri & Tanda Vital', [
    // Status General & Antropometri
    Text('Status General:', style: TextStyle(fontWeight: FontWeight.w600)),
    buildInfoRow('Tingkat Kesadaran', extractedFields['kesadaran']?.toString()),
    buildInfoRow('Tinggi Badan', extractedFields['tinggi_badan']?.toString()),
    buildInfoRow('Berat Badan', extractedFields['berat_badan']?.toString()),

    const Divider(),
    Text('Tanda Vital:', style: TextStyle(fontWeight: FontWeight.w600)),
    // Tanda Vital
    buildInfoRow('Tekanan Darah', extractedFields['tekanan_darah']?.toString()),
    buildInfoRow('Denyut Nadi', extractedFields['nadi']?.toString()),
    buildInfoRow('Laju Pernapasan', extractedFields['respirasi']?.toString()),
    buildInfoRow('Suhu', extractedFields['suhu']?.toString()),
  ]);
}

Widget buildPemeriksaanFisikSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('6. Pemeriksaan Fisik (Per Sistem)', [
    buildInfoRow('Kepala & Mata', extractedFields['kepala']?.toString()),
    buildInfoRow('THT', extractedFields['tht']?.toString()),
    buildInfoRow('Mulut', extractedFields['mulut']?.toString()),
    buildInfoRow('Leher', extractedFields['leher']?.toString()),
    buildInfoRow('Thorak & Payudara', extractedFields['thoraks']?.toString()),
    buildInfoRow('Jantung', extractedFields['jantung']?.toString()),
    buildInfoRow('Abdomen', extractedFields['abdomen']?.toString()),
    buildInfoRow('Urogenital', extractedFields['urogenital']?.toString()),
    buildInfoRow('Ekstremitas', extractedFields['ekstremitas']?.toString()),
    buildInfoRow('Kulit', extractedFields['kulit']?.toString()),
  ]);
}

Widget buildAsesmenNyeriSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('7. Asesmen Nyeri', [
    buildInfoRow('Lokasi', extractedFields['lokasi_nyeri']?.toString()),
    buildInfoRow(
      'Sifat (Karakter)',
      extractedFields['karakter_nyeri']?.toString(),
    ),
    buildInfoRow(
      'Skala Nyeri',
      extractedFields['skor']?.toString(),
      bold: true,
    ),
    buildInfoRow(
      'Faktor Pencetus',
      extractedFields['faktor_pencetus_nyeri']?.toString(),
    ),
    buildInfoRow(
      'Faktor Pereda',
      extractedFields['faktor_pereda_nyeri']?.toString(),
    ),
  ]);
}

Widget buildSkriningGiziSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('8. Skrining Gizi', [
    buildInfoRow('Skor', extractedFields['mna_sf']?.toString()),
    buildInfoRow(
      'Kategori',
      extractedFields['kategori_gizi']?.toString(),
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
    buildInfoRow(
      'Riwayat Jatuh 1 Tahun',
      extractedFields['riwayat_jatuh']?.toString(),
    ),
    buildInfoRow(
      'Penggunaan Alat Bantu',
      extractedFields['alat_bantu_jalan']?.toString(),
    ),
  ]);
}

Widget buildStatusPsikososialSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('10. Status Psikososial & Spiritual', [
    buildInfoRow(
      'Bahasa Sehari-hari',
      extractedFields['bahasa_sehari_hari']?.toString(),
    ),
    buildInfoRow(
      'Status Komunikasi',
      extractedFields['komunikasi']?.toString(),
    ),
    buildInfoRow(
      'Status Emosional',
      extractedFields['kondisi_emosional']?.toString(),
    ),
    buildInfoRow(
      'Gangguan Jiwa',
      extractedFields['riwayat_gangguan_jiwa']?.toString(),
    ),

    const Divider(),
    Text('Kondisi Sosial:', style: TextStyle(fontWeight: FontWeight.w600)),
    buildInfoRow('Pendidikan', extractedFields['pendidikan']?.toString()),
    buildInfoRow(
      'Status Ekonomi',
      extractedFields['status_ekonomi']?.toString(),
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

Widget buildRencanaPerawatanSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('11. Rencana Perawatan & Edukasi', [
    buildInfoRow(
      'Edukasi Pasien',
      extractedFields['edukasi']?.toString(),
      bold: true,
    ),
    const Divider(),
    Text('Rencana Lanjutan:', style: TextStyle(fontWeight: FontWeight.w600)),
    buildInfoRow('Rujukan', extractedFields['rujukan']?.toString()),
    buildInfoRow('Home Care', extractedFields['home_care']?.toString()),
  ]);
}

Widget buildMasalahKeperawatanSection(Map<String, dynamic> extractedFields) {
  // Masalah Keperawatan adalah List<String> di JSON
  final List<dynamic> masalahList =
      extractedFields['masalah_keperawatan_list'] is List
      ? extractedFields['masalah_keperawatan_list'] as List<dynamic>
      : [];

  final String masalahDisplay = masalahList.isEmpty
      ? '-'
      : masalahList.map((e) => e.toString()).join(', ');

  return buildSectionCard('12. Masalah Keperawatan', [
    buildInfoRow('Daftar Masalah', masalahDisplay, bold: true),
  ]);
}

Widget _buildSignatureActions(VoidCallback onClear, VoidCallback onPick) {
  return Row(
    children: [
      ElevatedButton.icon(
        onPressed: onClear,
        icon: const Icon(Icons.delete_outline),
        label: const Text('Hapus'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
        ),
      ),
      const SizedBox(width: 8),
      ElevatedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.edit),
        label: const Text('Ganti'),
      ),
    ],
  );
}

Widget _buildSignaturePlaceholder(VoidCallback onPick) {
  return GestureDetector(
    onTap: onPick,
    child: Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(
          color: _colors.cardBorder,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upload_file,
              size: 28,
              color: _colors.headingBlue.withOpacity(0.8),
            ),
            const SizedBox(height: 6),
            Text(
              'Belum ada tanda tangan\nKetuk untuk pilih file',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _colors.headingBlue.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildSignatureSection(
  Map<String, dynamic> extractedFields,
  File? signatureFile,
  Uint8List? signatureBytes,
  bool isImage,
  VoidCallback onPickSignature,
  VoidCallback onClearSignature,
  void Function(BuildContext) showFullImageViewer,
) {
  return buildSectionCard('13. Tanda Tangan & Administrasi Data', [
    buildInfoRow(
      'Perawat Pengassesmen',
      extractedFields['perawat_pengassesmen']?.toString(),
    ),
    buildInfoRow(
      'Lokasi Asesmen',
      extractedFields['lokasi_asesmen']?.toString(),
    ),
    buildInfoRow(
      'Tanggal/Waktu Asesmen',
      extractedFields['tanggal_asesmen']?.toString(),
    ),
    const Divider(),
    // Data TTD aktual tidak ada di JSON, hanya nama perawat dari root
    Text(
      'Status Tanda Tangan (Simulasi UI):',
      style: TextStyle(color: _colors.headingBlue, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 6),
    if (signatureFile != null || signatureBytes != null) ...[
      // Menampilkan placeholder gambar TTD (perlu implementasi lebih lanjut)
      Text(
        'Tanda tangan sudah ada (File: ${signatureFile?.path.split('/').last ?? 'Bytes'})',
      ),
      const SizedBox(height: 8),
      _buildSignatureActions(onClearSignature, onPickSignature),
    ] else ...[
      _buildSignaturePlaceholder(onPickSignature),
    ],
  ]);
}
