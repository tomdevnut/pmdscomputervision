import 'package:flutter/material.dart';
import 'single_user.dart';
import '../shared_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String kCleanScansUrl ='https://clean-scans-5ja5umnfkq-ey.a.run.app';

class SettingsPage extends StatefulWidget {
  final int level;

  const SettingsPage({super.key, required this.level});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _cleanScans() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated.');
      }
      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse(kCleanScansUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All scans have been successfully deleted.'),
            backgroundColor: AppColors.green,
          ),
        );
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final errorMessage =
            responseData['message'] ?? 'An unknown error occurred.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SETTINGS',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 44),
          ],
        ),
        const SizedBox(height: 20),
        // Lista di opzioni per le impostazioni
        buildListItem(
          title: 'Account details',
          icon: Icons.person,
          hasArrow: true,
          onTap: () {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SingleUserPage(showControls: false, userId: user.uid),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        buildListItem(
          title: 'Reset password',
          icon: Icons.password,
          hasArrow: false,
          onTap: () {
            showConfirmationDialog(
              context: context,
              onConfirm: () {
                FirebaseAuth.instance.sendPasswordResetEmail(
                  email: FirebaseAuth.instance.currentUser?.email ?? '',
                );
              },
              message:
                  'A password reset link will be sent to your registered email address. Do you want to proceed?',
            );
          },
        ),
        const SizedBox(height: 12),
        if (widget.level > 0)
          buildListItem(
            title: 'Clean all scans',
            icon: Icons.delete_forever,
            hasArrow: false,
            iconColor: AppColors.red,
            onTap: _cleanScans,
          ),
        if (widget.level > 0) const SizedBox(height: 12),
        buildListItem(
          title: 'Logout',
          hasArrow: false,
          icon: Icons.logout,
          onTap: () {
            showConfirmationDialog(
              context: context,
              onConfirm: () async {
                await FirebaseAuth.instance.signOut();
              },
              message: 'Are you sure you want to logout?',
            );
          },
        ),
      ],
    );
  }
}
