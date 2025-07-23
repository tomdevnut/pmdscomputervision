
import 'package:flutter/material.dart';

class StepsPage extends StatelessWidget { // uso un widget senza stato perché la pagina non cambia dinamicamente
  const StepsPage({super.key});

  // lista statica di dizionari (Map) che rappresentano ogni file step
  static const List<Map<String, String>> steps = [
    {'title': 'Step 1', 'subtitle': 'Subhead'},
    {'title': 'Step 2', 'subtitle': 'Subhead'},
    {'title': 'Step 3', 'subtitle': 'Subhead'},
    {'title': 'Step 4', 'subtitle': 'Subhead'},
    {'title': 'Step 5', 'subtitle': 'Subhead'},
    {'title': 'Step 6', 'subtitle': 'Subhead'},
  ];

  // metodo build che costruisce la UI della pagina
  @override
  Widget build(BuildContext context) {
    return Scaffold( // Scaffold fornisce la struttura di base della pagina
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column( // tutti i widget vengono disposti in verticale
          children: [
            // titolo "Steps" in alto allineato a sinistra, con padding
            const Padding(
              padding: EdgeInsets.only(top: 24.0, left: 16.0, bottom: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Steps',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Lista scrollabile che occupa tutto lo spazio disponibile
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16), // margine orizzontale
                itemCount: steps.length, // numero di elementi nella lista
                itemBuilder: (context, index) {
                  final step = steps[index]; // recupera il singolo step

                  // Ritorna una Card per ogni elemento
                  return Card(
                    color: Colors.grey[900], // sfondo scuro della card
                    margin: const EdgeInsets.symmetric(vertical: 6), // spazio tra le card
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // angoli snodati
                    ),

                    // Contenuto della Card: un ListTile
                    child: ListTile(
                      title: Text(
                        step['title']!, // titolo dello step
                        style: const TextStyle(color: Colors.white), // testo bianco
                      ),

                      subtitle: Text(
                        step['subtitle']!, // sottotitolo dello step
                        style: const TextStyle(color: Colors.white54), // testo grigio
                      ),

                      trailing: const Icon(
                        Icons.view_list, // icona a destra
                        color: Colors.white70,
                      ),
                      
                      onTap: () {
                        // azione da eseguire quando l'utente tocca uno step (da implementare)
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}