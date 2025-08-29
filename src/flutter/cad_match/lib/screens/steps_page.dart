import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../utils.dart';

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
              const Text (
                    'To load steps, please use the web app.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
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
          return const Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)
          ));
        }
        if (snapshot.hasError) {
          return _buildMessage('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildMessage('No steps found.');
        }
        return _buildStepsList(snapshot.data!.docs);
      },
    );
  }

  Widget _buildStepsList(List<QueryDocumentSnapshot> steps) {
    return ListView.builder(
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final data = step.data() as Map<String, dynamic>;
        final title = data['name'] as String? ?? 'No Title';
        final subtitle = data['description'] as String? ?? 'No Description';
        final stepNumber = index + 1;

        return _buildStepCard(title, subtitle, stepNumber);
      },
    );
  }

  Widget _buildStepCard(String title, String subtitle, int stepNumber) {
    return Card(
      color: AppColors.tileBackground,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.file_copy, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.white,
          size: 16,
        ),
        onTap: () {
          // Handle step item tap
        },
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textPrimary),
        textAlign: TextAlign.center,
      ),
    );
  }
}
