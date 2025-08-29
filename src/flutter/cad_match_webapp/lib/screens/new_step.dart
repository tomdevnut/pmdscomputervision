import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../shared_utils.dart'; // Importa il file di utility condiviso

class StepUpload extends StatefulWidget {
  const StepUpload({super.key});

  @override
  State<StepUpload> createState() => _StepUploadState();
}

class _StepUploadState extends State<StepUpload> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  PlatformFile? _selectedFile;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
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
      backgroundColor: AppColors.lightBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Utilizzo della funzione buildTopBar da shared_utils.dart
              buildTopBar(
                context,
                title: 'UPLOAD A NEW STEP',
                mainPageIndex: 1,
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Utilizzo della funzione buildInputField da shared_utils.dart
                        buildInputField(
                          label: 'Name',
                          icon: Icons.abc,
                          hintText: 'Enter a step name',
                          controller: _nameController,
                        ),
                        const SizedBox(height: 24),
                        // Utilizzo della funzione buildInputField per la descrizione
                        buildInputField(
                          label: 'Description',
                          icon: Icons.description,
                          hintText: 'Enter a description',
                          controller: _descriptionController,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Sezione di caricamento del file
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Upload File',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_selectedFile == null)
                          _buildUploadButton()
                        else
                          _buildFileDetails(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildButton(
                    label: 'Save',
                    onTap: () {
                      if (_selectedFile != null) {
                        // TODO: Implementare la logica di salvataggio
                      }
                    },
                    isEnabled: _selectedFile != null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Costruisce il pulsante per il caricamento del file
  Widget _buildUploadButton() {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Upload File',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // Costruisce la visualizzazione dei dettagli del file caricato
  Widget _buildFileDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedFile!.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Size: ${_formatFileSize(_selectedFile!.size)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _removeFile,
            child: const Text(
              'Remove file',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
