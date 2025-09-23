import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vocare/widgets/perawat/report_utils.dart';

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
  static const double labelWidth = 140.0;
  static const double thumbWidth = 140.0;
  static const double thumbHeight = 80.0;
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
  return buildInfoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _colors.headingBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...rows,
        const SizedBox(height: 6),
      ],
    ),
  );
}

Widget buildInformasiUmumSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('1. Informasi Umum', [
    buildInfoRow('Kode RM', extractedFields['kode_rm']?.toString()),
    buildInfoRow('Nama pasien', extractedFields['nama_pasien']?.toString()),
    buildInfoRow('Jenis kelamin', extractedFields['jenis_kelamin']?.toString()),
    buildInfoRow('Tanggal lahir', extractedFields['tanggal_lahir']?.toString()),
    buildInfoRow('Usia', extractedFields['usia']?.toString()),
    buildInfoRow('Tanggal masuk', extractedFields['tanggal_masuk']?.toString()),
    buildInfoRow('Jam masuk', extractedFields['jam_masuk']?.toString()),
    buildInfoRow('Cara masuk', extractedFields['cara_masuk']?.toString()),
    buildInfoRow('Alamat', extractedFields['alamat']?.toString()),
    buildInfoRow('Pekerjaan', extractedFields['pekerjaan']?.toString()),
    buildInfoRow('Agama', extractedFields['agama']?.toString()),
  ]);
}

Widget buildPengantarPendampingSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('2. Pengantar & Pendamping', [
    buildInfoRow(
      'Penanggung Jawab',
      extractedFields['penanggung_jawab']?.toString(),
    ),
    buildInfoRow(
      'Hubungan',
      extractedFields['hubungan_penanggung_jawab']?.toString(),
    ),
    buildInfoRow(
      'Kontak',
      extractedFields['kontak_penanggung_jawab']?.toString(),
    ),
    buildInfoRow(
      'Nama pendamping',
      getPendampingValue(extractedFields['pendamping'], 'nama'),
    ),
    buildInfoRow(
      'Hubungan pendamping',
      getPendampingValue(extractedFields['pendamping'], 'hubungan'),
    ),
  ]);
}

Widget buildKeluhanUtamaSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('3. Keluhan Utama', [
    buildInfoRow('Keluhan', extractedFields['keluhan_utama']?.toString()),
    buildInfoRow('Durasi', extractedFields['durasi_keluhan']?.toString()),
  ]);
}

Widget buildRiwayatKesehatanSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('4. Riwayat Kesehatan', [
    buildInfoRow(
      'Riwayat Sekarang',
      extractedFields['riwayat_penyakit_sekarang']?.toString(),
    ),
    buildInfoRow(
      'Riwayat Dahulu',
      extractedFields['riwayat_penyakit_dahulu']?.toString(),
    ),
    buildInfoRow(
      'Riwayat Operasi',
      extractedFields['riwayat_operasi']?.toString(),
    ),
    buildInfoRow(
      'Riwayat Transfusi',
      extractedFields['riwayat_transfusi']?.toString(),
    ),
    buildInfoRow(
      'Pengobatan Teratur',
      extractedFields['pengobatan_teratur']?.toString(),
    ),
    buildInfoRow('Alergi', extractedFields['alergi']?.toString()),
  ]);
}

Widget buildStatusGeneralSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('5. Status General', [
    buildInfoRow('Kesadaran', extractedFields['kesadaran']?.toString()),
    buildInfoRow('Keadaan Umum', extractedFields['keadaan_umum']?.toString()),
    buildInfoRow('Berat Badan', extractedFields['berat_badan']?.toString()),
    buildInfoRow('Tekanan Darah', extractedFields['tekanan_darah']?.toString()),
    buildInfoRow('Nadi', extractedFields['nadi']?.toString()),
    buildInfoRow('Respirasi', extractedFields['respirasi']?.toString()),
    buildInfoRow('Suhu', extractedFields['suhu']?.toString()),
    buildInfoRow('GCS', extractedFields['gcs']?.toString()),
    buildInfoRow(
      'Golongan Darah',
      extractedFields['golongan_darah']?.toString(),
    ),
  ]);
}

Widget buildPemeriksaanFisikSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('6. Pemeriksaan Fisik', [
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
    buildInfoRow('Jenis', extractedFields['jenis_nyeri']?.toString()),
    buildInfoRow('Karakter', extractedFields['karakter_nyeri']?.toString()),
    buildInfoRow('Lokasi', extractedFields['lokasi_nyeri']?.toString()),
    buildInfoRow('Penjalaran', extractedFields['penjalaran_nyeri']?.toString()),
    buildInfoRow('Intensitas', extractedFields['intensitas_nyeri']?.toString()),
    buildInfoRow('Durasi', extractedFields['durasi_nyeri']?.toString()),
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
    buildInfoRow(
      'Penurunan BB',
      extractedFields['penurunan_berat_badan']?.toString(),
    ),
    buildInfoRow('Asupan Makan', extractedFields['asupan_makanan']?.toString()),
    buildInfoRow('MNA-SF', extractedFields['mna_sf']?.toString()),
    buildInfoRow('Lingkar Betis', extractedFields['lingkar_betis']?.toString()),
  ]);
}

Widget buildSkriningRisikoJatuhSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('9. Skrining Risiko Jatuh', [
    buildInfoRow('Skala Morse', extractedFields['skala_morse']?.toString()),
    buildInfoRow('Riwayat Jatuh', extractedFields['riwayat_jatuh']?.toString()),
    buildInfoRow('Orientasi', extractedFields['orientasi']?.toString()),
    buildInfoRow(
      'Alat Bantu Jalan',
      extractedFields['alat_bantu_jalan']?.toString(),
    ),
    buildInfoRow('Infus', extractedFields['infus']?.toString()),
  ]);
}

Widget buildStatusPsikososialSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('10. Status Psikososial', [
    buildInfoRow(
      'Komposisi Keluarga',
      extractedFields['komposisi_keluarga']?.toString(),
    ),
    buildInfoRow('Komunikasi', extractedFields['komunikasi']?.toString()),
    buildInfoRow(
      'Kondisi Emosional',
      extractedFields['kondisi_emosional']?.toString(),
    ),
    buildInfoRow(
      'Dukungan Keluarga',
      extractedFields['dukungan_keluarga']?.toString(),
    ),
    buildInfoRow(
      'Riwayat Gangguan Jiwa',
      extractedFields['riwayat_gangguan_jiwa']?.toString(),
    ),
    buildInfoRow(
      'Kebutuhan Spiritual',
      extractedFields['kebutuhan_spiritual']?.toString(),
    ),
    buildInfoRow(
      'Status Ekonomi',
      extractedFields['status_ekonomi']?.toString(),
    ),
    buildInfoRow('Pendidikan', extractedFields['pendidikan']?.toString()),
  ]);
}

Widget buildRencanaPerawatanSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('11. Rencana Perawatan', [
    buildInfoRow('Observasi', extractedFields['observasi']?.toString()),
    buildInfoRow('Edukasi', extractedFields['edukasi']?.toString()),
    buildInfoRow('Home Care', extractedFields['home_care']?.toString()),
    buildInfoRow('Rujukan', extractedFields['rujukan_rencana']?.toString()),
    buildInfoRow(
      'Anjuran Kembali',
      extractedFields['anjuran_kembali']?.toString(),
    ),
  ]);
}

Widget buildMasalahKeperawatanSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('12. Masalah Keperawatan', [
    buildInfoRow(
      'Diagnosa Utama',
      extractedFields['diagnosa_utama']?.toString(),
    ),
    buildInfoRow('Risiko', extractedFields['risiko']?.toString()),
    buildInfoRow('Intervensi', extractedFields['intervensi']?.toString()),
  ]);
}

Widget buildSignatureSection(
  File? signatureFile,
  Uint8List? signatureBytes,
  bool isImage,
  VoidCallback onPickSignature,
  VoidCallback onClearSignature,
  void Function(BuildContext) showFullImageViewer,
) {
  return buildInfoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '13. Tanda Tangan & Meta Data',
          style: TextStyle(
            color: _colors.headingBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        buildInfoRow('Perawat Pengassesmen', 'Nama Perawat A'),
        buildInfoRow('Perawat Penanggung Jawab', 'Nama Perawat B'),
        buildInfoRow('Tanggal Asesmen', '23/09/2025'),
        const SizedBox(height: 12),
        Text(
          'Upload Tanda Tangan',
          style: TextStyle(
            color: _colors.headingBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        if (signatureFile != null || signatureBytes != null) ...[
          if (isImage) ...[
            _buildImageThumbnail(
              signatureFile,
              signatureBytes,
              showFullImageViewer,
            ),
          ] else ...[
            _buildPdfThumbnail(signatureFile),
          ],
          const SizedBox(height: 10),
          _buildSignatureActions(onClearSignature, onPickSignature),
        ] else ...[
          _buildSignaturePlaceholder(onPickSignature),
          const SizedBox(height: 10),
        ],
      ],
    ),
  );
}

Widget _buildImageThumbnail(
  File? signatureFile,
  Uint8List? signatureBytes,
  void Function(BuildContext) showFullImageViewer,
) {
  return GestureDetector(
    onTap: () => showFullImageViewer,
    child: Container(
      width: _AppDimensions.thumbWidth,
      height: _AppDimensions.thumbHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: signatureBytes != null
            ? Image.memory(
                signatureBytes,
                fit: BoxFit.cover,
                width: _AppDimensions.thumbWidth,
                height: _AppDimensions.thumbHeight,
              )
            : Image.file(
                signatureFile!,
                fit: BoxFit.cover,
                width: _AppDimensions.thumbWidth,
                height: _AppDimensions.thumbHeight,
              ),
      ),
    ),
  );
}

Widget _buildPdfThumbnail(File? signatureFile) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: _colors.cardBorder),
      borderRadius: BorderRadius.circular(8),
      color: Colors.grey.shade50,
    ),
    child: Row(
      children: [
        const Icon(Icons.picture_as_pdf, color: Colors.red),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            signatureFile?.path.split('/').last ?? 'File dipilih.pdf',
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
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

