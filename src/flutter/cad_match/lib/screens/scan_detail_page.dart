
import 'package:flutter/material.dart';

// creo uno statelesswidget (stateless dato che mostra dati passati), che riceve una mappa scan
class ScanDetailPage extends StatelessWidget {
  final Map<String, dynamic> scan;

  const ScanDetailPage({super.key, required this.scan});

  // per normalizzare i valori in stringhe (- per indicare dato mancante)
  String _v(dynamic v) =>
      (v == null || (v is String && v.trim().isEmpty)) ? '—' : v.toString();

  // definisco il contenuto con scaffold e listview
  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0F0F0F);
    const card = Color(0xFF161616);
    const labelColor = Colors.white70;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        centerTitle: true,
        elevation: 0.5,
        title: const Text('Scan Details'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // card contentente i dettagli dello scan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Model',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Details of your object',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // uso la funzione helper _field (costruisce un blocco con label e value) per mostrare i 5 campi
                  _field('Scan ID', _v(scan['scanId'])),
                  const SizedBox(height: 14),
                  _field('Step ID', _v(scan['stepId'])),
                  const SizedBox(height: 14),
                  _field('Object Type', _v(scan['objectType'])),
                  const SizedBox(height: 14),
                  _field('Name', _v(scan['name'])),
                  const SizedBox(height: 14),
                  _field('Description', _v(scan['description']), multiline: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // funzione per mostrare un singolo campo dei dettagli dello scan
  Widget _field(String label, String value, {bool multiline = false}) { // riceve tre parametri: label, value, multiline
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2421),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Text(
            value,
            style: const TextStyle(color: Colors.white),
            maxLines: multiline ? null : 2,
            overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}