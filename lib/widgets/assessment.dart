import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AssessmentWidget extends StatefulWidget {
  final Future<void> Function(PlatformFile file)? onSave;

  const AssessmentWidget({super.key, this.onSave});

  @override
  State<AssessmentWidget> createState() => _AssessmentWidgetState();
}

class _AssessmentWidgetState extends State<AssessmentWidget> {
  PlatformFile? _pickedFile;
  bool _isSaving = false;

  final Color _navy = const Color(0xFF0B3B82);

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
      );
      if (result == null) return; // user batal
      setState(() => _pickedFile = result.files.first);
    } catch (e) {
      // error picking
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih file: $e')),
      );
    }
  }

  Future<void> _saveFile() async {
    if (_pickedFile == null) return;
    setState(() => _isSaving = true);
    try {
      if (widget.onSave != null) {
        await widget.onSave!(_pickedFile!);
      } else {
        await Future.delayed(const Duration(seconds: 1));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File berhasil disimpan')),
      );
      setState(() => _pickedFile = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
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
    final bool hasFile = _pickedFile != null;
    final String buttonText = hasFile
        ? (_isSaving ? 'Menyimpan...' : 'Simpan')
        : 'Pilih File';
    final double maxCardWidth = 520;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxCardWidth,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: _navy.withOpacity(0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.description_outlined,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'Upload Assessment',
              style: TextStyle(
                color: _navy,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            if (hasFile)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Text(
                  _shortFileName(_pickedFile!.name),
                  style: TextStyle(color: _navy.withOpacity(0.9)),
                ),
              )
            else
              const SizedBox(height: 6),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        if (hasFile) {
                          _saveFile();
                        } else {
                          _pickFile();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(buttonText, style: const TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
