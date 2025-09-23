import 'package:flutter/material.dart';
import 'package:vocare/page/perawat/laporan/assesments.dart';

class VocareReportInap extends StatefulWidget {
  final String reportText;
  const VocareReportInap({super.key, required this.reportText});

  @override
  State<VocareReportInap> createState() => _VocareReportInapState();
}

class _VocareReportInapState extends State<VocareReportInap> {
  late TextEditingController _controller;
  late String _currentText;

  @override
  void initState() {
    super.initState();
    _currentText = widget.reportText;
    _controller = TextEditingController(text: _currentText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showEditSheet() {
    showModalBottomSheet(
      backgroundColor: const Color(0xFFDFF0FF),
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Laporan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF083B74),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                minLines: 5,
                decoration: InputDecoration(
                  hintText: 'Masukkan teks laporan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentText = _controller.text;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // memecah teks transkrip menjadi blok-blok ringkasan.
  // Kita anggap setiap paragraf kosong (double newline) sebagai pemisah item.
  List<String> _buildActionItemsFromText(String t) {
    final parts = t.split(RegExp(r'\n\s*\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty && t.trim().isNotEmpty) return [t.trim()];
    if (parts.isEmpty) return ['Tidak ada tindakan.'];
    return parts;
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFDFF0FF); // latar biru muda
    const cardBorder = Color(0xFFCED7E8);
    const headingBlue = Color(0xFF0F4C81);
    const accentBox = Color(0xFFEAF2FF); // warna box kecil
    const darkButtonBlue = Color(0xFF083B74);

    final actions = _buildActionItemsFromText(_currentText);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF093275)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Nurse Report',
          style: TextStyle(
            color: Color(0xFF093275),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            children: [
              // Informasi Pasien card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Informasi Pasien',
                        style: TextStyle(
                          color: headingBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Nama Pasien: Tn. Andi', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Nomor RM: 1234'),
                    const SizedBox(height: 4),
                    const Text('Tanggal/Waktu:'),
                    const SizedBox(height: 2),
                    const Text('25 Oktober 2024, 10:30', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Tindakan',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: actions.map((item) {
                              return GestureDetector(
                                onTap: _showEditSheet, 
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: accentBox,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.split('\n').first.length > 40
                                            ? item.split('\n').first.substring(0, 40) + '...'
                                            : item.split('\n').first,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: headingBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item,
                                        style: const TextStyle(height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VocareReport2(reportText: _currentText),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
