import 'package:flutter/material.dart';
import '../shared_utils.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:js_interop';

@JS('window.open')
external void openUrl(String url, String target);

class Statistics extends StatefulWidget {
  final String scanid;
  const Statistics({super.key, required this.scanid});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  Future<DocumentSnapshot>? _scanDataFuture;

  @override
  void initState() {
    super.initState();
    _scanDataFuture = FirebaseFirestore.instance
        .collection('stats')
        .doc(widget.scanid)
        .get();
  }

  Future<void> downloadFile() async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'comparisons/${widget.scanid}.ply',
      );
      final url = await ref.getDownloadURL();

      openUrl(url, '_blank');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File download started successfully.'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('The file was not found.'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'An error occurred while downloading the file: ${e.message}',
              ),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showResultDialog(context, 'Error', 'An unexpected error occurred: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: FutureBuilder<DocumentSnapshot>(
            future: _scanDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(
                  child: Text('No statistics found for this scan.'),
                );
              }

              final statistics = snapshot.data!.data() as Map<String, dynamic>?;

              if (statistics == null || statistics.isEmpty) {
                return const Center(
                  child: Text('No statistics found for this scan.'),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTopBar(context, title: 'SCAN STATISTICS'),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildInfoField(
                                    label: 'Accuracy',
                                    value:
                                        '${(statistics['accuracy'] ?? 'N/A')}',
                                    icon: Icons.check_circle,
                                  ),
                                  const SizedBox(height: 24),
                                  buildInfoField(
                                    label: 'Average Deviation',
                                    value:
                                        '${(statistics['avg_deviation'] ?? 'N/A')}',
                                    icon: Icons.stacked_line_chart,
                                  ),
                                  const SizedBox(height: 24),
                                  buildInfoField(
                                    label: 'Maximum Deviation',
                                    value:
                                        '${(statistics['max_deviation'] ?? 'N/A')}',
                                    icon: Icons.arrow_circle_up,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildInfoField(
                                    label: 'Minimum Deviation',
                                    value:
                                        '${(statistics['min_deviation'] ?? 'N/A')}',
                                    icon: Icons.arrow_circle_down,
                                  ),
                                  const SizedBox(height: 24),
                                  buildInfoField(
                                    label: 'Standard Deviation',
                                    value:
                                        '${(statistics['std_deviation'] ?? 'N/A')}',
                                    icon: Icons.analytics,
                                  ),
                                  const SizedBox(height: 24),
                                  buildInfoField(
                                    label:
                                        'Percentage of Points within Tolerance',
                                    value:
                                        '${(statistics['ppwt'] ?? 'N/A')}',
                                    icon: Icons.percent,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildInfoField(
                              label: 'Accuracy',
                              value: '${(statistics['accuracy'] ?? 'N/A')}',
                              icon: Icons.check_circle,
                            ),
                            const SizedBox(height: 24),
                            buildInfoField(
                              label: 'Average Deviation',
                              value:
                                  '${(statistics['avg_deviation'] ?? 'N/A')}',
                              icon: Icons.stacked_line_chart,
                            ),
                            const SizedBox(height: 24),
                            buildInfoField(
                              label: 'Maximum Deviation',
                              value: '${(statistics['max_deviation'] ?? 'N/A')}',
                              icon: Icons.arrow_circle_up,
                            ),
                            const SizedBox(height: 24),
                            buildInfoField(
                              label: 'Minimum Deviation',
                              value: '${(statistics['min_deviation'] ?? 'N/A')}',
                              icon: Icons.arrow_circle_down,
                            ),
                            const SizedBox(height: 24),
                            buildInfoField(
                              label: 'Standard Deviation',
                              value:
                                  '${(statistics['std_deviation'] ?? 'N/A')}',
                              icon: Icons.analytics,
                            ),
                            const SizedBox(height: 24),
                            buildInfoField(
                              label: 'Percentage of Points within Tolerance',
                              value:
                                  '${(statistics['ppwt'] ?? 'N/A')}',
                              icon: Icons.percent,
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(width: 12),
                      buildButton(
                        label: 'Download Compared File',
                        icon: Icons.download,
                        onTap: () {
                          downloadFile();
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
