import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'screens/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/main_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

const String kSaveFcmTokenUrl =
    'https://save-fcm-token-5ja5umnfkq-ey.a.run.app';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// Funzione per richiedere i permessi e inviare il token FCM alla Cloud Function
Future<void> setupFirebaseMessaging() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint('[FCM] User not logged in, cannot save token.');
    return;
  }

  // Richiedi i permessi di notifica
  NotificationSettings settings = await FirebaseMessaging.instance
      .requestPermission();

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // Ottieni il token FCM
    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint('[FCM] Token: $fcmToken');

    // Invia il token alla Cloud Function tramite una richiesta HTTP
    if (fcmToken != null) {
      try {
        final idToken = await user.getIdToken();
        final response = await http.post(
          Uri.parse(kSaveFcmTokenUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'Bearer $idToken', // Invia il token di autenticazione per l'autorizzazione
          },
          body: jsonEncode({'fcm_token': fcmToken}),
        );

        if (response.statusCode == 200) {
          debugPrint('[FCM] Token salvato con successo tramite Cloud Function');
        } else {
          final Map<String, dynamic> responseData = json.decode(response.body);
          debugPrint(
            '[FCM] Errore nel salvare il token: ${response.statusCode} - ${responseData['message']}',
          );
        }
      } catch (e) {
        debugPrint('[FCM] Errore imprevisto nel salvare il token: $e');
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
            return MainPage();
          }
          return LoginPage();
        },
      ),
    );
  }
}
