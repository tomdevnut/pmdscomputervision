import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      if (mounted) {
        setState(() {
          _userData = doc.data();
        });
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _resetPassword(BuildContext context) async {
    showConfirmationDialog(
      context,
      'Are you sure you want to reset your password? A reset link will be sent to your email.',
      () async {
        Navigator.of(context).pop();
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _user?.email ?? '',
        );
      },
      title: 'Reset Password',
      confirmText: 'Reset',
      cancelText: 'Cancel',
    );
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = AppColors.cardBackground;
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildHeader('Profile'),
                const SizedBox(height: 20),
                _buildProfileIcon(),
                const SizedBox(height: 32),
                // Card per le informazioni dell'utente
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.boxborder),
                  ),
                  child: _buildUserInfo(),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: buildButton(
                        'RESET PASSWORD',
                        onPressed: () => _resetPassword(context),
                        icon: Icons.lock_reset_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: buildButton('LOGOUT', onPressed: _signOut, icon: Icons.logout_rounded)),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileIcon() {
    return const Center(
      child: CircleAvatar(
        radius: 60,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.person_rounded, size: 60, color: Colors.white),
      ),
    );
  }

  Widget _buildUserInfo() {
    String nameAndSurname =
        '${_userData?['name'] ?? ''} ${_userData?['surname'] ?? ''}';
    return _user != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cardField('Name:', nameAndSurname, Icons.person_rounded),
              const SizedBox(height: 10),
              const Divider(color: AppColors.boxborder),
              const SizedBox(height: 10),
              cardField('Email:', _user?.email ?? 'Loading...', Icons.email_rounded),
              const SizedBox(height: 10),
              const Divider(color: AppColors.boxborder),
              const SizedBox(height: 10),
              cardField(
                'Level:',
                _userData?['level']?.toString() ?? 'Loading...',
                Icons.bar_chart_rounded,
              ),
              const SizedBox(height: 10),
              const Divider(color: AppColors.boxborder),
              const SizedBox(height: 10),
              cardField(
                'Enabled:',
                (_userData?['enabled'] ?? false) ? 'Yes' : 'No',
                (_userData?['enabled'] ?? false)                    
                ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
              ),
            ],
          )
        : Center(
            child: Text(
              'Please sign in to view your profile.',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          );
  }
}
