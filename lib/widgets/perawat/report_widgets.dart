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
  static const double labelWidth = 180.0;
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

/// -------------------------
/// UI: Section builders (dipakai di screen)
/// -------------------------
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
    buildInfoRow('Kelas Pelayanan', extractedFields['pelayanan']?.toString()),
    buildInfoRow('Cara Masuk', extractedFields['cara_masuk']?.toString()),
    buildInfoRow('Pendamping', extractedFields['pendamping']?.toString()),
    buildInfoRow(
      'Sumber Data Anamnesa',
      extractedFields['sumber_data']?.toString(),
    ),
    buildInfoRow('Rujukan', extractedFields['rujukan']?.toString()),
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
  return buildSectionCard('3. Riwayat & Pemeriksaan Sistem', [
    buildInfoRow(
      'Riwayat Penyakit Dahulu',
      extractedFields['riwayat_penyakit_dahulu'],
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
    buildInfoRow('Nafsu Makan', extractedFields['nafsu_makan']?.toString()),
    buildInfoRow(
      'Perubahan Berat Badan',
      extractedFields['perubahan_berat_badan']?.toString(),
    ),
    const Divider(),
    buildInfoRow('Alergi', extractedFields['alergi']?.toString(), bold: true),
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
  return buildSectionCard('5. Pemeriksaan Fisik (Per Sistem)', [
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
      bold: true,
    ),
    buildInfoRow(
      'Skala Nyeri',
      extractedFields['skala']?.toString(),
    ),
  ]);
}

Widget buildSkriningGiziSection(Map<String, dynamic> extractedFields) {
  return buildSectionCard('7. Skrining Gizi', [
    buildInfoRow('Skor', extractedFields['skor_gizi']?.toString()),
    buildInfoRow('Tinggi Badan', extractedFields['tinggi_badan']?.toString()),
    buildInfoRow('Berat Badan', extractedFields['berat_badan']?.toString()),
    buildInfoRow('IMT', extractedFields['IMT']?.toString()),
    buildInfoRow(
      'Penurunan Berat Badan',
      extractedFields['penurunan_berat_badan']?.toString(),
    ),
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
  final List<dynamic> masalahList =
      extractedFields['masalah_keperawatan_list'] is List
          ? extractedFields['masalah_keperawatan_list'] as List<dynamic>
          : [];

  final String masalahDisplay =
      masalahList.isEmpty ? '-' : masalahList.map((e) => e.toString()).join(', ');

  return buildSectionCard('12. Masalah Keperawatan', [
    buildInfoRow('Daftar Masalah', masalahDisplay, bold: true),
  ]);
}


class RencanaAsuhanEditor extends StatefulWidget {
  final List<String> initialRencana;
  final void Function(List<String>)? onChanged;
  final bool editable;

  const RencanaAsuhanEditor({
    Key? key,
    this.initialRencana = const [],
    this.onChanged,
    this.editable = true,
  }) : super(key: key);

  @override
  _RencanaAsuhanEditorState createState() => _RencanaAsuhanEditorState();
}

class _RencanaAsuhanEditorState extends State<RencanaAsuhanEditor> {
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.initialRencana);
  }

  void _notify() {
    widget.onChanged?.call(List<String>.from(_items));
    setState(() {});
  }

  Future<void> _showEditDialog({String? current, int? index}) async {
    final controller = TextEditingController(text: current ?? '');
    final isNew = index == null;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(isNew ? 'Tambah Rencana Asuhan' : 'Ubah Rencana Asuhan'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Tulis rencana asuhan...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(_colors.buttonSave),
            ),
            onPressed: () {
              final val = controller.text.trim();
              if (val.isEmpty) return;
              if (isNew) {
                _items.add(val);
              } else {
                _items[index!] = val;
              }
              Navigator.of(ctx).pop();
              _notify();
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.editable && _items.isEmpty) {
      return buildInfoCard(child: Text('-'));
    }

    return buildSectionCard(
      '13 Rencana Asuhan Keperawatan',
      [
        if (_items.isEmpty) const Text('Belum ada rencana asuhan.'),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          itemBuilder: (context, idx) {
            final text = _items[idx];
            return Dismissible(
              key: ValueKey('rencana_${idx}_${text.hashCode}'),
              direction: widget.editable ? DismissDirection.endToStart : DismissDirection.none,
              background: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: widget.editable
                  ? (_) {
                      _items.removeAt(idx);
                      _notify();
                    }
                  : null,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${idx + 1}. $text'),
                trailing: widget.editable
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showEditDialog(current: text, index: idx),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() {
                              _items.removeAt(idx);
                            });
                            _notify();
                          },
                        ),
                      ])
                    : null,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        if (widget.editable)
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Tambah Rencana'),
              onPressed: () => _showEditDialog(),
            ),
          ),
      ],
    );
  }
}