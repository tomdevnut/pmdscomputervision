import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'single_scan.dart';
import '../shared_utils.dart';
import 'package:intl/intl.dart';

class ScansPage extends StatelessWidget {
  final int level;

  const ScansPage({super.key, required this.level});

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
        // Utilizziamo un Expanded per consentire alla lista di scansioni di occupare lo spazio disponibile
        // e per rendere l'area scorrevole.
        Expanded(
          child: StreamBuilder(
            // Utilizza StreamBuilder per ascoltare i cambiamenti nella collezione 'scans' di Firestore.
            stream: FirebaseFirestore.instance.collection('scans').snapshots(),
            builder: (context, snapshot) {
              // Se la connessione non è attiva, mostra un indicatore di caricamento.
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Se c'è un errore nella query, mostra un messaggio di errore.
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              // Se non ci sono dati, mostra un messaggio informativo.
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No scans found.'));
              }

              // Se i dati sono disponibili, costruisci la lista.
              final scans = snapshot.data!.docs;
              return ListView.builder(
                itemCount: scans.length,
                itemBuilder: (context, index) {
                  final scanData = scans[index].data();
                  final title = scanData['name'] ?? 'No Name';
                  final timestamp = scanData['timestamp'] as Timestamp?;
                  final status = scanData['status'] as int;
                  final statusText = getStatusText(status);

                  String subtitle;
                  if (timestamp != null) {
                    final uploadedDate = timestamp.toDate();
                    final formattedDate = DateFormat(
                      'yyyy-MM-dd – HH:mm',
                    ).format(uploadedDate);
                    subtitle = 'Uploaded: $formattedDate, Status: $statusText';
                  } else {
                    subtitle = 'Date not available, Status: $statusText';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: buildListItem(
                      title: title,
                      subtitle: subtitle,
                      icon: Icons.view_in_ar,
                      hasArrow: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SingleScan(),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
