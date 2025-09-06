import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../shared_utils.dart';
import 'change_password.dart';

const String kDeleteUserUrl = 'https://delete-user-5ja5umnfkq-ey.a.run.app';
const String kDisableUserUrl = 'https://disable-user-5ja5umnfkq-ey.a.run.app';
const String kEnableUserUrl = 'https://enable-user-5ja5umnfkq-ey.a.run.app';

class SingleUserPage extends StatefulWidget {
  final String userId;
  final bool showControls;

  const SingleUserPage({
    super.key,
    required this.userId,
    this.showControls = true,
  });

  @override
  State<SingleUserPage> createState() => _SingleUserPageState();
}

class _SingleUserPageState extends State<SingleUserPage> {
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        FirebaseAuth.instance.userChanges().first,
        _usersCollection.doc(widget.userId).get(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final user = snapshot.data![0] as User?;
        final userDoc = snapshot.data![1] as DocumentSnapshot;
        if (!userDoc.exists) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(child: Text('User not found.')),
          );
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final userName = userData['name'] ?? 'N/A';
        final userSurname = userData['surname'] ?? 'N/A';
        final isEnabled = userData['enabled'] ?? false;
        final userLevel = userData['level'] ?? 0;
        final userEmail = widget.userId == user?.uid ? user?.email ?? 'Email not available' : (userData['email'] ?? 'N/A');

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              child: Column(
                children: [
                  buildTopBar(context, title: 'USER INFO'),
                  const SizedBox(height: 40),
                  _buildUserInfoSection(
                    userName: '$userName $userSurname',
                    userEmail: userEmail,
                    isUserEnabled: isEnabled,
                    userLevel: userLevel,
                  ),
                  const SizedBox(height: 80),
                  if (widget.showControls)
                    _buildActionButtons(
                      context: context,
                      isUserEnabled: isEnabled,
                      userLevel: userLevel,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSnackbar({required String message, bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppColors.white)),
        backgroundColor: isError ? Colors.red : AppColors.green,
      ),
    );
  }

  Future<void> _toggleUserStatus(bool isEnabled) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      if (idToken == null) {
        throw Exception('User is not authenticated.');
      }

      final url = isEnabled ? kDisableUserUrl : kEnableUserUrl;
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'uid': widget.userId}),
      );

      if (response.statusCode == 200) {
        _showSnackbar(
          message: 'User successfully ${isEnabled ? 'disabled' : 'enabled'}.',
        );
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final errorMessage =
            responseData['message'] ?? 'An unknown error occurred.';
        _showSnackbar(
          message:
              'Failed to ${isEnabled ? 'disable' : 'enable'} user: $errorMessage',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackbar(message: 'Error toggling user status: $e', isError: true);
    }
  }

  Future<void> _deleteUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      if (idToken == null) {
        throw Exception('User is not authenticated.');
      }

      final response = await http.post(
        Uri.parse(kDeleteUserUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'uid': widget.userId}),
      );

      if (response.statusCode == 200) {
        _showSnackbar(message: 'User successfully deleted.');
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final errorMessage =
            responseData['message'] ?? 'An unknown error occurred.';
        _showSnackbar(
          message: 'Failed to delete user: $errorMessage',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackbar(message: 'Error deleting user: $e', isError: true);
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    try {
      final userDoc = await _usersCollection.doc(widget.userId).get();
      if (!userDoc.exists) {
        _showSnackbar(message: 'User not found in Firestore.', isError: true);
        return;
      }
      final userData = userDoc.data() as Map<String, dynamic>;
      final userEmail = userData['email'] as String?;

      if (userEmail == null || userEmail.isEmpty) {
        _showSnackbar(message: 'User email not available.', isError: true);
        return;
      }
      await FirebaseAuth.instance.sendPasswordResetEmail(email: userEmail);
      _showSnackbar(message: 'Password reset email sent to $userEmail.');
    } catch (e) {
      _showSnackbar(
        message: 'Failed to send password reset email: $e',
        isError: true,
      );
    }
  }

  Widget _buildUserInfoSection({
    required String userName,
    required String userEmail,
    required bool isUserEnabled,
    required int userLevel,
  }) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: ShapeDecoration(
            color: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 60),
        ),
        const SizedBox(height: 24),
        Text(
          userName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          userEmail,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusBox(isUserEnabled),
            const SizedBox(width: 70),
            _buildLevelBox(userLevel),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBox(bool isEnabled) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.green : AppColors.red,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isEnabled ? Icons.check : Icons.close,
            color: AppColors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isEnabled ? 'Enabled' : 'Disabled',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelBox(int level) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.borderGray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$level',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Level',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons({
    required BuildContext context,
    required bool isUserEnabled,
    required int userLevel,
  }) {
    final bool canDeleteOrDisable = userLevel < 2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (canDeleteOrDisable)
          buildButton(
            label: isUserEnabled ? 'Disable user' : 'Enable user',
            icon: isUserEnabled ? Icons.cancel : Icons.check_circle,
            backgroundColor: isUserEnabled ? AppColors.red : AppColors.green,
            onTap: () => _toggleUserStatus(isUserEnabled),
          ),
        if (canDeleteOrDisable) const SizedBox(width: 30),
        if (canDeleteOrDisable)
          buildButton(
            label: 'Send password reset email',
            icon: Icons.email,
            onTap: _sendPasswordResetEmail,
          ),
        if (canDeleteOrDisable) const SizedBox(width: 30),
        // Pulsante per modificare la password
        if (canDeleteOrDisable) buildButton(
          label: 'Change user\'s password',
          icon: Icons.lock,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChangePassword(userId: widget.userId)),
            );
          },
        ),
        if (canDeleteOrDisable) const SizedBox(width: 30),
        if (canDeleteOrDisable) buildButton(
          label: 'Delete user',
          icon: Icons.delete,
          backgroundColor: AppColors.red,
          onTap: () {
              showConfirmationDialog(
                context: context,
                message:
                    'This action will permanently delete the user and their associated scans.',
                onConfirm: _deleteUser,
              );
            },
          ),
      ],
    );
  }
}
