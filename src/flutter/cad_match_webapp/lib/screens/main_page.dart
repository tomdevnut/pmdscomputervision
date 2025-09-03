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

  @override
  void initState() {
    super.initState();
    _selectedPageIndex = 0; // Imposta la pagina iniziale su Scans.
  }

  @override
  Widget build(BuildContext context) {
    // Usa uno StreamBuilder per ascoltare i cambiamenti nel documento dell'utente in tempo reale
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Se la connessione è in attesa, mostra un indicatore di caricamento.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        int userLevel = 1; // Livello predefinito
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('level')) {
            userLevel = data['level'] as int? ?? 1;
          }
        }

        // Costruisci le liste di pagine e di menu in base al livello utente.
        final List<Widget> pages = [
          ScansPage(level: userLevel),
          StepsPage(level: userLevel),
          SettingsPage(level: userLevel),
        ];
        final List<String> pageTitles = ['Scans', 'Steps', 'Settings'];

        // Se il livello è 2, aggiungi la pagina e il menu per la gestione degli utenti.
        if (userLevel == 2) {
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 60,
                  ),
                  child: pages[_selectedPageIndex],
                ),
              ),
            ],
          ),
        );
      },
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
