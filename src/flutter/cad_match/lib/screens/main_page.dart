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
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: AppColors.backgroundColor,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.unselected,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.view_in_ar_rounded), label: 'Scans'),
          BottomNavigationBarItem(icon: Icon(Icons.file_copy_rounded), label: 'Steps'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
