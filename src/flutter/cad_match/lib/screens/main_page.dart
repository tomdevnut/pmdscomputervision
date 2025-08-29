
import 'package:flutter/material.dart'; // per usare i widget Material di Flutter
import 'scans_page.dart'; // schermata delle scansioni
import 'steps_page.dart'; // schermata degli step
import 'profile_page.dart'; // schermata del profilo
import '../utils.dart';

class MainPage extends StatefulWidget { // definizione di un widget principale chiamato MainPage
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState(); // funzione che collega il widget con il suo stato interno
}

class _MainPageState extends State<MainPage> { // classe privata (_) che contiene lo stato del widget MainPage
  int currentIndex = 0; // variabile che tiene traccia della pagina attualmente selezionata
  // 0 = SCANS, 1 = STEPS, 2 = PROFILE

  final List<Widget> pages = const [ // lista delle pagine disponibili
    ScansPage(),
    StepsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) { // metodo principale che costruisce l'interfaccia utente
    return Scaffold(
      body: pages[currentIndex], // il contenuto di body mostra la pagina selezionata

      bottomNavigationBar: BottomNavigationBar( // costruisce la barra di navigazione in basso
        currentIndex: currentIndex, // collega la voce selezionata nella bottom nav con la pagina visibile

        // imposta lo stile della barra
        backgroundColor: AppColors.backgroundColor,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.unselected,

        // quando l'utente tocca una voce della barra: l'indice cambia, setState() aggiorna l'interfaccia
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        // definisce le 3 voci della bottom navigation bar con icona e testo
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_in_ar),
            label: 'Scans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_copy),
            label: 'Steps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}