import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class StepsPage extends StatefulWidget {
  const StepsPage({super.key});

  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> {
  Stream<QuerySnapshot>? _stepsStream;
  StreamSubscription<User?>? _authSub;

  Stream<QuerySnapshot> _stepsFor(String uid) async* {
    // First, get the user's level from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    
    final userData = userDoc.data();
    final userLevel = userData?['level'] as int? ?? 1; // Default to level 1
    
    if (userLevel >= 2) {
      // Level 2 or higher: show all steps
      yield* FirebaseFirestore.instance
          .collection('steps')
          .snapshots();
    } else {
      // Level 1: show only user's own steps
      yield* FirebaseFirestore.instance
          .collection('steps')
          .where('user', isEqualTo: uid)
          .snapshots();
    }
  }

  @override
  void initState() {
    super.initState();
    
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      _stepsStream = _stepsFor(user.uid);
    } else {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
        if (u != null && mounted) {
          setState(() {
            _stepsStream = _stepsFor(u.uid);
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
      body: SafeArea(
        child: Column(
          children: [
            // titolo "Steps" in alto allineato a sinistra, con padding
            const Padding(
              padding: EdgeInsets.only(top: 24.0, left: 16.0, bottom: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Steps',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Steps list
            Expanded(
              child: _stepsStream == null
                  ? const Center(
                      child: Text(
                        'Please sign in to view steps',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: _stepsStream,
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
                              'No steps found. Press + to add one!',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        final steps = snapshot.data!.docs;

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: steps.length,
                          itemBuilder: (context, index) {
                            final step = steps[index];
                            final data = step.data() as Map<String, dynamic>;
                            final title = data['name'] as String? ?? 'No Title';
                            final subtitle = data['description'] as String? ?? 'No Subtitle';
                            
                            return Card(
                              color: Colors.grey[900],
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  title,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  subtitle,
                                  style: const TextStyle(color: Colors.white54),
                                ),
                                trailing: const Icon(
                                  Icons.view_list,
                                  color: Colors.white70,
                                ),
                                onTap: () {
                                  // Handle step item tap
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final user = FirebaseAuth.instance.currentUser;
          
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please sign in first')),
            );
            return;
          }
          
        },
        backgroundColor: const Color(0xFFFF7C00),
        child: const Icon(Icons.add),
      ),
    );
  }
}