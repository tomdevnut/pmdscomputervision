import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../utils.dart';

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
        if (userLevel >= 2) {
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
              _buildBanner(),
              const SizedBox(height: 20),
              _buildScansList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your logic to handle the add button press
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/banner.png',
        width: double.infinity,
        height: 160,
        fit: BoxFit.cover,
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
                style: const TextStyle(color: AppColors.red),
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
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final scan = snapshot.data!.docs[index];
              final data = scan.data() as Map<String, dynamic>;
              final title = data['name'] as String? ?? 'No Title';
              final date = (data['timestamp'] as Timestamp?)?.toDate();
              final status = data['status'] as int? ?? 0;

              return ScanItem(title: title, date: date, status: status);
            },
          );
        },
      ),
    );
  }
}

class ScanItem extends StatelessWidget {
  final String title;
  final DateTime? date;
  final int status;

  const ScanItem({
    super.key,
    required this.title,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.tileBackground,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          Icons.arrow_forward_ios,
          color: AppColors.white,
          size: 16,
        ),
        leading: _buildStatusIcon(status),
        onTap: () {
          // Handle scan item tap
        },
      ),
    );
  }

  Widget _buildStatusIcon(int status) {
    switch (status) {
      case 2: // Completed
        return const Icon(Icons.check_circle, color: AppColors.green);
      case 1: // Inviato al server di backend
        return const Icon(Icons.hourglass_top, color: AppColors.yellow);
      case 0: // Ricevuto
        return const Icon(Icons.inbox, color: AppColors.yellow);
      default: // Errore (-1)
        return const Icon(Icons.warning, color: AppColors.red);
    }
  }
}
