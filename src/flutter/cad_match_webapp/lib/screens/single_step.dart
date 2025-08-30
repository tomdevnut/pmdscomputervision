import 'package:flutter/material.dart';
import '../shared_utils.dart';

class SingleStep extends StatelessWidget {
  const SingleStep({super.key});

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
              buildTopBar(context, title: 'STEP INFO'),
              const SizedBox(height: 24),  
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  if (constraints.maxWidth > 800) {
                    // Layout per schermi ampi
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildInfoField(label: 'Name', value: 'Step 1', icon: Icons.abc),
                              const SizedBox(height: 24),
                              buildInfoField(
                                label: 'Description',
                                value:
                                    'Description of the step. This is a longer text to test the multiline functionality.',
                                icon: Icons.description
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
                                label: 'Upload Date',
                                value: '2024-01-15',
                                icon: Icons.calendar_today,
                              ),
                              const SizedBox(height: 24),
                              buildInfoField(
                                label: 'Author',
                                value: 'john.doe@example.com',
                                icon: Icons.person,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Layout per schermi stretti
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildInfoField(label: 'Name', value: 'Step 1', icon: Icons.abc),
                        const SizedBox(height: 24),
                        buildInfoField(
                          label: 'Description',
                          value:
                              'Description of the step. This is a longer text to test the multiline functionality.',
                          icon: Icons.description,
                        ),
                        const SizedBox(height: 24),
                        buildInfoField(label: 'Upload Date', value: '2024-01-15', icon: Icons.calendar_today),
                        const SizedBox(height: 24),
                        buildInfoField(
                          label: 'Author',
                          value: 'john.doe@example.com',
                          icon: Icons.person,
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children:[
                  buildButton(
                    label: 'Download Step File',
                    icon: Icons.download,
                    onTap: () {
                      // TODO: Logica per scaricare il file dello step
                    },
                  ),
                  const SizedBox(width: 12),
                  buildButton(
                    label: 'Delete Step',
                    icon: Icons.delete,
                    backgroundColor: AppColors.red,
                    onTap: () => showConfirmationDialog(context: context, message: 'This action will permanently delete the step. All associated scans will not be affected.', onConfirm: () {
                      // TODO: Logica per eliminare il passo
                    }),
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
