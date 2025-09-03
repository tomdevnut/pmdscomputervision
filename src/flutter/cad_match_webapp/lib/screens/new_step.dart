import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
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
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSnackbar({required String message, bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppColors.white)),
        backgroundColor: isError ? AppColors.red : AppColors.green,
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        if (result.files.first.extension?.toLowerCase() != 'step') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a .step file.'),
                backgroundColor: AppColors.red,
              ),
            );
          }
          return;
        }
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(
          message: 'Error during file selection: $e',
          isError: true,
        );
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

  Future<void> _uploadStep() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || description.isEmpty) {
      _showSnackbar(
        message: 'Add a name and description first.',
        isError: true,
      );
      return;
    }

    if (_selectedFile == null) {
      _showSnackbar(message: 'Please select a file to upload.', isError: true);
      return;
    }

    final fileName = _selectedFile!.name.toLowerCase();
    if (!fileName.endsWith('.step')) {
      _showSnackbar(
        message: 'Invalid file format. Please upload a .step file.',
        isError: true,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackbar(
        message: 'User is not authenticated. Unable to upload file.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final String fileId = const Uuid().v4();
      final String filePath = 'steps/$fileId.step';
      final storageRef = FirebaseStorage.instance.ref().child(filePath);

      final metadata = SettableMetadata(
        customMetadata: {
          'user': user.uid,
          'name': name,
          'description': description,
        },
      );

      final uploadTask = storageRef.putData(_selectedFile!.bytes!, metadata);

      await uploadTask;

      _showSnackbar(message: 'File uploaded successfully!');
      if (mounted) {
        _nameController.clear();
        _descriptionController.clear();
        _removeFile();
      }
    } on FirebaseException catch (e) {
      _showSnackbar(message: 'Firebase Error: ${e.message}', isError: true);
    } catch (e) {
      _showSnackbar(message: 'Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
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
              buildTopBar(context, title: 'UPLOAD A NEW STEP'),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 600,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.file_copy,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'File',
                                style: TextStyle(
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
                    label: _isUploading ? 'Uploading...' : 'Create step',
                    icon: _isUploading
                        ? Icons.hourglass_empty
                        : _selectedFile == null
                        ? Icons.cancel
                        : Icons.check_circle,
                    onTap: _isUploading
                        ? () {}
                        : _selectedFile == null
                        ? () {
                            _showSnackbar(
                              message: 'Please upload a step first.',
                              isError: true,
                            );
                          }
                        : _uploadStep,
                    backgroundColor: _selectedFile == null
                        ? AppColors.disabledButton
                        : AppColors.secondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileDetails() {
    if (_selectedFile == null) return const SizedBox.shrink();
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
