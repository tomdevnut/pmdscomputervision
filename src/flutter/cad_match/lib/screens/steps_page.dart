import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../utils.dart';

// Funzione per recuperare i nomi utente in un'unica query
Future<Map<String, String>> fetchUsernames(List<String> userIds) async {
  final validUserIds = userIds.where((id) => id.isNotEmpty).toList();
  if (validUserIds.isEmpty) {
    return {};
  }
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

  // --- STATO PER L'ESPANSIONE ---
  String? _expandedStepId;

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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            Expanded(child: _buildStepsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 16.0,
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
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
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
              'No steps found.',
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
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final doc = steps[index];
                final data = doc.data() as Map<String, dynamic>;
                final bool isExpanded = doc.id == _expandedStepId;

                return _buildExpandableStepItem(
                  data: data,
                  docId: doc.id,
                  usernames: usernames,
                  isExpanded: isExpanded,
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedStepId = null; // Se è già aperto, chiudilo
                      } else {
                        _expandedStepId = doc.id; // Altrimenti, aprilo
                      }
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // --- WIDGET PER L'ELEMENTO ESPANDIBILE ---
  Widget _buildExpandableStepItem({
    required Map<String, dynamic> data,
    required String docId,
    required Map<String, String> usernames,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    final title = (data['name'] as String?)?.isNotEmpty == true
        ? data['name'] as String
        : (data['stepId'] as String?) ?? 'No Title';
    final description = (data['description'] as String?)?.isNotEmpty == true
        ? data['description'] as String
        : 'No Description';
    final userId = data['user'] as String? ?? '';
    final username = usernames[userId] ?? 'Unknown User';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadows,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- VISTA COMPATTA ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.rowBoxColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.file_copy_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!isExpanded) ...[
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.unselected,
                      ),
                    ],
                  ),
                  // --- VISTA ESPANSA (appare solo se isExpanded è true) ---
                  if (isExpanded) ...[
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.description_outlined,
                      'Description',
                      description,
                    ),
                    _buildInfoRow(Icons.person_outline, 'Author', username),
                    _buildInfoRow(Icons.vpn_key_outlined, 'Step ID', docId),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
