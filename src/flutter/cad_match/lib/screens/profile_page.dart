
import 'package:flutter/material.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // tema dark come nel resto dell'app
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Titolo "Profile"
              const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // Icona profilo
              const Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFFF7C00),
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
              ),

              const SizedBox(height: 24),

              // Nome utente
              const Text(
                'Name:',
                style: TextStyle(color: Colors.white70),
              ),
              const Text(
                'Mario Rossi',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),

              const SizedBox(height: 16),

              // Livello operatore
              const Text(
                'Level:',
                style: TextStyle(color: Colors.white70),
              ),
              const Text(
                '1', // livelli possibili:'0', '1' o '2'
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),

              const SizedBox(height: 16),

              // Email utente
              const Text(
                'Email:',
                style: TextStyle(color: Colors.white70),
              ),
              const Text(
                'mario.rossi@example.com',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),

              const SizedBox(height: 24),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false, // rimuove tutte le route precedenti
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF7C00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}
