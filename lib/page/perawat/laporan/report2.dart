import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class VocareReport2 extends StatefulWidget {
  final String reportText;
  const VocareReport2({super.key, required this.reportText});

  @override
  State<VocareReport2> createState() => _VocareReport2State();
}

class _VocareReport2State extends State<VocareReport2> {
  static const background = Color.fromARGB(255, 223, 240, 255);
  static const cardBorder = Color(0xFFCED7E8);
  static const headingBlue = Color(0xFF0F4C81);
  static const buttonSave = Color(0xFF009563);

  File? _signatureFile;
  Uint8List? _signatureBytes;
  String? _signatureExtension;

  static const double _thumbWidth = 140;
  static const double _thumbHeight = 80;

  Future<void> _pickSignatureFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.single;

        setState(() {
          _signatureExtension = picked.extension?.toLowerCase();
          _signatureBytes = picked.bytes;
          _signatureFile = picked.path != null ? File(picked.path!) : null;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _clearSignature() {
    setState(() {
      _signatureFile = null;
      _signatureBytes = null;
      _signatureExtension = null;
    });
  }

  bool _isImageFile() {
    final ext = _signatureExtension;
    if (ext != null) {
      return ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext);
    }

    final f = _signatureFile;
    if (f != null) {
      final lower = f.path.toLowerCase();
      return lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.webp') ||
          lower.endsWith('.heic');
    }

    return false;
  }

  Widget section(String title, {required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: cardBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: headingBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          child,
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showFullImageViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: _signatureBytes != null
              ? Image.memory(_signatureBytes!, fit: BoxFit.contain)
              : _signatureFile != null
              ? Image.file(_signatureFile!, fit: BoxFit.contain)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isImage = _isImageFile();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: background,
        centerTitle: true,
        title: const Text(
          'Vocare Report',
          style: TextStyle(
            color: Color(0xFF083B74),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: background),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 18, top: 10),
            children: [
              const SizedBox(height: 6),
              const Text(
                ' CPPT 40 10-09-2025 Perawat - Aan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0XFF093275),
                ),
              ),
              const SizedBox(height: 5),
              section(
                'Subjective',
                child: Text(
                  widget.reportText,
                  style: const TextStyle(height: 1.4, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              section(
                'Assessment',
                child: Text(
                  widget.reportText,
                  style: const TextStyle(height: 1.4, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              section(
                'Keterangan',
                child: Text(
                  widget.reportText,
                  style: const TextStyle(height: 1.4, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              section(
                'dr.Andy Hakim :',
                child: Text(
                  widget.reportText,
                  style: const TextStyle(height: 1.4, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              section(
                'Tanda Tangan',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_signatureFile != null || _signatureBytes != null) ...[
                      if (isImage) ...[
                        GestureDetector(
                          onTap: () => _showFullImageViewer(context),
                          child: SizedBox(
                            width: _thumbWidth,
                            height: _thumbHeight,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _signatureBytes != null
                                  ? Image.memory(
                                      _signatureBytes!,
                                      fit: BoxFit.cover,
                                      width: _thumbWidth,
                                      height: _thumbHeight,
                                    )
                                  : Image.file(
                                      _signatureFile!,
                                      fit: BoxFit.cover,
                                      width: _thumbWidth,
                                      height: _thumbHeight,
                                    ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: cardBorder),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _signatureFile?.path.split('/').last ??
                                      'File dipilih.${_signatureExtension ?? ''}',
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _clearSignature,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Hapus'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _pickSignatureFile,
                            icon: const Icon(Icons.edit),
                            label: const Text('Ganti'),
                          ),
                        ],
                      ),
                    ] else ...[
                      GestureDetector(
                        onTap: _pickSignatureFile,
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: cardBorder),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.upload_file,
                                  size: 28,
                                  color: headingBlue.withOpacity(0.8),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Belum ada tanda tangan\nKetuk untuk pilih file',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: headingBlue.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                final sigPath =
                    _signatureFile?.path ??
                    (_signatureBytes != null ? '<bytes>' : '<tidak ada>');
                debugPrint('Menyimpan report dengan tanda tangan: $sigPath');

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report tersimpan')),
                );
              },
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonSave,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
