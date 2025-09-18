import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vocare/common/type.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vocare/page/perawat/laporan/voice.dart';

class UploadLab extends StatefulWidget {
  final Future<void> Function(PlatformFile file)? onSave;
  final User user;

  const UploadLab({super.key, this.onSave, required this.user });

  @override
  State<UploadLab> createState() => _UploadLabState();
}

class _UploadLabState extends State<UploadLab> {
  PlatformFile? _pickedFile;
  bool _isSaving = false;

  final Color _navy = const Color(0xFF0B3B82);

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
      );
      if (result == null) return; // user batal pilih
      setState(() => _pickedFile = result.files.first);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File dipilih: ${_pickedFile!.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih file: $e')));
    }
  }

  Future<void> _saveFile() async {
    if (_pickedFile == null) return;
    setState(() => _isSaving = true);
    try {
      if (widget.onSave != null) {
        await widget.onSave!(_pickedFile!);
      } else {
        // simulasi proses penyimpanan jika tidak ada callback
        await Future.delayed(const Duration(seconds: 1));
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File berhasil disimpan')));
      setState(() => _pickedFile = null);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _shortFileName(String name, {int max = 25}) {
    if (name.length <= max) return name;
    return '${name.substring(0, max - 3)}...';
  }

  @override
  Widget build(BuildContext context) {
    final navy = _navy; // gunakan warna dari field

    return Scaffold(
      backgroundColor: const Color(0xFFD7E2FD),
      appBar: AppBar(
        titleSpacing: 60,
        title: Text(
          'Vocare Report',
          style: TextStyle(fontSize: 20, color: Color(0xFF093275)),
        ),
        backgroundColor: const Color(0xFFD7E2FD),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // kotak ikon yang bisa diketuk untuk pilih file
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.insert_drive_file,
                      color: Colors.white,
                      size: 60,
                    ),
                    if (_pickedFile != null)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Upload Hasil Lab',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF082B54),
              ),
            ),

            const SizedBox(height: 8),

            // tampilkan nama file bila ada
            if (_pickedFile != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Text(
                      _shortFileName(_pickedFile!.name),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // tombol kecil untuk mengganti atau hapus file
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _isSaving ? null : _pickFile,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Ganti'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () => setState(() => _pickedFile = null),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Hapus'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 18),
        child: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      // jika ada file, simpan dulu; jika tidak, langsung lanjut
                      if (_pickedFile != null) {
                        await _saveFile();
                        // setelah berhasil simpan, lanjut ke halaman voice
                        if (!_isSaving) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => VoicePageLaporan(user: widget.user),
                            ),
                          );
                        }
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => VoicePageLaporan(user: widget.user),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
              child: _isSaving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Menyimpan...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(width: 10),
                        Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
