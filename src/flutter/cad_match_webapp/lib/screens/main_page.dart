import 'package:flutter/material.dart';
import 'scans_page.dart';
import 'users_page.dart';
import 'settings_page.dart';
import 'steps_page.dart';

class MainPage extends StatefulWidget {
  final int initialPageIndex;

  const MainPage({super.key, this.initialPageIndex = 0});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedPageIndex;

  final List<Widget> _pages = const [
    ScansPage(),
    StepsPage(),
    SettingsPage(),
    UsersPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedPageIndex = widget.initialPageIndex;
  }

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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Text(
                    'CADmatch',
                    style: TextStyle(
                      color: Color(0xFF111416),
                      fontSize: 24,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildMenuItem(context, 'Scans', 0),
                  const SizedBox(height: 16),
                  _buildMenuItem(context, 'Steps', 1),
                  const SizedBox(height: 16),
                  _buildMenuItem(context, 'Settings', 2),
                  const SizedBox(height: 16),
                  _buildMenuItem(context, 'Users Management', 3),
                ],
              ),
            ),
          ),
          // Contenuto principale a destra.
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
