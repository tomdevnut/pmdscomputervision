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

  /// Genera un file .ply dai punti scansionati.
  Future<File> _generatePLYFile(
    List<LidarPoint> scannedPoints,
    String scanId,
  ) async {
    StringBuffer plyContent = StringBuffer();
    plyContent.writeln('ply');
    plyContent.writeln('format ascii 1.0');
    plyContent.writeln('element vertex ${scannedPoints.length}');
    plyContent.writeln('property float x');
    plyContent.writeln('property float y');
    plyContent.writeln('property float z');
    plyContent.writeln('property uchar red');
    plyContent.writeln('property uchar green');
    plyContent.writeln('property uchar blue');
    plyContent.writeln('end_header');

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

  /// Carica il file su Firebase Storage con i metadati corretti.
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

  /// Gestisce l'intero processo di upload e navigazione.
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
          const SnackBar(
            content: Text(
              'Upload successful! Your scan is being processed.',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      String message;
      if (e.toString().contains("network error")) {
        message = 'A network error occurred. Please check your connection.';
      } else {
        message = 'Upload failed: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: const TextStyle(color: AppColors.textPrimary),
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

  /// Scarta la scansione e naviga alla Home.
  void _discardScan() {
    if (_isProcessing) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Confirm Scan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.textPrimary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scan Summary',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Name:', widget.payload['name'] ?? 'N/A'),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Step:',
                      widget.payload['stepName'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Points captured:',
                      widget.scannedPoints.length.toString(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50), // Spazio fisso invece dello Spacer
              buildButton(
                _isProcessing ? 'UPLOADING...' : 'CONFIRM & UPLOAD',
                color: AppColors.primary,
                icon: Icons.cloud_upload_rounded,
                onPressed: _isProcessing ? () {} : _confirmAndUpload,
              ),
              const SizedBox(height: 12),
              buildButton(
                'DISCARD',
                onPressed: _isProcessing ? () {} : _discardScan,
                color: AppColors.error,
                icon: Icons.delete_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
