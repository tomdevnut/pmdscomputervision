import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../utils.dart';
import 'step_detail_page.dart';

// Funzione per recuperare i nomi utente in un'unica query
Future<Map<String, String>> fetchUsernames(List<String> userIds) async {
  final validUserIds = userIds.where((id) => id.isNotEmpty).toList();
  if (validUserIds.isEmpty) return {};
  final userDocs = await FirebaseFirestore.instance
      .collection('users')
      .where(FieldPath.documentId, whereIn: validUserIds)
      .get();
  return {
    for (var doc in userDocs.docs)
      doc.id:
          '${doc.data()['name'] ?? 'Unknown User'} ${doc.data()['surname'] ?? ''}',
  };
}

// funzione per costruire la card di un singolo step in modo coerente
Widget _buildStepCard(String title, String subtitle, {VoidCallback? onTap}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.boxborder),
    ),
    child: ListTile(
      leading: const Icon(Icons.file_copy_rounded, color: AppColors.secondary),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: AppColors.textSecondary,
        size: 16,
      ),
      onTap: onTap,
    ),
  );
}

// funzione per mostrare un messaggio di stato
Widget _buildMessage(String message) {
  return Center(
    child: Text(
      message,
      style: const TextStyle(color: AppColors.textPrimary),
      textAlign: TextAlign.center,
    ),
  );
}

class StepsPage extends StatefulWidget {
  const StepsPage({super.key});

  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> {
  Stream<QuerySnapshot>? _stepsStream;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _initializeStepsStream();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _initializeStepsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _setStepsStream();
    } else {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
        if (u != null && mounted) {
          _setStepsStream();
        }
      });
    }
  }

  void _setStepsStream() {
    setState(() {
      _stepsStream = FirebaseFirestore.instance.collection('steps').snapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader('Steps'),
              const Text(
                'To load and manage steps, please use the web app.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_stepsStream == null) {
      return _buildMessage('Please sign in to view steps');
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _stepsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }
        if (snapshot.hasError) {
          return _buildMessage('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildMessage('No steps found.');
        }

        final steps = snapshot.data!.docs;
        final userIds = steps
            .map(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['user'] as String? ?? '',
            )
            .toList();

        return FutureBuilder<Map<String, String>>(
          future: fetchUsernames(userIds),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (futureSnapshot.hasError) {
              return _buildMessage(
                'Error loading user data: ${futureSnapshot.error}',
              );
            }

            final usernames = futureSnapshot.data ?? {};

            return ListView.builder(
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final doc = steps[index];
                final data = doc.data() as Map<String, dynamic>;

                final title = (data['name'] as String?)?.isNotEmpty == true
                    ? data['name'] as String
                    : (data['stepId'] as String?) ?? 'No Title';

                final description =
                    (data['description'] as String?)?.isNotEmpty == true
                    ? data['description'] as String
                    : 'No Description';

                final userId = data['user'] as String? ?? '';
                final username = usernames[userId] ?? 'Unknown User';

                return _buildStepCard(
                  title,
                  description,
                  onTap: () {
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StepDetailPage(
                            step: {
                              'stepId': doc.id,
                              'name': title,
                              'user': username,
                              'description': description,
                            },
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
