
import 'package:flutter/material.dart';
import 'main_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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

              Image.asset( // carica l'immagine da file
                'assets/logo.png',
                height: 150,
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
              TextField( // campo di inserimento testo
                decoration: InputDecoration( // controlla l'aspetto del campo (colore, bordi, hint)
                  hintText: 'Username',
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
              TextField( // campo di inserimento testo
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
                child: ElevatedButton( // bottone con sfondo e ombra
                  onPressed: () {
                    // logica di login (API, validazione, ecc.)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MainPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom( // personalizza colore e bordi
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