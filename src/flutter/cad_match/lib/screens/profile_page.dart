import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      setState(() {
        _userData = doc.data();
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

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
              Text(
                _userData?['name'] ?? 'Loading...',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),

              const SizedBox(height: 16),

              // Livello operatore
              const Text(
                'Level:',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                _userData?['level']?.toString() ?? '...',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),

              const SizedBox(height: 16),

              // Email utente
              const Text(
                'Email:',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                _user?.email ?? 'Loading...',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),

              const SizedBox(height: 24),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signOut,
                  child: const Text('LOGOUT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
