import 'package:flutter/material.dart';
import 'main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // Per ora passiamo a main_page
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold fornisce la struttura di base della pagina
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // Layout per schermi ampi (desktop)
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: _buildLoginContent(context),
              ),
            );
          } else {
            // Layout per schermi stretti (mobile)
            return SingleChildScrollView(child: _buildLoginContent(context));
          }
        },
      ),
    );
  }

  // Metodo per costruire il contenuto del login, riutilizzabile per entrambi i layout
  Widget _buildLoginContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome Back to CADmatch web',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF111416),
              fontSize: 40,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),

          // Sottotitolo
          Text(
            'Please sign in.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF111416),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 48),

          // Contenitore del modulo di login
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFFE1EDFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                // Campo di testo per l'Email
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDBE0E5)),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Campo di testo per la Password
                TextField(
                  obscureText: true,
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDBE0E5)),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Bottone "Sign In"
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      // Logica di autenticazione
                      _signIn();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C7FF2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
