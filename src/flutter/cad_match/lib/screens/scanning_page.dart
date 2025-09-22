import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as vector;
import 'lidar_view.dart';
import 'send_scan_page.dart';
import '../utils.dart';

class LidarScannerScreen extends StatefulWidget {
  final Map<String, dynamic> payload;
  const LidarScannerScreen({super.key, required this.payload});

  @override
  State<LidarScannerScreen> createState() => _LidarScannerScreenState();
}

class _LidarScannerScreenState extends State<LidarScannerScreen> {
  final scannedPoints = <vector.Vector3>[];
  bool isScanning = false;
  String? scanStatus = 'Ready to scan';
  final int recommendedPoints = 15000; // recommended for large objects
  final int minPointsToSave = 1500; // minimum to save something useful
  double minPointDistance = 0.01; // 1 cm
  double maxScanDistance =
      6.0; // 6 m (LiDAR reaches up to ~5m, let's leave a margin)
  Timer? uiTick;
  final _lidarKey = GlobalKey<LidarViewState>();
  DateTime? _lastPointsAt;

  @override
  void initState() {
    super.initState();
    uiTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        // update warning / progress status
      });
    });
  }

  @override
  void dispose() {
    uiTick?.cancel();
    super.dispose();
  }

  void _onPoints(List<vector.Vector3> pts) {
    if (!isScanning) return;
    _lastPointsAt = DateTime.now();

    for (final p in pts) {
      // Niente filtro su distanza dal mondo: nativo ha già filtrato d ∈ (0, 8]
      if (scannedPoints.isEmpty ||
          scannedPoints.last.distanceTo(p) >= minPointDistance) {
        scannedPoints.add(p);
      }
    }

    if (scannedPoints.length % 50 == 0) {
      setState(() => scanStatus = 'Scanning... ${scannedPoints.length} points');
    }
  }

  void toggleScanning() {
    setState(() {
      isScanning = !isScanning;
      if (isScanning) {
        scanStatus = 'Scanning... Move slowly around the part';
        _lidarKey.currentState?.start();
      } else {
        scanStatus = 'Scan paused - ${scannedPoints.length} points';
        _lidarKey.currentState?.stop();
      }
    });
  }

  void resetScan() {
    setState(() {
      isScanning = false;
      scannedPoints.clear();
      scanStatus = 'Ready to scan';
      _lastPointsAt = null;
    });
    _lidarKey.currentState?.reset();
  }

  void _onSaveScan() {
    if (scannedPoints.length < minPointsToSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'At least $minPointsToSave points are needed for a decent result',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            SendScanPage(payload: widget.payload, scannedPoints: scannedPoints),
      ),
    );
  }

  bool get _noPointsRecently {
    if (!isScanning) return false;
    if (_lastPointsAt == null) return true;
    return DateTime.now().difference(_lastPointsAt!).inSeconds >= 2;
  }

  @override
  Widget build(BuildContext context) {
    final progress = (scannedPoints.length / recommendedPoints).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0,
        title: Text(widget.payload['name'] ?? 'New Scan'),
      ),
      body: Stack(
        children: [
          LidarView(key: _lidarKey, onPoints: _onPoints),
          _buildUIOverlay(progress),
          if (isScanning) _buildScanningGuide(progress),
        ],
      ),
    );
  }

  Widget _buildScanningGuide(double progress) {
    return Center(
      child: CustomPaint(
        size: const Size(200, 200),
        painter: ScanningGuidePainter(progress: progress),
      ),
    );
  }

  Widget _buildUIOverlay(double progress) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Barra stato compatta
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withAlpha(204),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  scanStatus ?? 'Ready to scan',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Before starting: show tips
                if (!isScanning) ...[
                  const Text(
                    'Tips for large parts:\n'
                    '• Keep 0.5–2.5 m from the part.\n'
                    '• Move slowly and cover the entire perimeter.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Goal: $recommendedPoints points (recommended)',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],

                // During scanning: show only counter + progress
                if (isScanning) ...[
                  Text(
                    'Points: ${scannedPoints.length} / $recommendedPoints',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],

                const SizedBox(height: 8),

                LinearProgressIndicator(
                  value: math.max(0.02, progress),
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),

                // Warning "no points" with text wrapping (no overflow)
                if (_noPointsRecently) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'No points from LiDAR. Get closer to the part or move slowly.',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Additional tips: show ONLY before starting
          if (!isScanning)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Cover all surfaces, especially the edges.\nAvoid sudden movements.',
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

          // Controls
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSideButton(
                  icon: Icons.refresh_rounded,
                  onPressed: resetScan,
                  label: 'Reset',
                ),
                _buildMainScanButton(),
                _buildSideButton(
                  icon: Icons.check_rounded,
                  onPressed: scannedPoints.length >= minPointsToSave
                      ? _onSaveScan
                      : null,
                  label: 'Save',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainScanButton() {
    return GestureDetector(
      onTap: toggleScanning,
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: AppColors.textPrimary.withAlpha(128),
            width: 5,
          ),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isScanning ? 30 : 60,
            height: isScanning ? 30 : 60,
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(isScanning ? 8 : 30),
            ),
          ),
        ),
      ),
    );
  }

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
                backgroundColor: AppColors.cardBackground.withAlpha(204),
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
}

class ScanningGuidePainter extends CustomPainter {
  final double progress;
  ScanningGuidePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );

    paint.color = AppColors.primary;
    paint.strokeWidth = 4;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant ScanningGuidePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
