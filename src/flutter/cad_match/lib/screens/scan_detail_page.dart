import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../utils.dart';

// Widget stateless per la pagina dei dettagli
class ScanDetailPage extends StatelessWidget {
  final Map<String, dynamic> scan;

  const ScanDetailPage({super.key, required this.scan});

  // Funzione helper per normalizzare i valori
  String _v(dynamic value) {
    return (value == null || (value is String && value.trim().isEmpty))
        ? '—'
        : value.toString();
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
        elevation: 0.5,
        title: const Text('Scan Details'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.white),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _v(scan['name']),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${_v(scan['scanId'])}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  cardField('Step Name', _v(scan['stepName'])),
                  const SizedBox(height: 14),
                  cardField('User', _v(scan['user'])),
                  const SizedBox(height: 14),
                  cardField(
                    'Timestamp',
                    _v(
                      (scan['timestamp'] is Timestamp)
                          ? DateFormat(
                              'yyyy-MM-dd HH:mm:ss',
                            ).format((scan['timestamp'] as Timestamp).toDate())
                          : '—',
                    ),
                  ),
                  const SizedBox(height: 14),
                  cardField('Status', getStatusString(status)),
                  const SizedBox(height: 14),
                  cardField('Progress', _v('${scan['progress']}%')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            buildButton(
              'VIEW STATISTICS',
              color: status == 2 ? AppColors.primary : AppColors.textSecondary,
              onPressed: () {
                if (status == 2) {
                  // TODO: Naviga alla pagina delle statistiche
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Statistics are not available yet.'),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            buildButton(
              'DELETE SCAN',
              color: status == 2 || status == -1
                  ? AppColors.red
                  : AppColors.textSecondary,
              onPressed: () {
                if (status == 2 || status == -1) {
                  // Passa il contesto a una funzione asincrona
                  showConfirmationDialog(
                    context,
                    'Are you sure you want to delete this scan?',
                    () async {
                        await FirebaseStorage.instance
                            .ref('scans/${scan['scanId']}')
                            .delete();
                      }
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Scan cannot be deleted until it is completed or has failed.',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
