import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Navigate to the main page on successful login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Show an error message if login fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // struttura basic con Scaffold (fornisce la struttura visiva principale, sfondo, body, app bar...)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,// imposto lo sfondo

      // SafeArea, Padding, Column
      body: SafeArea( // evita che i contenuti vadano sotto status bar
        child: Padding( // aggiunge margine orizzontale per non attaccare tutto ai bordi
          padding: const EdgeInsets.symmetric(horizontal:32),
          child: Column( // organizza gli elementi in verticale
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // image e title
              const SizedBox(height: 50), // spaziatura verticale

              ClipRRect(
                borderRadius: BorderRadius.circular(12), 
                child: Image.asset( // carica l'immagine da file
                  'assets/logo.png',
                  height: 150,  
                ),
              ),

              const SizedBox(height: 20),
              
              const Text( // mostra il messaggio di benvenuto
                'Welcome to CADmatch',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              // Campo di testo: Username
              TextField(
                controller: _emailController, // Add this controller
                keyboardType: TextInputType.emailAddress, // Set keyboard type
                decoration: InputDecoration(
                  hintText: 'Email', // Changed from 'Username'
                  filled: true,
                  fillColor: Colors.grey[900],
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white), // colore del testo inserito
              ),

              const SizedBox(height: 16),

              // campo di testo: Password
              TextField(
                controller: _passwordController, // Add this controller
                obscureText: true, // per nascondere i caratteri
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.grey[900],
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white), // colore del testo inserito
              ),

              // pulsante 'LOGIN'
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height:50,
                child: ElevatedButton(
                  onPressed: _signIn, // Call the signIn method
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7C00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text( // scritta button
                    'LOGIN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            ]
          )
        )
      ),
    );
  }

}