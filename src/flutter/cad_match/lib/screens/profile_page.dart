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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
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
    setState(() => _isLoading = false);
  }

  Future<void> _signOut(BuildContext context) async {
    showConfirmationDialog(
      context,
      'Are you sure you want to log out?',
      () async {
        await FirebaseAuth.instance.signOut();
      },
      title: 'Logout',
      confirmText: 'Logout',
      pop: false,
    );
  }

  Future<void> _resetPassword(BuildContext context) async {
    if (_user?.email == null) return;

    showConfirmationDialog(
      context,
      'A reset link will be sent to your email: ${_user!.email}.',
      () async {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _user!.email!,
        );
      },
      title: 'Reset Password',
      confirmText: 'Send Email',
      cancelText: 'Cancel',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _user == null
          ? _buildSignedOutView()
          : SingleChildScrollView(
              padding: const EdgeInsets.only(top: 100.0, bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileIconWithBadge(),
                  const SizedBox(height: 16),
                  Text(
                    '${_userData?['name'] ?? ''} ${_userData?['surname'] ?? ''}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _user?.email ?? '',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildActionsMenu(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileIconWithBadge() {
    String level = _userData?['level']?.toString() ?? '...';
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        const CircleAvatar(
          radius: 60,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person_rounded, size: 60, color: Colors.white),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.backgroundColor, width: 3),
          ),
          child: Text(
            level,
            style: const TextStyle(
              color: AppColors.buttonText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadows,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.shield_rounded,
            label: 'Status',
            value: (_userData?['enabled'] ?? false) ? 'Enabled' : 'Not Enabled',
          ),
          // Aggiungi qui altre info se necessario
        ],
      ),
    );
  }

  Widget _buildActionsMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadows,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionRow(
            icon: Icons.lock_reset_rounded,
            title: 'Reset Password',
            onTap: () => _resetPassword(context),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildActionRow(
            icon: Icons.logout_rounded,
            title: 'Logout',
            color: AppColors.error,
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(icon, color: color ?? AppColors.primary),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.unselected,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignedOutView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_off_rounded,
            size: 80,
            color: AppColors.unselected,
          ),
          const SizedBox(height: 20),
          const Text(
            'You are not signed in',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please sign in to view your profile.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
