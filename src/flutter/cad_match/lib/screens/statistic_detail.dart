import 'package:flutter/material.dart';
import '../utils.dart';

// Widget stateless per la pagina dei dettagli
class StatisticDetailPage extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StatisticDetailPage({super.key, required this.stats});

  // Funzione helper per normalizzare i valori
  String _v(dynamic value) {
    return (value == null || (value is String && value.trim().isEmpty))
        ? '—'
        : value.toString();
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
                  cardField('Accuracy', _v(stats['accuracy'])),
                  const SizedBox(height: 20),
                  cardField('Average deviation', _v(stats['avg_deviation'])),
                  const SizedBox(height: 20),
                  cardField('Minimum deviation', _v(stats['min_deviation'])),
                  const SizedBox(height: 20),
                  cardField('Maximum deviation', _v(stats['max_deviation'])),
                  const SizedBox(height: 20),
                  cardField('Standard deviation', _v(stats['std_deviation'])),
                  const SizedBox(height: 20),
                  cardField('Percentage of points within tolerance', _v(stats['ppwt'])),
                ],
              ),
            ),
            // TODO: visualizzatore della statistica 3D
          ],
        ),
      ),
    );
  }
}
