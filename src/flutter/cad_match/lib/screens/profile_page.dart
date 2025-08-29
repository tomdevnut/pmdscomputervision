import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
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
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    // Implement change password functionality
  }

  Future<void> _sendLoginInfoEmail() async {
    // Implement send login info email functionality
  }

  @override
  Widget build(BuildContext context) {
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
                _buildUserInfo(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 32),
                        _buildButton(
                          'CHANGE PASSWORD',
                          () => _changePassword(context),
                        ),
                        const SizedBox(height: 16),
                        _buildButton(
                          'RESEND LOGIN INFO EMAIL',
                          _sendLoginInfoEmail,
                        ),
                        const SizedBox(height: 16),
                        _buildButton('LOGOUT', _signOut),
                      ],
                    ),
                  ],
                ),
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
        child: Icon(Icons.person, size: 60, color: AppColors.white),
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
              _buildInfoRow('Name:', nameAndSurname),
              const SizedBox(height: 16),
              _buildInfoRow('Email:', _user?.email ?? 'Loading...'),
              const SizedBox(height: 16),
              _buildInfoRow(
                'Level:',
                _userData?['level']?.toString() ?? 'Loading...',
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                'Enabled:',
                (_userData?['enabled'] ?? false) ? 'Yes' : 'No',
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

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String title, VoidCallback onPressed) {
    return SizedBox(
      width: 300,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
