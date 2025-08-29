import 'package:flutter/material.dart';
import 'new_step.dart';
import 'single_step.dart';
import '../shared_utils.dart';

class StepsPage extends StatelessWidget {
  const StepsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'STEPS',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            // TODO: mostrare il pulsante + solo se utente di livello >= 1
            buildAddButton(context, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StepUpload()),
              );
            }),
          ],
        ),
        const SizedBox(height: 20),
        // Lista di step
        buildListItem(
          title: 'Step 1',
          subtitle: 'Created: 2024-01-15',
          icon: Icons.file_copy,
          hasArrow: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SingleStep()),
            );
          },
        ),
        const SizedBox(height: 12),
        buildListItem(
          title: 'Step 2',
          subtitle: 'Created: 2024-01-10',
          icon: Icons.file_copy,
          hasArrow: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SingleStep()),
            );
          },
        ),
        const SizedBox(height: 12),
        buildListItem(
          title: 'Step 3',
          subtitle: 'Created: 2024-01-05',
          icon: Icons.file_copy,
          hasArrow: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SingleStep()),
            );
          },
        ),
      ],
    );
  }
}
