// scanning_page.dart
import 'package:flutter/material.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;
import 'send_scan_page.dart';
import '../utils.dart';

class LidarScannerScreen extends StatefulWidget {
  final Map<String, dynamic> payload;

  const LidarScannerScreen({super.key, required this.payload});

  @override
  _LidarScannerScreenState createState() => _LidarScannerScreenState();
}

class _LidarScannerScreenState extends State<LidarScannerScreen> {
  late ARKitController arkitController;
  bool isScanning = false;
  String? scanStatus;
  List<vector.Vector3> scannedPoints = [];
  List<ARKitNode> visualNodes = [];

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
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
        title: Text(widget.payload['name'] ?? 'New Scan'),
      ),
      body: Stack(
        children: [
          ARKitSceneView(
            onARKitViewCreated: onARKitViewCreated,
            configuration: ARKitConfiguration.worldTracking,
            showFeaturePoints: true,
            planeDetection: ARPlaneDetection.horizontal,
          ),
          _buildUIOverlay(),
        ],
      ),
    );
  }

  Widget _buildUIOverlay() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Barra di stato in alto
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              scanStatus ?? 'Ready to scan',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Controlli in basso
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Pulsante Reset
                _buildSideButton(
                  icon: Icons.refresh,
                  onPressed: resetScan,
                  label: 'Reset',
                ),

                // Pulsante Start/Stop Stile iOS
                _buildMainScanButton(),

                // Pulsante Salva
                _buildSideButton(
                  icon: Icons.check,
                  onPressed: scannedPoints.isNotEmpty ? _onSaveScan : null,
                  label: 'Save',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NUOVO: Widget per il pulsante principale stile iOS
  Widget _buildMainScanButton() {
    return GestureDetector(
      onTap: toggleScanning,
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 5),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isScanning ? 30 : 60,
            height: isScanning ? 30 : 60,
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(isScanning ? 8 : 30),
            ),
          ),
        ),
      ),
    );
  }

  // MODIFICATO: Widget per i bottoni laterali
  Widget _buildSideButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String label,
  }) {
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cardBackground.withOpacity(0.8),
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  void onARKitViewCreated(ARKitController controller) {
    arkitController = controller;
    arkitController.onUpdateNodeForAnchor = (anchor) {
      if (isScanning) {
        final position = vector.Vector3(
          anchor.transform.getColumn(3).x,
          anchor.transform.getColumn(3).y,
          anchor.transform.getColumn(3).z,
        );
        addScannedPoint(position);
      }
    };
    setState(() {
      scanStatus = 'Aim the object and press Start';
    });
  }

  void addScannedPoint(vector.Vector3 position) {
    const minDistance = 0.01;
    if (scannedPoints.any((p) => p.distanceTo(position) < minDistance)) return;

    scannedPoints.add(position);

    final node = ARKitNode(
      geometry: ARKitSphere(
        radius: 0.003,
        materials: [
          ARKitMaterial(
            diffuse: ARKitMaterialProperty.color(AppColors.primary),
          ),
        ],
      ),
      position: position,
    );
    visualNodes.add(node);
    arkitController.add(node);

    if (scannedPoints.length % 50 == 0) {
      setState(() {
        scanStatus = 'Scanning... ${scannedPoints.length} points';
      });
    }
  }

  // NUOVA: Funzione privata per pulire i dati
  void _clearScanData() {
    for (var node in visualNodes) {
      arkitController.remove(node.name);
    }
    visualNodes.clear();
    scannedPoints.clear();
  }

  // MODIFICATO: Logica di Start/Stop corretta
  void toggleScanning() {
    setState(() {
      isScanning = !isScanning;
      if (isScanning) {
        _clearScanData(); // Pulisce la scansione precedente
        scanStatus = 'Scanning...';
        startAutomaticScanning();
      } else {
        scanStatus = 'Scan paused - ${scannedPoints.length} points acquired';
      }
    });
  }

  void startAutomaticScanning() {
    if (!isScanning) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!isScanning) return;
      final random = math.Random();
      final point = vector.Vector3(
        (random.nextDouble() - 0.5) * 1.0,
        (random.nextDouble() - 0.5) * 1.0,
        -0.5 - random.nextDouble() * 1.5,
      );
      addScannedPoint(point);

      if (scannedPoints.length < 2000) {
        startAutomaticScanning();
      } else {
        setState(() {
          isScanning = false;
          scanStatus = 'Scan completed with ${scannedPoints.length} points';
        });
      }
    });
  }

  // MODIFICATO: Logica di Reset corretta
  void resetScan() {
    setState(() {
      if (isScanning) isScanning = false;
      _clearScanData();
      scanStatus = 'Ready to scan';
    });
  }

  void _onSaveScan() {
    if (scannedPoints.isEmpty) return;

    if (isScanning) {
      setState(() {
        isScanning = false;
        scanStatus = 'Scan paused - ${scannedPoints.length} points acquired';
      });
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            SendScanPage(payload: widget.payload, scannedPoints: scannedPoints),
      ),
    );
  }
}
