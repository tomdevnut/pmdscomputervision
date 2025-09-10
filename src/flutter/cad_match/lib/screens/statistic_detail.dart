import 'package:flutter/material.dart';
import 'ply_viewer_page.dart';
import '../utils.dart';

// Widget stateless per la pagina dei dettagli
class StatisticDetailPage extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StatisticDetailPage({super.key, required this.stats});

  // Funzione helper per normalizzare i valori di testo
  String _v(dynamic value) {
    return (value == null || (value is String && value.trim().isEmpty))
        ? '—'
        : value.toString();
  }

  // Funzione helper per formattare i numeri con unità
  String _f(dynamic value, int decimals, String unit) {
    if (value == null || value is! num) return '—';
    return '${value.toStringAsFixed(decimals)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    const bg = AppColors.backgroundColor;
    const cardColor = AppColors.cardBackground;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        shadowColor: cardColor,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0.5,
        title: const Text('Statistic Details'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.white),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _v(stats['name']),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${_v(stats['scanId'])}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  cardField('Accuracy', _f(stats['accuracy'], 2, '%')),
                  const SizedBox(height: 20),
                  cardField(
                    'Average deviation',
                    _f(stats['avg_deviation'], 3, 'mm'),
                  ),
                  const SizedBox(height: 20),
                  cardField(
                    'Minimum deviation',
                    _f(stats['min_deviation'], 3, 'mm'),
                  ),
                  const SizedBox(height: 20),
                  cardField(
                    'Maximum deviation',
                    _f(stats['max_deviation'], 3, 'mm'),
                  ),
                  const SizedBox(height: 20),
                  cardField(
                    'Standard deviation',
                    _f(stats['std_deviation'], 3, 'mm'),
                  ),
                  const SizedBox(height: 20),
                  cardField(
                    'Percentage of points within tolerance',
                    _f(stats['ppwt'], 2, '%'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              // --- BOTTONE MODIFICATO ---
              child: ElevatedButton.icon(
                icon: const Icon(Icons.view_in_ar_rounded),
                label: const Text(
                  'VIEW 3D COMPARISON',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  final scanId = stats['scanId'];
                  if (scanId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlyViewerPage(scanId: scanId),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scan ID not available.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
