import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../shared_utils.dart';

class BulkUpload extends StatefulWidget {
  const BulkUpload({super.key});

  @override
  State<BulkUpload> createState() => _BulkUploadState();
}

class _BulkUploadState extends State<BulkUpload> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  final String _functionUrl =
      'https://bulk-create-users-5ja5umnfkq-ey.a.run.app';

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        if (result.files.first.extension?.toLowerCase() != 'csv') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a CSV file.'),
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

  Future<void> _uploadFile() async {
    if (_selectedFile == null || _isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated.');
      }
      final idToken = await user.getIdToken();

      var request = http.MultipartRequest('POST', Uri.parse(_functionUrl));

      // The key change: handle both bytes (web) and path (mobile/desktop)
      final http.MultipartFile multipartFile;
      if (_selectedFile!.bytes != null) {
        multipartFile = http.MultipartFile.fromBytes(
          'file',
          _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        );
      } else if (_selectedFile!.path != null) {
        multipartFile = await http.MultipartFile.fromPath(
          'file',
          _selectedFile!.path!,
        );
      } else {
        throw Exception('Selected file has no data.');
      }
      request.files.add(multipartFile);

      request.headers.addAll({'Authorization': 'Bearer $idToken'});

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      final decodedResponse = json.decode(responseBody);
      final status = decodedResponse['status'];
      final message = decodedResponse['message'];

      if (status == 'success') {
        final data = decodedResponse['data'];
        final successCount = data['success_count'];
        final failureCount = data['failure_count'];
        String snackBarMessage =
            'Creation completed: $successCount successful, $failureCount failed.';

        if (failureCount > 0) {
          final failedUsers = data['failed_users'] as List;
          snackBarMessage +=
              ' Failures: ${failedUsers.map((e) => e['email']).join(', ')}';

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(snackBarMessage),
                backgroundColor: AppColors.red,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(snackBarMessage),
                backgroundColor: AppColors.green,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
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
              buildTopBar(context, title: 'BULK UPLOAD'),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 600,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'The CSV file must contain the following columns: email, password, level, name, surname.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
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
                              label: 'Upload CSV File',
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
                    label: _isUploading ? 'Uploading...' : 'Create users',
                    icon: (_selectedFile != null && !_isUploading)
                        ? Icons.check_circle
                        : Icons.cancel,
                    onTap: _uploadFile,
                    isEnabled: _selectedFile != null && !_isUploading,
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
