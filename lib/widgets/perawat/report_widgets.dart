import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// Asumsi class _AppColors, _AppDimensions, _colors, _AppDimensions, 
// buildInfoRow, _formatDisplayValue, buildInfoCard, dan buildSectionCard
// adalah sama dan sudah didefinisikan di sini.

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
  static const double labelWidth = 160.0; // Disesuaikan sedikit agar label lebih panjang
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

// ----------------------- Section Builders -----------------------

Widget buildInformasiUmumSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('1. Informasi Pasien & Kunjungan', [
    // Informasi Umum Pasien
    buildInfoRow('No. Rekam Medis (RM)', extractedFields['no_rm']?.toString()),
    buildInfoRow('Kode RM', extractedFields['kode_rm']?.toString()),
    buildInfoRow('Nama Pasien', extractedFields['nama_pasien']?.toString()),
    buildInfoRow('Jenis Kelamin', extractedFields['jenis_kelamin']?.toString()),
    buildInfoRow('Tanggal Lahir', extractedFields['tanggal_lahir']?.toString()),
    buildInfoRow('Usia', extractedFields['usia']?.toString()),
    buildInfoRow('Agama', extractedFields['agama']?.toString()),
    buildInfoRow('Pekerjaan', extractedFields['pekerjaan']?.toString()),
    buildInfoRow('Status Perkawinan', extractedFields['status_perkawinan']?.toString()),
    buildInfoRow('Alamat', extractedFields['alamat']?.toString()),

    const Divider(),
    Text('Informasi Kunjungan:', style: TextStyle(fontWeight: FontWeight.w600)),
    // Informasi Kunjungan
    buildInfoRow('Tanggal Masuk', extractedFields['tanggal_masuk']?.toString()),
    buildInfoRow('Jam Masuk', extractedFields['jam_masuk']?.toString()),
    buildInfoRow('Poli/Unit', extractedFields['poli']?.toString()),
    buildInfoRow('Kelas', extractedFields['kelas']?.toString()),
    buildInfoRow('Cara Masuk', extractedFields['cara_masuk']?.toString()),
    buildInfoRow('Sumber Data', extractedFields['sumber_data']?.toString()),
    buildInfoRow('Rujukan', extractedFields['rujukan']?.toString()),
  ]);
}

Widget buildPengantarPendampingSection(Map<String, dynamic> extractedFields) {
  final pendampingData = extractedFields['pendamping'] as Map<String, dynamic>? ?? {};

  return buildSectionCard('2. Penanggung Jawab & Pendamping', [
    // Penanggung Jawab
    Text('Penanggung Jawab Pasien:', style: TextStyle(fontWeight: FontWeight.w600)),
    buildInfoRow('Nama PJ', extractedFields['penanggung_jawab']?.toString()),
    buildInfoRow('Hubungan PJ', extractedFields['hubungan_penanggung_jawab']?.toString()),
    buildInfoRow('Kontak PJ', extractedFields['kontak_penanggung_jawab']?.toString()),
    
    const Divider(),
    // Pendamping
    Text('Informasi Pendamping (Pengantar):', style: TextStyle(fontWeight: FontWeight.w600)),
    buildInfoRow('Nama Pendamping', pendampingData['nama']?.toString()),
    buildInfoRow('Hubungan', pendampingData['hubungan']?.toString()),
    buildInfoRow('Usia', pendampingData['usia']?.toString()),
    buildInfoRow('Kondisi', pendampingData['kondisi']?.toString()),
  ]);
}

Widget buildKeluhanUtamaSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('3. Keluhan Utama', [
    buildInfoRow('Keluhan Utama', extractedFields['keluhan_utama']?.toString()),
    buildInfoRow('Durasi Keluhan', extractedFields['durasi_keluhan']?.toString()),
  ]);
}

Widget buildRiwayatKesehatanSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('4. Riwayat Kesehatan & Alergi', [
    buildInfoRow('Penyakit Sekarang', extractedFields['riwayat_penyakit_sekarang']?.toString()),
    buildInfoRow('Penyakit Dahulu', extractedFields['riwayat_penyakit_dahulu']?.toString()),
    buildInfoRow('Riwayat Operasi', extractedFields['riwayat_operasi']?.toString()),
    buildInfoRow('Riwayat Transfusi', extractedFields['riwayat_transfusi']?.toString()),
    buildInfoRow('Golongan Darah', extractedFields['golongan_darah']?.toString()),
    const Divider(),
    Text('Alergi:', style: TextStyle(fontWeight: FontWeight.w600)),
    buildInfoRow('Alergi Obat/Makanan', extractedFields['alergi']?.toString(), bold: true),
    buildInfoRow('Gelang Alergi', extractedFields['gelang_alergi']?.toString()),
  ]);
}

Widget buildStatusGeneralSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('5. Status General & Tanda Vital', [
    // Status General
    Text('Status General:', style: TextStyle(fontWeight: FontWeight.w600)),
    buildInfoRow('Keadaan Umum', extractedFields['keadaan_umum']?.toString()),
    buildInfoRow('Kesadaran', extractedFields['kesadaran']?.toString()),
    buildInfoRow('GCS', extractedFields['gcs']?.toString()),
    
    const Divider(),
    Text('Tanda Vital:', style: TextStyle(fontWeight: FontWeight.w600)),
    // Tanda Vital
    buildInfoRow('Berat Badan', extractedFields['berat_badan']?.toString()),
    buildInfoRow('Tekanan Darah', extractedFields['tekanan_darah']?.toString()),
    buildInfoRow('Nadi', extractedFields['nadi']?.toString()),
    buildInfoRow('Respirasi', extractedFields['respirasi']?.toString()),
    buildInfoRow('Suhu', extractedFields['suhu']?.toString()),
  ]);
}

Widget buildPemeriksaanFisikSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('6. Pemeriksaan Fisik (Per Sistem)', [
    buildInfoRow('Kepala', extractedFields['kepala']?.toString()),
    buildInfoRow('Mata', extractedFields['mata']?.toString()),
    buildInfoRow('THT', extractedFields['tht']?.toString()),
    buildInfoRow('Mulut', extractedFields['mulut']?.toString()),
    buildInfoRow('Leher', extractedFields['leher']?.toString()),
    buildInfoRow('Thoraks', extractedFields['thoraks']?.toString()),
    buildInfoRow('Jantung', extractedFields['jantung']?.toString()),
    buildInfoRow('Abdomen', extractedFields['abdomen']?.toString()),
    buildInfoRow('Urogenital', extractedFields['urogenital']?.toString()),
    buildInfoRow('Ekstremitas', extractedFields['ekstremitas']?.toString()),
    buildInfoRow('Kulit', extractedFields['kulit']?.toString()),
  ]);
}

Widget buildAsesmenNyeriSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('7. Asesmen Nyeri', [
    buildInfoRow('Jenis Nyeri', extractedFields['jenis_nyeri']?.toString()),
    buildInfoRow('Karakter Nyeri', extractedFields['karakter_nyeri']?.toString()),
    buildInfoRow('Lokasi Nyeri', extractedFields['lokasi_nyeri']?.toString()),
    buildInfoRow('Penjalaran', extractedFields['penjalaran_nyeri']?.toString()),
    buildInfoRow('Intensitas Nyeri', extractedFields['intensitas_nyeri']?.toString()),
    buildInfoRow('Durasi Nyeri', extractedFields['durasi_nyeri']?.toString()),
    buildInfoRow('Faktor Pencetus', extractedFields['faktor_pencetus_nyeri']?.toString()),
    buildInfoRow('Faktor Pereda', extractedFields['faktor_pereda_nyeri']?.toString()),
    buildInfoRow('Rekomendasi', extractedFields['rekomendasi_nyeri']?.toString()),
  ]);
}

Widget buildSkriningGiziSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('8. Skrining Gizi (MNA-SF)', [
    buildInfoRow('Penurunan BB', extractedFields['penurunan_berat_badan']?.toString()),
    buildInfoRow('Asupan Makan', extractedFields['asupan_makanan']?.toString()),
    buildInfoRow('Skor MNA-SF', extractedFields['mna_sf']?.toString()),
    buildInfoRow('Lingkar Betis', extractedFields['lingkar_betis']?.toString()),
  ]);
}

Widget buildSkriningRisikoJatuhSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('9. Skrining Risiko Jatuh', [
    buildInfoRow('Skala Morse', extractedFields['skala_morse']?.toString()),
    buildInfoRow('Riwayat Jatuh', extractedFields['riwayat_jatuh']?.toString()),
    buildInfoRow('Orientasi', extractedFields['orientasi']?.toString()),
    buildInfoRow('Alat Bantu Jalan', extractedFields['alat_bantu_jalan']?.toString()),
    buildInfoRow('Terpasang Infus', extractedFields['infus']?.toString()),
  ]);
}

Widget buildStatusPsikososialSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('10. Status Psikososial & Spiritual', [
    buildInfoRow('Tinggal Dengan', extractedFields['komposisi_keluarga']?.toString()),
    buildInfoRow('Pendidikan', extractedFields['pendidikan']?.toString()),
    buildInfoRow('Status Ekonomi', extractedFields['status_ekonomi']?.toString()),
    buildInfoRow('Komunikasi', extractedFields['komunikasi']?.toString()),
    buildInfoRow('Kondisi Emosional', extractedFields['kondisi_emosional']?.toString()),
    buildInfoRow('Dukungan Keluarga', extractedFields['dukungan_keluarga']?.toString()),
    buildInfoRow('Riwayat Gangguan Jiwa', extractedFields['riwayat_gangguan_jiwa']?.toString()),
    buildInfoRow('Agama/Keyakinan', extractedFields['agama']?.toString()),
    buildInfoRow('Kebutuhan Spiritual', extractedFields['kebutuhan_spiritual']?.toString()),
  ]);
}

Widget buildRencanaPerawatanSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('11. Rencana Perawatan & Edukasi', [
    buildInfoRow('Observasi', extractedFields['observasi']?.toString()),
    buildInfoRow('Edukasi', extractedFields['edukasi']?.toString()),
    buildInfoRow('Home Care', extractedFields['home_care']?.toString()),
    buildInfoRow('Rujukan Gizi', extractedFields['rujukan_gizi']?.toString()),
    buildInfoRow('Rujukan Terapi', extractedFields['rujukan_terapi']?.toString()),
    buildInfoRow('Anjuran Kembali', extractedFields['anjuran_kembali']?.toString()),
  ]);
}

Widget buildMasalahKeperawatanSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('12. Masalah Keperawatan & Intervensi', [
    buildInfoRow('Diagnosa Utama', extractedFields['diagnosa_utama']?.toString()),
    buildInfoRow('Risiko Masalah', extractedFields['risiko']?.toString()),
    buildInfoRow('Intervensi', extractedFields['intervensi']?.toString()),
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
    buildInfoRow('Lokasi Asesmen', extractedFields['lokasi_asesmen']?.toString()),
    buildInfoRow('Tanggal/Waktu Asesmen', extractedFields['tanggal_asesmen']?.toString()),
    const Divider(),
    buildInfoRow('Perawat Pengassesmen', extractedFields['perawat_pengassesmen']?.toString()),
    buildInfoRow('Status TTD Pengassesmen', extractedFields['ttd_perawat']?.toString()),
    const SizedBox(height: 8),
    buildInfoRow('Perawat Penanggung Jawab', extractedFields['perawat_penanggung_jawab']?.toString()),
    buildInfoRow('Status TTD Penanggung Jawab', extractedFields['ttd_dokter']?.toString()),
    
    const Divider(),
    Text(
      'Status Tanda Tangan (Simulasi UI):',
      style: TextStyle(
        color: _colors.headingBlue,
        fontWeight: FontWeight.w600,
      ),
    ),
    const SizedBox(height: 6),
    if (signatureFile != null || signatureBytes != null) ...[
      // Menampilkan placeholder gambar TTD (perlu implementasi lebih lanjut)
      Text('Tanda tangan sudah ada (File: ${signatureFile?.path.split('/').last ?? 'Bytes'})'),
      const SizedBox(height: 8),
      _buildSignatureActions(onClearSignature, onPickSignature),
    ] else ...[
      _buildSignaturePlaceholder(onPickSignature),
    ],
  ]);
}