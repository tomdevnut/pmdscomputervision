import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../utils.dart';
import 'add_scan_page.dart';
import 'scan_detail_page.dart';

Future<Map<String, String>> fetchStepNames(List<String> stepIds) async {
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

class ScansPage extends StatefulWidget {
  const ScansPage({super.key});

  @override
  State<ScansPage> createState() => _ScansPageState();
}

class _ScansPageState extends State<ScansPage> {
  Stream<QuerySnapshot>? _scansStream;
  StreamSubscription<User?>? _authSub;

  final _searchController = TextEditingController();
  Timer? _searchDebouncer;
  bool _showFilters = false;

  int? _activeStatusFilter;
  bool _filterOnlyMyScans = false;

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
      _buildAndSetScansStream();
    } else {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
        if (u != null && mounted) {
          _buildAndSetScansStream();
        }
      });
    }
  }

  void _onSearchChanged() {
    if (_searchDebouncer?.isActive ?? false) _searchDebouncer!.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      _buildAndSetScansStream();
    });
  }

  Future<void> _buildAndSetScansStream() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data();
    final userLevel = userData?['level'] as int? ?? 1;

    Query query = FirebaseFirestore.instance.collection('scans');

    if (_filterOnlyMyScans || userLevel < 1) {
      query = query.where('user', isEqualTo: user.uid);
    }

    if (_activeStatusFilter != null) {
      query = query.where('status', isEqualTo: _activeStatusFilter);
    }

    final searchTerm = _searchController.text.trim();
    if (searchTerm.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThanOrEqualTo: '$searchTerm\uf8ff');
    }

    if (searchTerm.isNotEmpty) {
      query = query.orderBy('name');
    } else {
      query = query.orderBy('timestamp', descending: true);
    }

    if (mounted) {
      setState(() {
        _scansStream = query.snapshots();
      });
    }
  }

  Map<String, dynamic> _getStatusIconForScan(int status) {
    switch (status) {
      case 2:
        return {'icon': Icons.check_circle_rounded, 'color': AppColors.success};
      case 1:
        return {
          'icon': Icons.hourglass_top_rounded,
          'color': AppColors.warning,
        };
      case 0:
        return {'icon': Icons.inbox_rounded, 'color': AppColors.warning};
      default:
        return {'icon': Icons.error_rounded, 'color': AppColors.error};
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasActiveFilters = _activeStatusFilter != null || _filterOnlyMyScans;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(hasActiveFilters),
          if (_showFilters) _buildFilterChips(),
          _buildScansList(),
        ],
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
                    style: TextStyle(color: AppColors.buttonText),
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
        foregroundColor: AppColors.buttonText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildHeaderSection(bool hasActiveFilters) {
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
            'Your Scans',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    prefixIcon: Icon(Icons.search, color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => setState(() => _showFilters = !_showFilters),
                icon: Icon(Icons.filter_list_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.cardBackground,
                  foregroundColor: hasActiveFilters
                      ? AppColors.secondary
                      : AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 10),
      child: Row(
        children: [
          _buildFilterChip("My Scans", _filterOnlyMyScans, () {
            setState(() => _filterOnlyMyScans = !_filterOnlyMyScans);
            _buildAndSetScansStream();
          }),
          _buildFilterChip("Completed", _activeStatusFilter == 2, () {
            setState(
              () => _activeStatusFilter = _activeStatusFilter == 2 ? null : 2,
            );
            _buildAndSetScansStream();
          }),
          _buildFilterChip("Processing", _activeStatusFilter == 1, () {
            setState(
              () => _activeStatusFilter = _activeStatusFilter == 1 ? null : 1,
            );
            _buildAndSetScansStream();
          }),
          _buildFilterChip("Sent", _activeStatusFilter == 0, () {
            setState(
              () => _activeStatusFilter = _activeStatusFilter == 0 ? null : 0,
            );
            _buildAndSetScansStream();
          }),
          _buildFilterChip("Error", _activeStatusFilter == -1, () {
            setState(
              () => _activeStatusFilter = _activeStatusFilter == -1 ? null : -1,
            );
            _buildAndSetScansStream();
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        checkmarkColor: AppColors.primary,
        backgroundColor: AppColors.cardBackground,
        selectedColor: AppColors.primary.withAlpha(51),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : AppColors.unselected.withAlpha(128),
          ),
        ),
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
                'No scans found for the current filters. Please mind that scan names are case-sensitive.',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }
          final scans = snapshot.data!.docs;
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
              if (futureSnapshot.connectionState == ConnectionState.waiting &&
                  futureSnapshot.data == null) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
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
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: scans.length,
                itemBuilder: (context, index) {
                  final scan = scans[index];
                  final data = scan.data() as Map<String, dynamic>;
                  final date = (data['timestamp'] as Timestamp?)?.toDate();
                  final status = data['status'] as int? ?? 0;
                  final statusIconData = _getStatusIconForScan(status);

                  final scanData = {
                    'scanId': data['scanId'] ?? scan.id,
                    'step':
                        stepNames[data['step'] as String? ?? ''] ??
                        'Unknown Step',
                    'name': data['name'] ?? '',
                    'progress': data['progress'] ?? 0,
                    'timestamp': data['timestamp'] ?? '',
                    'user':
                        usernames[data['user'] as String? ?? ''] ??
                        'Unknown User',
                    'status': data['status'] ?? -1,
                    'createdAt': data['createdAt'] ?? '',
                    'description': data['description'] ?? '',
                  };

                  return buildScanListItem(
                    title: data['name'] as String? ?? 'No Title',
                    subtitle: date != null
                        ? DateFormat.yMMMd().add_jm().format(date)
                        : 'No date',
                    statusIcon: statusIconData['icon'],
                    statusIconColor: statusIconData['color'],
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
