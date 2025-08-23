import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ScansPage extends StatefulWidget {
  const ScansPage({super.key});

  @override
  State<ScansPage> createState() => _ScansPageState();
}

class _ScansPageState extends State<ScansPage> {
  Stream<QuerySnapshot>? _scansStream;
  StreamSubscription<User?>? _authSub;

  Stream<QuerySnapshot> _scansFor(String uid) async* {
    // First, get the user's level from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    
    final userData = userDoc.data();
    final userLevel = userData?['level'] as int? ?? 1; // Default to level 1
    
    if (userLevel >= 2) {
      // Level 2 or higher: show all scans
      yield* FirebaseFirestore.instance
          .collection('scans')
          .snapshots();
    } else {
      // Level 1: show only user's own scans
      yield* FirebaseFirestore.instance
          .collection('scans')
          .where('user', isEqualTo: uid)
          .snapshots();
    }
  }

  @override
  void initState() {
    super.initState();
    
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      _scansStream = _scansFor(user.uid);
    } else {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
        if (u != null && mounted) {
          setState(() {
            _scansStream = _scansFor(u.uid);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12), 
              child: Image.asset( // inserimento banner
                'assets/banner.png',
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),

            // Title 'Your Scans'
            const Text(
              'Your Scans',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Scans list
            Expanded(
              child: _scansStream == null
                  ? const Center(
                      child: Text(
                        'Please sign in to view scans',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: _scansStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No scans found. Press + to add one!',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        final scans = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: scans.length,
                          itemBuilder: (context, index) {
                            final scan = scans[index];
                            final data = scan.data() as Map<String, dynamic>;
                            final title = data['scan_name'] as String? ?? 'No Title';
                            return ScanItem(title: title);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

    floatingActionButton: FloatingActionButton(
      onPressed: () {
        // Naviga alla schermata "Nuova Scansione" -> scanning_page.dart
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScanningPage()),
        );
      },
      backgroundColor: const Color(0xFFFF7C00),
      child: const Icon(Icons.add),
    ),


    );
  }
}

class ScanItem extends StatelessWidget {
  final String title;

  const ScanItem({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
        onTap: () {
          // Handle scan item tap
        },
      ),
    );
  }
}