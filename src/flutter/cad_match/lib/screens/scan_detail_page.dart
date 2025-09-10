import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../utils.dart';
import 'statistic_detail.dart';

// Widget stateless per la pagina dei dettagli
class ScanDetailPage extends StatelessWidget {
  final Map<String, dynamic> scan;

  const ScanDetailPage({super.key, required this.scan});

  // Funzione helper per normalizzare i valori
  String _v(dynamic value) {
    return (value == null || (value is String && value.trim().isEmpty))
        ? '—'
        : value.toString();
  }

  // funzione per mostrare un messaggio di stato
  void showSnackBarMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = AppColors.backgroundColor;
    const cardColor = AppColors.cardBackground;
    final int status = scan['status'] as int? ?? -1;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        shadowColor: cardColor,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0.5,
        title: const Text('Scan Details'),
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
                    _v(scan['name']),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${_v(scan['scanId'])}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  cardField('Step Name', _v(scan['stepName'])),
                  const SizedBox(height: 14),
                  cardField('User', _v(scan['user'])),
                  const SizedBox(height: 14),
                  cardField(
                    'Timestamp',
                    _v(
                      (scan['timestamp'] is Timestamp)
                          ? DateFormat(
                              'yyyy-MM-dd HH:mm:ss',
                            ).format((scan['timestamp'] as Timestamp).toDate())
                          : '—',
                    ),
                  ),
                  const SizedBox(height: 14),
                  cardField('Status', getStatusString(status)),
                  const SizedBox(height: 14),
                  cardField('Progress', _v('${scan['progress']}%')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            buildButton(
              'VIEW STATISTICS',
              color: status == 2 ? AppColors.primary : AppColors.textSecondary,
              onPressed: () async {
                if (status == 2) {
                  try {
                    // Fetch dei dati dal database delle statistiche
                    final docId = _v(scan['scanId']);
                    final docSnapshot = await FirebaseFirestore.instance
                        .collection('stats')
                        .doc(docId)
                        .get();

                    if (docSnapshot.exists && docSnapshot.data() != null) {
                      final statsData = docSnapshot.data()!;
                      final accuracy =
                          (statsData['accuracy'] as num?)?.toDouble() ?? 0.0;
                      final name = scan['name'] as String? ?? 'Unknown';
                      final scanId = scan['scanId'] as String? ?? 'Unknown';
                      final minDeviation =
                          (statsData['min_deviation'] as num?)?.toDouble() ??
                          0.0;
                      final maxDeviation =
                          (statsData['max_deviation'] as num?)?.toDouble() ??
                          0.0;
                      final avgDeviation =
                          (statsData['avg_deviation'] as num?)?.toDouble() ??
                          0.0;
                      final stdDeviation =
                          (statsData['std_deviation'] as num?)?.toDouble() ??
                          0.0;
                      final ppwt =
                          (statsData['ppwt'] as num?)?.toDouble() ?? 0.0;
                      final statsMap = {
                        'name': name,
                        'scanId': scanId,
                        'accuracy': accuracy,
                        'min_deviation': minDeviation,
                        'max_deviation': maxDeviation,
                        'avg_deviation': avgDeviation,
                        'std_deviation': stdDeviation,
                        'ppwt': ppwt,
                      };

                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                StatisticDetailPage(stats: statsMap),
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        showSnackBarMessage(
                          context,
                          'No statistics available.',
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('Error fetching stats: $e');
                    if (context.mounted) {
                      showSnackBarMessage(
                        context,
                        'An error occurred while fetching statistics.',
                      );
                    }
                  }
                } else {
                  showSnackBarMessage(
                    context,
                    'Statistics are not available yet.',
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            buildButton(
              'DELETE SCAN',
              color: status == 2 || status == -1
                  ? AppColors.red
                  : AppColors.textSecondary,
              onPressed: () {
                if (status == 2 || status == -1) {
                  showConfirmationDialog(
                    context,
                    'Are you sure you want to delete this scan?',
                    () async {
                      await FirebaseStorage.instance
                          .ref('scans/${scan['scanId']}.ply')
                          .delete();
                      // Potrebbe essere necessario eliminare anche il documento da Firestore
                    },
                  );
                } else {
                  showSnackBarMessage(
                    context,
                    'Scan cannot be deleted until it is completed or has failed.',
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
