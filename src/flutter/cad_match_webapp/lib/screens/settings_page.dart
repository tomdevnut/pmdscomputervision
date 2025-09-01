import 'package:flutter/material.dart';
import 'single_user.dart';
import 'login_page.dart';
import '../shared_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class SettingsPage extends StatefulWidget {
  final int level;

  const SettingsPage({super.key, required this.level});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SingleUserPage(showControls: false),
              ),
            );
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
                // invio della richiesta di password reset con authentication
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
            onTap: () async {
              try {
                // Call the cloud function and await its result TODO: check after function improvement
                final HttpsCallableResult result = await FirebaseFunctions
                    .instance
                    .httpsCallable('clean_scans')
                    .call();
                if (mounted) {
                  // Check the result from the cloud function
                  if (result.data != null &&
                      result.data['status'] == 'success') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'All scans have been successfully deleted.',
                        ),
                        backgroundColor: AppColors.green,
                      ),
                    );
                  } else {
                    // Handle a failure response from the function
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: ${result.data['message'] ?? 'An unknown error occurred.'}',
                        ),
                        backgroundColor: AppColors.red,
                      ),
                    );
                  }
                }
              } on FirebaseFunctionsException catch (e) {
                // Handle specific Firebase function errors
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Function error: ${e.message}'),
                    backgroundColor: AppColors.red,
                  ),
                );
              } catch (e) {
                // Handle any other unexpected errors
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('An unexpected error occurred: $e'),
                    backgroundColor: AppColors.red,
                  ),
                );
              }
            },
          ),

        if (widget.level > 0) const SizedBox(height: 12),

        buildListItem(
          title: 'Logout',
          hasArrow: false,
          icon: Icons.logout,
          onTap: () {
            showConfirmationDialog(
              context: context,
              onConfirm: () {
                // TODO: Implementare la logica di logout
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              message: 'Are you sure you want to logout?',
            );
          },
        ),
      ],
    );
  }
}
