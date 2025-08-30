

import 'package:flutter/material.dart';

// creo uno statelesswidget (stateless dato che mostra dati passati), che riceve una mappa step con i dati dello step
class StepDetailPage extends StatelessWidget {
  final Map<String, dynamic> step; 

  const StepDetailPage({super.key, required this.step});

  // helper per normalizzare un valore
  String _v(dynamic v) =>
      (v == null || (v is String && v.trim().isEmpty)) ? '—' : v.toString();

  // helper per formattare una data in stringa leggibile
  String _fmtDate(dynamic v) {
    DateTime? dt;
    if (v is DateTime) {
      dt = v;
    } else if (v is String && v.isNotEmpty) {
      try {
        dt = DateTime.parse(v);
      } catch (_) {}
    }
    if (dt == null) return '—';
    dt = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    }

  // helper per formattare l'accuracy aggiungengo il simbolo %
  String _fmtAccuracy(dynamic v) {
    if (v == null) return '—';
    if (v is num) {
      final val = v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
      return '$val%';
    }
    return v.toString();
  }

  // metodo build principale con scaffold, safearea e listview
  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0F0F0F);
    const card = Color(0xFF161616);

    final dynamic thumb = step['thumbnail']; // estraggo l'eventuale anteprima

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        centerTitle: true,
        elevation: 0.5,
        title: const Text('Step Details'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // container con funzione di card dei dettagli con 4 campi _field
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
                  _field('Step ID', _v(step['stepId'])),
                  const SizedBox(height: 14),
                  _field('Date', _fmtDate(step['createdAt'])),
                  const SizedBox(height: 14),
                  _field('Processing',
                      (step['completed'] == true) ? 'Completed successfully' : 'In progress'),
                  const SizedBox(height: 14),
                  _field('Accuracy', _fmtAccuracy(step['accuracy'])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // funzione _field rappresentante un singolo campo di dettaglio
  Widget _field(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          ),
        ),
      ],
    );
  }
}
