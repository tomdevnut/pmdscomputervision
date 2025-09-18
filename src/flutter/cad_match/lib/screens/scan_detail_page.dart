import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../utils.dart';
import 'statistic_detail.dart';

class ScanDetailPage extends StatelessWidget {
  final Map<String, dynamic> scan;

  const ScanDetailPage({super.key, required this.scan});

  String _v(dynamic value) {
    return (value == null || (value is String && value.trim().isEmpty))
        ? '—'
        : value.toString();
  }

  void showSnackBarMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: AppColors.textPrimary)), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
        elevation: 0,
        title: const Text('Scan Details'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.boxborder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _v(scan['name']),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${_v(scan['scanId'])}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: AppColors.boxborder),
                          const SizedBox(height: 10),
                          cardField(
                            'Step',
                            _v(scan['step']),
                            Icons.file_copy_rounded,
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: AppColors.boxborder),
                          const SizedBox(height: 10),
                          cardField('User', _v(scan['user']), Icons.person),
                          const SizedBox(height: 10),
                          const Divider(color: AppColors.boxborder),
                          const SizedBox(height: 10),
                          cardField(
                            'Time of upload',
                            _v(
                              (scan['timestamp'] is Timestamp)
                                  ? DateFormat('dd/MM/yyyy - HH:mm:ss').format(
                                      (scan['timestamp'] as Timestamp).toDate(),
                                    )
                                  : '—',
                            ),
                            Icons.access_time_rounded,
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: AppColors.boxborder),
                          const SizedBox(height: 10),
                          cardField(
                            'Current status',
                            getStatusString(status),
                            status == 2
                                ? Icons.check_circle_rounded
                                : status == 1
                                ? Icons.hourglass_top_rounded
                                : status == 0
                                ? Icons.inbox_rounded
                                : Icons.error_rounded,
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: AppColors.boxborder),
                          const SizedBox(height: 10),
                          cardField(
                            'Progress',
                            _v('${scan['progress']}%'),
                            Icons.percent_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [

                  Expanded(
                    child: buildButton(
                      'DELETE SCAN',
                      color: status == 2 || status == -1
                          ? AppColors.error
                          : AppColors.unselected,
                      onPressed: () {
                        if (status == 2 || status == -1) {
                          showConfirmationDialog(
                            context,
                            'Are you sure you want to delete this scan?',
                            () async {
                              await FirebaseStorage.instance
                                  .ref('scans/${scan['scanId']}.ply')
                                  .delete();
                            },
                          );
                        } else {
                          showSnackBarMessage(
                            context,
                            'Scan cannot be deleted until it is completed or has failed.',
                          );
                        }
                      },
                      icon: Icons.delete_rounded,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildButton(
                      'VIEW STATS',
                      color: status == 2
                          ? AppColors.primary
                          : AppColors.unselected,
                      icon: Icons.bar_chart_rounded,
                      onPressed: () async {
                        if (status == 2) {
                          try {
                            final docId = _v(scan['scanId']);
                            final docSnapshot = await FirebaseFirestore.instance
                                .collection('stats')
                                .doc(docId)
                                .get();

                            if (docSnapshot.exists &&
                                docSnapshot.data() != null) {
                              final statsData = docSnapshot.data()!;
                              final accuracy =
                                  (statsData['accuracy'] as num?)?.toDouble() ??
                                  0.0;
                              final name = scan['name'] as String? ?? 'Unknown';
                              final scanId =
                                  scan['scanId'] as String? ?? 'Unknown';
                              final minDeviation =
                                  (statsData['min_deviation'] as num?)
                                      ?.toDouble() ??
                                  0.0;
                              final maxDeviation =
                                  (statsData['max_deviation'] as num?)
                                      ?.toDouble() ??
                                  0.0;
                              final avgDeviation =
                                  (statsData['avg_deviation'] as num?)
                                      ?.toDouble() ??
                                  0.0;
                              final stdDeviation =
                                  (statsData['std_deviation'] as num?)
                                      ?.toDouble() ??
                                  0.0;
                              final ppwt =
                                  (statsData['ppwt'] as num?)?.toDouble() ??
                                  0.0;
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
                  ),                  
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
