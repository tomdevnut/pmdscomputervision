import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/main_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// Funzione per richiedere i permessi e inviare il token FCM alla Cloud Function
Future<void> setupFirebaseMessaging() async {
  // Richiedi i permessi di notifica
  NotificationSettings settings = await FirebaseMessaging.instance
      .requestPermission();

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {

    // Ottieni il token FCM
    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint('[FCM] Token: $fcmToken');

    // Invia il token alla Cloud Function
    if (fcmToken != null) {
      try {
        final callable = FirebaseFunctions.instance.httpsCallable(
          'save_fcm_token',
        );
        await callable.call(<String, dynamic>{'fcm_token': fcmToken});
        debugPrint('[FCM] Token salvato con successo tramite Cloud Function');
      } on FirebaseFunctionsException catch (e) {
        debugPrint(
          '[FCM] Errore nel salvare il token: ${e.code} - ${e.message}',
        );
      }
    }
  } else {
    debugPrint('[FCM] Permessi di notifica negati');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CADmatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            // Se l'utente è loggato, chiama la funzione per gestire le notifiche
            setupFirebaseMessaging();
            return const MainPage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
