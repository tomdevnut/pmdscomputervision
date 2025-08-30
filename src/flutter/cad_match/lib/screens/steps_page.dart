import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../utils.dart';
import 'step_detail_page.dart';

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
        final doc = steps[index];
        final data = doc.data() as Map<String, dynamic>;

        // titoli/sottotitoli per la tile
        final title = (data['name'] as String?)?.trim().isNotEmpty == true
            ? data['name'] as String
            : (data['stepId'] as String?) ?? 'No Title';
        final subtitle = (data['description'] as String?)?.trim().isNotEmpty == true
            ? data['description'] as String
            : (data['status'] as String?) ?? 'No Description';

        // conversioni/estrazioni per la pagina di dettaglio
        final createdAt = (data['createdAt'] is Timestamp)
            ? (data['createdAt'] as Timestamp).toDate()
            : data['createdAt']; // può rimanere String ISO o DateTime
        final completed = (data['completed'] is bool) ? data['completed'] as bool : false;
        final accuracy = data['accuracy'];        // int/double/null
        final thumbnail = data['thumbnail'];      // url/path/null

        return _buildStepCard(
          title,
          subtitle,
          index + 1,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StepDetailPage(
                  step: {
                    'stepId': doc.id,       // usa l'ID del documento come identificativo
                    'createdAt': createdAt, // DateTime o String
                    'completed': completed, // bool
                    'accuracy': accuracy,   // num
                    'thumbnail': thumbnail, // opzionale
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStepCard(String title, String subtitle, int stepNumber, {VoidCallback? onTap}) {
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
        onTap: onTap,
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
