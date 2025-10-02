import 'package:flutter/material.dart';
import 'dart:async';
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
  final scannedPoints = <LidarPoint>[];
  bool isScanning = false;
  String? scanStatusMessage = 'Ready to scan';
  final int recommendedPoints = 50000;
  final int minPointsToSave = 10000;
  Timer? uiTick;
  final _lidarKey = GlobalKey<LidarViewState>();
  DateTime? _lastPointsAt;

  @override
  void initState() {
    super.initState();
    uiTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          // Forza un rebuild per aggiornare l'avviso _noPointsRecently
        });
      }
    });
  }

  @override
  void dispose() {
    uiTick?.cancel();
    _lidarKey.currentState?.stop();
    super.dispose();
  }

  // --- LOGICA DI CONTROLLO ---
  void _onPoints(List<LidarPoint> pts) {
    if (!isScanning || !mounted) return;
    _lastPointsAt = DateTime.now();
    scannedPoints.addAll(pts);
    setState(() {
      scanStatusMessage = 'Scanning...';
    });
  }

  void toggleScanning() {
    setState(() {
      isScanning = !isScanning;
      if (isScanning) {
        scanStatusMessage = 'Scanning... Move slowly';
        _lidarKey.currentState?.start();
      } else {
        scanStatusMessage = 'Scan paused';
        _lidarKey.currentState?.stop();
      }
    });
  }

  void resetScan() {
    showConfirmationDialog(
      context,
      'Are you sure you want to discard all scanned points?',
      () {
        if (mounted) {
          setState(() {
            isScanning = false;
            scannedPoints.clear();
            scanStatusMessage = 'Ready to scan';
            _lastPointsAt = null;
          });
        }
        _lidarKey.currentState?.reset();
        Navigator.of(context).pop(); // Chiude la dialog
      },
      title: 'Reset Scan',
      confirmText: 'Reset',
    );
  }

  void _onSaveScan() {
    if (scannedPoints.length < minPointsToSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('At least $minPointsToSave points are needed.'),
          backgroundColor: AppColors.error,
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
    if (!isScanning || _lastPointsAt == null) return false;
    return DateTime.now().difference(_lastPointsAt!).inSeconds >= 2;
  }

  void _cancelScan() {
    if (scannedPoints.isNotEmpty) {
      showConfirmationDialog(
        context,
        'Are you sure you want to cancel this scan and discard all points?',
        () {
          Navigator.of(context).pop(); // Chiude la dialog
          Navigator.of(context).pop(); // Torna alla pagina precedente
        },
        title: 'Cancel Scan',
        confirmText: 'Discard',
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (scannedPoints.length / recommendedPoints).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          LidarView(key: _lidarKey, onPoints: _onPoints),
          _buildHeader(),
          _buildFooter(progress),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.blackOverlay, Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 16, top: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: _cancelScan,
                ),
                Expanded(
                  child: Text(
                    widget.payload['name'] ?? 'New Scan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 40), // Spazio per bilanciare l'IconButton
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(double progress) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [AppColors.blackOverlay, Colors.transparent],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Column(
              children: [
                if (_noPointsRecently) _buildWarningBanner(),

                _buildStatusInfo(progress),

                _buildControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'No new points. Get closer or check for obstacles.',
              style: TextStyle(color: AppColors.warning, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Text(
            scanStatusMessage ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${scannedPoints.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                ' / $recommendedPoints recommended points',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.buttonTextSemiTransparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.9 ? AppColors.success : AppColors.primary,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSideButton(
            icon: Icons.refresh_rounded,
            onPressed: isScanning ? null : resetScan,
            label: 'Reset',
          ),
          _buildMainScanButton(),
          _buildSideButton(
            icon: Icons.check_rounded,
            onPressed: isScanning || scannedPoints.length < minPointsToSave
                ? null
                : _onSaveScan,
            label: 'Save',
          ),
        ],
      ),
    );
  }

  Widget _buildMainScanButton() {
    return GestureDetector(
      onTap: toggleScanning,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadows,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isScanning ? 32 : 70,
            height: isScanning ? 32 : 70,
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(isScanning ? 8 : 35),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideButton({
    required IconData icon,
    VoidCallback? onPressed,
    required String label,
  }) {
    final bool isEnabled = onPressed != null;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.buttonTextSemiTransparent,
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
