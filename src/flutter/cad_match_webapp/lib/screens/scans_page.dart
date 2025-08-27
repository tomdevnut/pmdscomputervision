import 'package:flutter/material.dart';

class ScansPage extends StatelessWidget {
  const ScansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SCANS',
          style: TextStyle(
            color: Color(0xFF111416),
            fontSize: 28, // Dimensione del font ridotta
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        // Lista di scansioni
        _buildScanItem(context, 'Scan 1', 'Uploaded: 2024-01-15'),
        const SizedBox(height: 12),
        _buildScanItem(context, 'Scan 2', 'Uploaded: 2024-01-10'),
        const SizedBox(height: 12),
        _buildScanItem(context, 'Scan 3', 'Uploaded: 2024-01-05'),
        const SizedBox(height: 12),
        _buildScanItem(context, 'Scan 4', 'Uploaded: 2024-01-05'),
      ],
    );
  }

  // Metodo helper per costruire gli elementi della lista scansioni
  Widget _buildScanItem(
    BuildContext context,
    String scanName,
    String uploadDate,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE1EDFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44, // Dimensione ridotta
                height: 44, // Dimensione ridotta
                decoration: ShapeDecoration(
                  color: const Color(0xFF002C58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(
                  Icons.view_in_ar,
                  color: Colors.white,
                  size: 20,
                ), // Dimensione icona ridotta
              ),
              const SizedBox(width: 12),
              Text(
                scanName,
                style: const TextStyle(
                  color: Color(0xFF111416),
                  fontSize: 18, // Dimensione del font ridotta
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            uploadDate,
            style: const TextStyle(
              color: Color(0xFF6B7582),
              fontSize: 14, // Dimensione del font ridotta
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
