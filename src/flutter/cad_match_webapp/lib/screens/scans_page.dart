import 'package:flutter/material.dart';
import 'single_scan.dart';
import '../shared_utils.dart'; // Importa il file di utility condiviso

class ScansPage extends StatelessWidget {
  const ScansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SCANS',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 44),
          ],
        ),
        const SizedBox(height: 20),
        // Lista di scansioni
        buildListItem(
          title: 'Scan 1',
          subtitle: 'Uploaded: 2024-01-15',
          icon: Icons.view_in_ar,
          hasArrow: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SingleScan()),
            );
          },
        ),
        const SizedBox(height: 12),
        buildListItem(
          title: 'Scan 2',
          subtitle: 'Uploaded: 2024-01-10',
          icon: Icons.view_in_ar,
          hasArrow: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SingleScan()),
            );
          },
        ),
        const SizedBox(height: 12),
        buildListItem(
          title: 'Scan 3',
          subtitle: 'Uploaded: 2024-01-05',
          icon: Icons.view_in_ar,
          hasArrow: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SingleScan()),
            );
          },
        ),
        const SizedBox(height: 12),
        buildListItem(
          title: 'Scan 4',
          subtitle: 'Uploaded: 2024-01-05',
          icon: Icons.view_in_ar,
          hasArrow: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SingleScan()),
            );
          },
        ),
      ],
    );
  }
}
