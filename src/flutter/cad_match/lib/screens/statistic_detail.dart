import 'package:flutter/material.dart';
import 'ply_viewer_page.dart';
import '../utils.dart';

// Widget stateless per la pagina dei dettagli statistici
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
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0,
        title: const Text('Statistic Details'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.boxborder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _v(stats['name']),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${_v(stats['scanId'])}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: AppColors.boxborder),
                          const SizedBox(height: 10),
                          cardField(
                            'Accuracy',
                            _f(stats['accuracy'], 2, '%'),
                            Icons.speed_rounded,
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: AppColors.boxborder),
                          const SizedBox(height: 10),
                          cardField(
                            'Average deviation',
                            _f(stats['avg_deviation'], 3, 'mm'),
                            Icons.analytics_rounded,
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: AppColors.boxborder),
                          const SizedBox(height: 10),
                          cardField(
                            'Minimum deviation',
                            _f(stats['min_deviation'], 3, 'mm'),
                            Icons.arrow_circle_down_rounded,
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: AppColors.boxborder),
                          const SizedBox(height: 10),
                          cardField(
                            'Maximum deviation',
                            _f(stats['max_deviation'], 3, 'mm'),
                            Icons.arrow_circle_up_rounded,
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: AppColors.boxborder),
                          const SizedBox(height: 10),
                          cardField(
                            'Standard deviation',
                            _f(stats['std_deviation'], 3, 'mm'),
                            Icons.stacked_line_chart_rounded,
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: AppColors.boxborder),
                          const SizedBox(height: 10),
                          cardField(
                            'Percentage of points within tolerance',
                            _f(stats['ppwt'], 2, '%'),
                            Icons.check_circle_outline_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              buildButton(
                'VIEW 3D COMPARISON',
                icon: Icons.view_in_ar_rounded,
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
                      SnackBar(
                        content: Text(
                          'Scan ID not available.',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
