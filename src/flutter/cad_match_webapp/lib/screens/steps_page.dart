import 'package:flutter/material.dart';
import 'new_step.dart';
import 'single_step.dart';

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
                color: Color(0xFF111416),
                fontSize: 28,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            // TODO: mostrare il pulsante + solo se utente di livello >= 1
            InkWell(
              onTap: () {
                // Naviga verso la schermata di caricamento
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StepUpload()),
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: ShapeDecoration(
                  color: const Color(0xFF002C58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Lista di step
        _buildStepItem(context, 'Step 1', 'Uploaded: 2024-01-15'),
        const SizedBox(height: 12),
        _buildStepItem(context, 'Step 2', 'Uploaded: 2024-01-10'),
        const SizedBox(height: 12),
        _buildStepItem(context, 'Step 3', 'Uploaded: 2024-01-05'),
        const SizedBox(height: 12),
        _buildStepItem(context, 'Step 4', 'Uploaded: 2024-01-05'),
      ],
    );
  }

  // Metodo helper per costruire gli elementi della lista degli step
  Widget _buildStepItem(
    BuildContext context,
    String stepName,
    String uploadDate,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SingleStep()),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8), // Spazio tra le voci
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white, // Sfondo bianco
          borderRadius: BorderRadius.circular(10), // Bordi arrotondati
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF002C58),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(
                    Icons.file_copy,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  stepName,
                  style: const TextStyle(
                    color: Color(0xFF111416),
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF6B7582),
            ),
          ],
        ),
      ),
    );
  }
}
