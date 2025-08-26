import 'package:flutter/material.dart';
import 'scans_page.dart'; // Importa la pagina di scansione, assicurati che il nome del file sia corretto.

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedPageIndex = 0;

  final List<Widget> _pages = const [
    ScansPage(),
    // Aggiungi qui altre pagine per gli altri menu
    Center(child: Text('Steps Page Placeholder')),
    Center(child: Text('Settings Page Placeholder')),
    Center(child: Text('Users Management Page Placeholder')),
  ];

  @override
  Widget build(BuildContext context) {
    // Utilizziamo un Row per creare un layout orizzontale,
    // perfetto per la barra laterale e il contenuto principale.
    return Scaffold(
      backgroundColor: const Color(0xFFE1EDFF),
      body: Row(
        children: [
          // Navigazione a sinistra.
          // Ha una larghezza fissa per mantenere il design.
          Container(
            width: 280, // Larghezza ridotta per un look più compatto
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 60, 0, 0),
                  child: Text(
                    'CADmatch',
                    style: TextStyle(
                      color: Color(0xFF111416),
                      fontSize: 28, // Dimensione del font ridotta
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildMenuItem(context, 'Scans', 0),
                const SizedBox(height: 12),
                _buildMenuItem(context, 'Steps', 1),
                const SizedBox(height: 12),
                _buildMenuItem(context, 'Settings', 2),
                const SizedBox(height: 12),
                _buildMenuItem(context, 'Users Management', 3),
              ],
            ),
          ),
          // Contenuto principale a destra.
          // Expanded prende tutto lo spazio rimanente orizzontalmente.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              child: _pages[_selectedPageIndex],
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
        width: 250, // Larghezza ridotta
        height: 50, // Altezza ridotta
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: ShapeDecoration(
          color: isActive ? const Color(0xFFE1EDFF) : Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: isActive ? const Color(0xFF0C7FF2) : Colors.white,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFF002C58),
                fontSize: 18, // Dimensione del font ridotta
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}