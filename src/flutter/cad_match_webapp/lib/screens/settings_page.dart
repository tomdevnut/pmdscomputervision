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
              MaterialPageRoute(builder: (context) => const ChangePassword(previousPage: 2)),
            );
          },
        ),
        const SizedBox(height: 12),
        buildListItem(
          title: 'Clean all scans',
          icon: Icons.delete_forever,
          hasArrow: false,
          iconColor: AppColors.danger,
          onTap: () {
            _showDeleteConfirmationDialog(context, 'scans');
          },
        ),
        const SizedBox(height: 12),
        buildListItem(
          title: 'Logout',
          hasArrow: false,
          icon: Icons.logout,
          onTap: () {
            _showLogoutConfirmationDialog(context);
          },
        ),
      ],
    );
  }

  // Metodo per mostrare il popup di conferma
  void _showDeleteConfirmationDialog(BuildContext context, String itemType) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Confirm action',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          content: Text(
            'This action will permanently delete all $itemType.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'NO',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implementare la logica di pulizia qui
                Navigator.of(context).pop();
              },
              child: const Text(
                'YES',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Metodo per mostrare il popup di conferma del logout
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Confirm action',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'NO',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implementa la logica di logout
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text(
                'YES',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
