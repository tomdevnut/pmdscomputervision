import 'package:flutter/material.dart';
import 'ply_viewer_page.dart';
import '../utils.dart';

class StatisticDetailPage extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StatisticDetailPage({super.key, required this.stats});

  String _v(dynamic value) {
    return (value == null || (value is String && value.trim().isEmpty))
        ? '—'
        : value.toString();
  }

  String _f(dynamic value, int decimals, String unit) {
    if (value == null || value is! num) return '—';
    return '${value.toStringAsFixed(decimals)} $unit';
  }

  // Helper per determinare il colore in base all'accuratezza
  Color _getAccuracyColor(int accuracy) {
    if (accuracy < 50) {
      return AppColors.error;
    } else if (accuracy < 80) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = (stats['accuracy'] as num?)?.toInt() ?? 0;
    final accuracyColor = _getAccuracyColor(accuracy);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.buttonText,
        leadingWidth: 72, // Spazio per la freccia di back
        titleSpacing: 0, // Annulla lo spazio di default per allineare il titolo
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              MainAxisAlignment.center, // Centra verticalmente il titolo
          children: [
            Text(
              _v(stats['name']),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'ID: ${_v(stats['scanId'])}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.buttonTextSemiTransparent,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAccuracyIndicator(accuracy, accuracyColor),
                      const SizedBox(height: 32),
                      buildButton(
                        'VIEW 3D COMPARISON',
                        onPressed: () => _navigateToPlyViewer(context),
                      ),
                      const SizedBox(height: 24),
                      _buildStatsDetailsCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyIndicator(int accuracy, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Accuracy',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '$accuracy%',
            style: TextStyle(
              color: color,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: accuracy / 100.0,
              minHeight: 12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              backgroundColor: color.withAlpha(50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsDetailsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
            Icons.analytics_rounded,
            'Average deviation',
            _f(stats['avg_deviation'], 3, 'mm'),
          ),
          const Divider(),
          _buildInfoRow(
            Icons.arrow_circle_down_rounded,
            'Minimum deviation',
            _f(stats['min_deviation'], 3, 'mm'),
          ),
          const Divider(),
          _buildInfoRow(
            Icons.arrow_circle_up_rounded,
            'Maximum deviation',
            _f(stats['max_deviation'], 3, 'mm'),
          ),
          const Divider(),
          _buildInfoRow(
            Icons.stacked_line_chart_rounded,
            'Standard deviation',
            _f(stats['std_deviation'], 3, 'mm'),
          ),
          const Divider(),
          _buildInfoRow(
            Icons.check_circle_outline_rounded,
            'Points within tolerance',
            _f(stats['ppwt'], 2, '%'),
          ),
        ],
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
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPlyViewer(BuildContext context) {
    final scanId = stats['scanId'];
    if (scanId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PlyViewerPage(scanId: scanId)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scan ID not available.',
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
  }
}
