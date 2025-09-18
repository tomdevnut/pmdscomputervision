import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../utils.dart'; // Assicurati che questo file contenga AppColors e buildHeader
import 'add_scan_page.dart';
import 'scan_detail_page.dart';

// Funzioni per recuperare dati utente e step in modo asincrono
// Aggiungo il pre-caricamento per ottimizzare le performance
Future<Map<String, String>> fetchStepNames(List<String> stepIds) async {
  // Filtra tutti gli ID vuoti o nulli
  final validStepIds = stepIds.where((id) => id.isNotEmpty).toList();
  if (validStepIds.isEmpty) return {};
  final stepDocs = await FirebaseFirestore.instance
      .collection('steps')
      .where(FieldPath.documentId, whereIn: validStepIds)
      .get();
  return {
    for (var doc in stepDocs.docs) doc.id: doc.data()['name'] ?? 'Unknown Step',
  };
}

Future<Map<String, String>> fetchUsernames(List<String> userIds) async {
  // Filtra tutti gli ID vuoti o nulli
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

// Widget separato per l'item della lista, con design coerente
class ScanItem extends StatelessWidget {
  final String title;
  final DateTime? date;
  final int status;
  final VoidCallback? onTap;

  const ScanItem({
    super.key,
    required this.title,
    required this.date,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.boxborder),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        subtitle: date != null
            ? Text(
                DateFormat.yMMMd().format(date!),
                style: const TextStyle(color: AppColors.textSecondary),
              )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: AppColors.textSecondary,
          size: 16,
        ),
        leading: _buildStatusIcon(status),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatusIcon(int status) {
    switch (status) {
      case 2: // Completed
        return const Icon(Icons.check_circle_rounded, color: AppColors.success);
      case 1: // Sent to backend server
        return const Icon(
          Icons.hourglass_top_rounded,
          color: AppColors.warning,
        );
      case 0: // Received
        return const Icon(Icons.inbox_rounded, color: AppColors.warning);
      default: // Error (-1)
        return const Icon(Icons.warning_rounded, color: AppColors.error);
    }
  }
}

class ScansPage extends StatefulWidget {
  const ScansPage({super.key});

  @override
  State<ScansPage> createState() => _ScansPageState();
}

class _ScansPageState extends State<ScansPage> {
  Stream<QuerySnapshot>? _scansStream;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _initializeScansStream();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _initializeScansStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _setScansStream(user.uid);
    } else {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
        if (u != null && mounted) {
          _setScansStream(u.uid);
        }
      });
    }
  }

  Future<void> _setScansStream(String uid) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final userData = userDoc.data();
    final userLevel = userData?['level'] as int? ?? 1;

    if (mounted) {
      setState(() {
        if (userLevel >= 1) {
          _scansStream = FirebaseFirestore.instance
              .collection('scans')
              .snapshots();
        } else {
          _scansStream = FirebaseFirestore.instance
              .collection('scans')
              .where('user', isEqualTo: uid)
              .snapshots();
        }
      });
    }
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
              buildHeader('Your Scans'),
              const SizedBox(height: 10),
              _buildScansList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Please sign in to add a scan',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
            return;
          }
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddScanPage()));
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildScansList() {
    if (_scansStream == null) {
      return const Expanded(
        child: Center(
          child: Text(
            'Please sign in to view scans',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _scansStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No scans found. Press + to add one!',
                style: TextStyle(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
            );
          }
          final scans = snapshot.data!.docs;
          // Ottimizzazione: Raccogliamo tutti gli ID utente e step
          final userIds = scans
              .map(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['user'] as String? ??
                    '',
              )
              .toList();
          final stepIds = scans
              .map(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['step'] as String? ??
                    '',
              )
              .toList();

          return FutureBuilder<Map<String, Map<String, String>>>(
            future: Future.wait([
              fetchUsernames(userIds),
              fetchStepNames(stepIds),
            ]).then((results) => {'users': results[0], 'steps': results[1]}),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (futureSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading data: ${futureSnapshot.error}',
                    style: const TextStyle(color: AppColors.error),
                  ),
                );
              }

              final usernames = futureSnapshot.data?['users'] ?? {};
              final stepNames = futureSnapshot.data?['steps'] ?? {};

              return ListView.builder(
                itemCount: scans.length,
                itemBuilder: (context, index) {
                  final scan = scans[index];
                  final data = scan.data() as Map<String, dynamic>;
                  final title = data['name'] as String? ?? 'No Title';
                  final date = (data['timestamp'] as Timestamp?)?.toDate();
                  final status = data['status'] as int? ?? 0;
                  final userId = data['user'] as String? ?? '';
                  final stepId = data['step'] as String? ?? '';

                  final username = usernames[userId] ?? 'Unknown User';
                  final stepName =
                      stepNames[stepId] ?? 'Unknown or Deleted Step';

                  final scanData = {
                    'scanId': data['scanId'] ?? scan.id,
                    'step': stepName,
                    'name': data['name'] ?? '',
                    'progress': data['progress'] ?? 0,
                    'timestamp': data['timestamp'] ?? '',
                    'user': username,
                    'status': data['status'] ?? -1,
                    'createdAt': data['createdAt'] ?? '',
                    'description': data['description'] ?? '',
                  };

                  return ScanItem(
                    title: title,
                    date: date,
                    status: status,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ScanDetailPage(scan: scanData),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
