import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scans_page.dart';
import 'users_page.dart';
import 'settings_page.dart';
import 'steps_page.dart';
import '../shared_utils.dart';

// La MainPage ora accetta l'oggetto User, come discusso in precedenza.
class MainPage extends StatefulWidget {
  final User user;

  const MainPage({super.key, required this.user});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedPageIndex;
  // Variabile per memorizzare il livello dell'utente.
  int? _userLevel;

  @override
  void initState() {
    super.initState();
    _selectedPageIndex = 0; // Imposta la pagina iniziale su Scans.
    // Lancia la funzione asincrona per recuperare il livello utente.
    _fetchUserLevel();
  }

  // Metodo asincrono per recuperare il livello utente da Firestore.
  Future<void> _fetchUserLevel() async {
    try {
      // Ottieni il documento dell'utente dalla collezione 'users'.
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      // Controlla se il documento esiste e ha il campo 'level'.
      if (userDoc.exists && userDoc.data()!.containsKey('level')) {
        final level = userDoc.data()!['level'];
        setState(() {
          _userLevel = level;
        });
      } else {
        // Se il documento non esiste o non ha il campo 'level',
        // imposta un livello predefinito (es. 1).
        setState(() {
          _userLevel = 1;
        });
      }
    } catch (e) {
      // In caso di errore, imposta un livello predefinito e stampa un log.
      print("Errore nel recupero del livello utente: $e");
      setState(() {
        _userLevel = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se il livello utente non è ancora stato caricato, mostra un indicatore di caricamento.
    if (_userLevel == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Costruisci le liste di pagine e di menu in base al livello utente.
    final List<Widget> pages = [
      ScansPage(level: _userLevel!),
      StepsPage(level: _userLevel!),
      SettingsPage(level: _userLevel!),
    ];
    final List<String> pageTitles = [
      'Scans',
      'Steps',
      'Settings',
    ];

    // Se il livello è 2, aggiungi la pagina e il menu per la gestione degli utenti.
    if (_userLevel == 2) {
      pages.add(const UsersPage());
      pageTitles.add('Users');
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Row(
        children: [
          // Menu a sinistra.
          Container(
            height: double.infinity,
            decoration: const ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Text(
                    'CADmatch',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 24,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Mappa i titoli dinamici per costruire gli elementi del menu.
                  ...pageTitles.asMap().entries.map((entry) {
                    int index = entry.key;
                    String title = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildMenuItem(context, title, index),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Contenuto principale a destra.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              child: pages[_selectedPageIndex],
            ),
          ),
        ],
      ),
    );
  }

  // Metodo helper per costruire gli elementi del menu
  Widget _buildMenuItem(BuildContext context, String title, int index) {
    bool isActive = index == _selectedPageIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPageIndex = index;
        });
      },
      child: Container(
        width: 250,
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: ShapeDecoration(
          color: isActive ? AppColors.backgroundColor : AppColors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: isActive ? AppColors.secondary : AppColors.white,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}