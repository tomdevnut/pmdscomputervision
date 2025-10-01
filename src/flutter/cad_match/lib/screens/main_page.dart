import 'package:flutter/material.dart';
import 'scans_page.dart';
import 'steps_page.dart';
import 'profile_page.dart';
import '../utils.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  final List<Widget> pages = const [ScansPage(), StepsPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Sfondo scuro che funge da base
      body: SafeArea(
        bottom: false, // La safe area inferiore è gestita dalla nav bar
        child: Container(
          // Contenitore chiaro per le pagine
          decoration: const BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            child: pages[currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: AppColors.primary, // Sfondo scuro per integrarsi
          type: BottomNavigationBarType
              .fixed, // Assicura che lo sfondo sia visibile
          elevation: 0,
          enableFeedback: false,
          selectedItemColor: AppColors.buttonText, // Testo e icone bianche
          unselectedItemColor: AppColors.buttonTextSemiTransparent,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.view_in_ar_outlined),
              activeIcon: Icon(Icons.view_in_ar_rounded),
              label: 'Scans',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.file_copy_outlined),
              activeIcon: Icon(Icons.file_copy_rounded),
              label: 'Steps',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
