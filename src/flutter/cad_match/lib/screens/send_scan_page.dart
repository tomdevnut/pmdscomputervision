import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart'; // Importa il pacchetto uuid
import 'package:vector_math/vector_math_64.dart' as vector;
import '../utils.dart';

class SendScanPage extends StatefulWidget {
  final Map<String, dynamic> payload;
  final List<vector.Vector3> scannedPoints;

  const SendScanPage({
    super.key,
    required this.payload,
    required this.scannedPoints,
  });

  @override
  State<SendScanPage> createState() => _SendScanPageState();
}

class _SendScanPageState extends State<SendScanPage> {
  bool _isProcessing = false; // Stato per gestire il caricamento

  /// Genera un file .ply dai punti scansionati con un nome basato sull'ID.
  Future<File> _generatePLYFile(
    List<vector.Vector3> scannedPoints,
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

    // Colore arancione per i punti
    for (var point in scannedPoints) {
      plyContent.writeln('${point.x} ${point.y} ${point.z} 245 124 0');
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

    // Imposta i metadati richiesti dalla Cloud Function
    final metadata = SettableMetadata(
      customMetadata: {
        'user': user.uid,
        'step': widget.payload['stepId'] ?? 'None',
        'scan_name': widget.payload['name'] ?? 'Untitled Scan',
      },
    );

    await storageRef.putFile(file, metadata);
    await file.delete(); // Pulisce il file locale dopo l'upload
  }

  /// Gestisce l'intero processo di upload e navigazione.
  void _confirmAndUpload() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // 1. Genera un ID univoco usando il pacchetto uuid
      const uuid = Uuid();
      final scanId = uuid.v4();

      // 2. Genera il file .ply usando l'ID
      final plyFile = await _generatePLYFile(widget.scannedPoints, scanId);

      // 3. Carica il file su Firebase Storage con i metadati
      await _uploadToFirebase(plyFile, scanId);

      // 4. Naviga alla schermata principale solo dopo il successo
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
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
        elevation: 0.5,
        title: const Text('Confirm Scan'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.white),
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
                    _buildSummaryRow('Name:', widget.payload['name']),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Step:', widget.payload['stepName']),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Points captured:',
                      widget.scannedPoints.length.toString(),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isProcessing ? null : _confirmAndUpload,
                icon: _isProcessing
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _isProcessing ? 'Uploading...' : 'Confirm & Upload',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isProcessing ? null : _discardScan,
                child: const Text(
                  'Discard',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
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
