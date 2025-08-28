import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'main_page.dart';

class StepUpload extends StatefulWidget {
  const StepUpload({super.key});

  @override
  State<StepUpload> createState() => _StepUploadState();
}

class _StepUploadState extends State<StepUpload> {
  PlatformFile? _selectedFile;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        // Memorizza l'oggetto PlatformFile
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      // mostra errore
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes >= 1024 * 1024) {
      return "${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB";
    } else {
      return "${(sizeInBytes / 1024).toStringAsFixed(2)} KB";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1EDFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const Text(
                'UPLOAD A NEW STEP',
                style: TextStyle(
                  color: Color(0xFF111416),
                  fontSize: 28,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          context,
                          icon: Icons.tag,
                          label: 'Step name',
                          hintText: 'Enter step name',
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(
                          context,
                          icon: Icons.description,
                          label: 'Description',
                          hintText: 'Enter a description',
                          isMultiLine: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(child: _buildUploadArea(context)),
                ],
              ),
              const SizedBox(height: 40),
              Align(alignment: Alignment.center, child: _buildSaveButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainPage(initialPageIndex: 1),
            ),
          );
        },
        child: Row(
          children: const [
            Icon(Icons.arrow_back_ios, color: Color(0xFF111416), size: 24),
            SizedBox(width: 8),
            Text(
              'BACK',
              style: TextStyle(
                color: Color(0xFF111416),
                fontSize: 20,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String hintText,
    bool isMultiLine = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Contenitore per l'icona
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF002C58),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            // Testo della label
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF111416),
                fontSize: 20,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE0E2)),
          ),
          child: TextFormField(
            maxLines: isMultiLine ? 5 : 1,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF6B7582),
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.all(15),
              border: InputBorder.none,
            ),
            style: const TextStyle(color: Color(0xFF111416), fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 2,
          color: const Color(0xFFDBE8F2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_selectedFile == null)
            // Area iniziale di upload con il pulsante "Choose file"
            Column(
              children: [
                const Text(
                  'Upload a step file',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF111416),
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5E7EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Choose file',
                    style: TextStyle(
                      color: Color(0xFF111416),
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          else
            // Visualizzatore del file caricato
            Column(
              children: [
                InkWell(
                  onTap:
                      _pickFile, // Cliccando sul visualizzatore, si può scegliere un nuovo file
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 50,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chosen file: ${_selectedFile!.name}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF111416),
                          fontSize: 18,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Size: ${_formatFileSize(_selectedFile!.size)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6B7582),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Pulsante per rimuovere il file
                TextButton(
                  onPressed: _removeFile,
                  child: const Text(
                    'Remove file',
                    style: TextStyle(
                      color: Color(0xFFD94451),
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return InkWell(
      onTap: () {
        if (_selectedFile != null) {
          // TODO: Implement save functionality
        } else {
          // Do nothing
        }
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: (_selectedFile == null
              ? const Color(0xFF6B7582)
              : const Color(0xFF002C58)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Save',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
