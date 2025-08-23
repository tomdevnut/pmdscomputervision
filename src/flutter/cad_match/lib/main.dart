import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );



  // Create/update a user document on every login
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user == null) {
      debugPrint('[Auth] Signed out');
      return;
    }
    debugPrint('[Auth] Signed in as ${user.uid}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CADmatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const LoginPage(),
    );
  }
}
