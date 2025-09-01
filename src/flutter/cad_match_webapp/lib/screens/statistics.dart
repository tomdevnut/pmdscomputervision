import 'package:flutter/material.dart';
import '../shared_utils.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

    Future<void> downloadFile() async {
    try {
      // Get the download URL of the file from Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(
        'scans/${widget.scanid}.ply',
      );
      final url = await ref.getDownloadURL();

      // Use the dart:js package to open the URL in a new window/tab, triggering the download.
      openUrl(url, '_blank');

      // Show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File download started successfully.'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } on FirebaseException catch (e) {
      // Handle the case where the file does not exist
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
        // Handle other Firebase errors
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
      // Handle any other unexpected errors
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
          child: Column(
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
                                value: '95%',
                                icon: Icons.check_circle,
                              ),
                              const SizedBox(height: 24),
                              buildInfoField(
                                label: 'Average Deviation',
                                value: '2.5%',
                                icon: Icons.stacked_line_chart,
                              ),
                              const SizedBox(height: 24),
                              buildInfoField(
                                label: 'Maximum Deviation',
                                value: '5%',
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
                                value: '1.5%',
                                icon: Icons.arrow_circle_down,
                              ),
                              const SizedBox(height: 24),
                              buildInfoField(
                                label: 'Standard Deviation',
                                value: '2.0%',
                                icon: Icons.analytics,
                              ),
                              const SizedBox(height: 24),
                              buildInfoField(
                                label: 'Percentage of Points within Tolerance',
                                value: '88%',
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
                          value: '95%',
                          icon: Icons.check_circle,
                        ),
                        const SizedBox(height: 24),
                        buildInfoField(
                          label: 'Average Deviation',
                          value: '2.5%',
                          icon: Icons.stacked_line_chart,
                        ),
                        const SizedBox(height: 24),
                        buildInfoField(
                          label: 'Maximum Deviation',
                          value: '5%',
                          icon: Icons.arrow_circle_up,
                        ),
                        const SizedBox(height: 24),
                        buildInfoField(
                          label: 'Minimum Deviation',
                          value: '1.5%',
                          icon: Icons.arrow_circle_down,
                        ),
                        const SizedBox(height: 24),
                        buildInfoField(
                          label: 'Standard Deviation',
                          value: '2.0%',
                          icon: Icons.analytics,
                        ),
                        const SizedBox(height: 24),
                        buildInfoField(
                          label: 'Percentage of Points within Tolerance',
                          value: '88%',
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
          ),
        ),
      ),
    );
  }
}
