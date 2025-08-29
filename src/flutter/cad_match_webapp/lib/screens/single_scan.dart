import 'package:flutter/material.dart';
import '../shared_utils.dart'; // Importa il file di utility condiviso

class SingleScan extends StatelessWidget {
  const SingleScan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTopBar(context, title: 'SCAN INFO'),
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
                                label: 'Name',
                                value: 'Scan 1',
                                icon: Icons.abc,
                              ),
                              const SizedBox(height: 24),
                              buildInfoField(
                                label: 'Date',
                                value: '2024-01-15',
                                icon: Icons.calendar_today,
                              ),
                              const SizedBox(height: 24),
                              buildInfoField(
                                label: 'User',
                                value: 'john.doe@example.com',
                                icon: Icons.person,
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
                                label: 'Status',
                                value: 'Completed',
                                icon: Icons.check_circle,
                              ),
                              const SizedBox(height: 24),
                              buildInfoField(
                                label: 'Step',
                                value: '123456789',
                                icon: Icons.tag,
                              ),
                              const SizedBox(height: 24),
                              buildInfoField(
                                label: 'Progress',
                                value: '100%',
                                icon: Icons.data_usage,
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
                          label: 'Name',
                          value: 'Scan 1',
                          icon: Icons.abc,
                        ),
                        const SizedBox(height: 24),
                        buildInfoField(
                          label: 'Date',
                          value: '2024-01-15',
                          icon: Icons.calendar_today,
                        ),
                        const SizedBox(height: 24),
                        buildInfoField(
                          label: 'User',
                          value: 'john.doe@example.com',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 24),
                        buildInfoField(
                          label: 'Status',
                          value: 'Completed',
                          icon: Icons.check_circle,
                        ),
                        const SizedBox(height: 24),
                        buildInfoField(
                          label: 'Step',
                          value: '123456789',
                          icon: Icons.tag,
                        ),
                        const SizedBox(height: 24),
                        buildInfoField(
                          label: 'Progress',
                          value: '100%',
                          icon: Icons.data_usage,
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
                  buildButton(
                    label: 'Delete Scan',
                    onTap: () => showConfirmationDialog(context: context, message: 'This action will permanently delete the scan.', onConfirm: () {
                      // TODO: Logica per eliminare la scansione
                    }),
                    backgroundColor: AppColors.errorRed,
                    icon: Icons.delete,
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
