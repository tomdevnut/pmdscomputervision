import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'single_user.dart';
import 'login_page.dart';
import 'change_password.dart';
import '../shared_utils.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                builder: (context) =>
                    const SingleUserPage(showControls: false, mainPageIndex: 2),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        buildListItem(
          title: 'Change password',
          icon: Icons.lock,
          hasArrow: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChangePassword(previousPage: 2),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        buildListItem(
          title: 'Resend password',
          icon: Icons.email,
          hasArrow: false,
          onTap: () {
            // TODO: Implementare la logica di invio della password
          },
        ),
        const SizedBox(height: 12),
        buildListItem(
          title: 'Clean all scans',
          icon: Icons.delete_forever,
          hasArrow: false,
          iconColor: AppColors.red,
          onTap: () {
            showConfirmationDialog(
              context: context,
              onConfirm: () {
                // TODO: Implementare la logica di eliminazione
              },
              message:
                  'This action will permanently delete all the scans on the server. This operation cannot be undone.',
            );
          },
        ),
        const SizedBox(height: 12),
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
