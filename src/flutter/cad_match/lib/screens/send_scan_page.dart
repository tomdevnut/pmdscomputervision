import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../utils.dart';
import 'lidar_view.dart';

class SendScanPage extends StatefulWidget {
  final Map<String, dynamic> payload;
  final List<LidarPoint> scannedPoints;

  const SendScanPage({
    super.key,
    required this.payload,
    required this.scannedPoints,
  });

  @override
  State<SendScanPage> createState() => _SendScanPageState();
}

class _SendScanPageState extends State<SendScanPage> {
  bool _isProcessing = false;

  Future<File> _generatePLYFile(
    List<LidarPoint> scannedPoints,
    String scanId,
  ) async {
    final plyContent = StringBuffer()
      ..writeln('ply')
      ..writeln('format ascii 1.0')
      ..writeln('element vertex ${scannedPoints.length}')
      ..writeln('property float x')
      ..writeln('property float y')
      ..writeln('property float z')
      ..writeln('property uchar red')
      ..writeln('property uchar green')
      ..writeln('property uchar blue')
      ..writeln('end_header');

    for (var point in scannedPoints) {
      final pos = point.position;
      plyContent.writeln(
        '${pos.x} ${pos.y} ${pos.z} ${point.r} ${point.g} ${point.b}',
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$scanId.ply');
    await file.writeAsString(plyContent.toString());
    return file;
  }

  Future<void> _uploadToFirebase(File file, String scanId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not authenticated.");
    }

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('scans')
        .child('$scanId.ply');
    final metadata = SettableMetadata(
      customMetadata: {
        'user': user.uid,
        'step': widget.payload['stepId'] ?? 'None',
        'scan_name': widget.payload['name'] ?? 'Untitled Scan',
      },
    );

    await storageRef.putFile(file, metadata);
    await file.delete();
  }

  void _confirmAndUpload() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        throw Exception("User not authenticated.");
      }

      const uuid = Uuid();
      final scanId = uuid.v4();
      final plyFile = await _generatePLYFile(widget.scannedPoints, scanId);
      await _uploadToFirebase(plyFile, scanId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload successful! Your scan is being processed.',
              style: TextStyle(color: AppColors.buttonText),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      String message = 'Upload failed: ${e.toString()}';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: TextStyle(color: AppColors.buttonText),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _discardScan() {
    if (_isProcessing) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.buttonText,
        title: const Text(
          'Confirm Scan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // Rimuove il pulsante "indietro"
      ),
      body: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  children: [
                    const Text(
                      'Scan Summary',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please review the scan details before uploading.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadows,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.label_outline_rounded,
                            'Name',
                            widget.payload['name'] ?? 'N/A',
                          ),
                          const Divider(),
                          _buildInfoRow(
                            Icons.file_copy_outlined,
                            'Step',
                            widget.payload['stepName'] ?? 'N/A',
                          ),
                          const Divider(),
                          _buildInfoRow(
                            Icons.scatter_plot_rounded,
                            'Points captured',
                            widget.scannedPoints.length.toString(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  children: [
                    buildButton(
                      'CONFIRM & UPLOAD',
                      isLoading: _isProcessing,
                      onPressed: _confirmAndUpload,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isProcessing ? null : _discardScan,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
