import 'package:flutter/material.dart';
import '../shared_utils.dart';

class Statistics extends StatelessWidget {
  const Statistics({super.key});

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
                      // TODO: Logica per scaricare il file confrontato
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
