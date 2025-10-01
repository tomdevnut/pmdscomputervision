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

class StepsPage extends StatefulWidget {
  const StepsPage({super.key});

  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> {
  Stream<QuerySnapshot>? _stepsStream;
  StreamSubscription<User?>? _authSub;

  final _searchController = TextEditingController();
  Timer? _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _initializeStreamLogic();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebouncer?.cancel();
    super.dispose();
  }

  void _initializeStreamLogic() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _buildAndSetStepsStream();
    } else {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
        if (u != null && mounted) {
          _buildAndSetStepsStream();
        }
      });
    }
  }

  void _onSearchChanged() {
    if (_searchDebouncer?.isActive ?? false) _searchDebouncer!.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      _buildAndSetStepsStream();
    });
  }

  void _buildAndSetStepsStream() {
    Query query = FirebaseFirestore.instance.collection('steps');
    final searchTerm = _searchController.text.trim();

    if (searchTerm.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .orderBy('name');
    } else {
      query = query.orderBy('name');
    }

    if (mounted) {
      setState(() {
        _stepsStream = query.snapshots();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(),
          Expanded(child: _buildStepsList()),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 40.0,
        left: 24.0,
        right: 24.0,
        bottom: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Steps',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'To load and manage steps, please use the web app.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: 'Search by name...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.cardBackground,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsList() {
    if (_stepsStream == null) {
      return const Center(
        child: Text(
          'Please sign in to view steps',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _stepsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
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
              'No steps found. Please mind that step names are case-sensitive.',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
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
            if (futureSnapshot.connectionState == ConnectionState.waiting &&
                futureSnapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (futureSnapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading user data: ${futureSnapshot.error}',
                  style: const TextStyle(color: AppColors.error),
                ),
              );
            }

            final usernames = futureSnapshot.data ?? {};

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
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

                // Usiamo il nuovo widget da utils.dart
                return buildStepListItem(
                  title: title,
                  subtitle: description,
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
