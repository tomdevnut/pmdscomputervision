import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../shared_utils.dart';

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

  // Funzione per selezionare un file dal dispositivo
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

  // Funzione per rimuovere il file selezionato
  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  // Funzione per formattare la dimensione del file
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
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTopBar(
                context,
                title: 'UPLOAD A NEW STEP',
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 600, // Imposta una larghezza fissa per il contenuto
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildInputField(
                        label: 'Name',
                        icon: Icons.abc,
                        hintText: 'Enter a step name',
                        controller: _nameController,
                      ),
                      const SizedBox(height: 24),
                      buildInputField(
                        label: 'Description',
                        icon: Icons.description,
                        hintText: 'Enter a description',
                        controller: _descriptionController,
                      ),
                      const SizedBox(height: 24),
                      // Sezione di caricamento del file
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Container for the icon
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.file_copy,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Label text
                              Text(
                                'File',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_selectedFile == null)
                            buildButton(
                              label: 'Upload File',
                              onTap: _pickFile,
                              icon: Icons.upload_file,
                              backgroundColor: AppColors.primary,
                            )
                          else
                            _buildFileDetails(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildButton(
                    label: 'Create step',
                    icon: Icons.check_circle,
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
              const Icon(Icons.check_circle, color: AppColors.green),
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
                color: AppColors.red,
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
