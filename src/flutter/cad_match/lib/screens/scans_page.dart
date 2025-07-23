
import 'package:flutter/material.dart';

class ScansPage extends StatelessWidget {
  const ScansPage({super.key});

  // Scaffold
  @override
  Widget build(BuildContext context) { // costruisce la UI
    return Scaffold(
      backgroundColor: Colors.black,

      body: Padding( // per avere spazio interno
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset( // inserimento banner
              'assets/banner.png',
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),

            const SizedBox(height: 20),

            // Titolo 'Your Scans"
            const Text(
              'Your Scans',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Lista di alcuni elementi scansione
            Expanded( // la lista occupa tutto lo spazio disponibile sotto il titolo
              child: ListView( // lista scrollabile
                children: const [
                  ScanItem(title: 'Scan 1'), // widget creato sotto per rappresentare ogni riga
                  ScanItem(title: 'Scan 2'),
                  ScanItem(title: 'Scan 3'),
                  ScanItem(title: 'Scan 4'),
                  ScanItem(title: 'Scan 5'),
                ],
              )
            )

          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // schermata "Nuova Scansione"
        },
        backgroundColor: const Color(0xFFFF7C00),
        child: const Icon(Icons.add),
      ),


    );
  }
}


// Widget riutilizzabile per ogni scansione nella lista
class ScanItem extends StatelessWidget {
  final String title;

  const ScanItem({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
        onTap: () {

        },
      ),
    );
  }
}