import 'package:flutter/material.dart';
import 'single_user.dart';
import 'login_page.dart';

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
                color: Color(0xFF111416),
                fontSize: 28,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 44), // Placeholder per l'allineamento
          ],
        ),
        const SizedBox(height: 20),
        // Lista di opzioni per le impostazioni
        _buildSettingsItem(
          context,
          Icons.person,
          'Account details',
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
        _buildSettingsItem(
          context,
          Icons.lock,
          'Change password',
          hasArrow: true,
          onTap: () {}
        ),

        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          Icons.logout,
          'Log out',
          hasArrow: false,
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
        ),
        
        // TODO: mostrare questa voce solo se utente di livello alto
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          Icons.delete,
          'Clean all scans',
          hasArrow: false,
          onTap: () => _showConfirmationDialog(context),
          iconBackgroundColor: const Color(0xFFD32F2F),
        ),
      ],
    );
  }

  // Metodo helper per costruire gli elementi della lista delle impostazioni
  Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String title, {
    required bool hasArrow,
    required VoidCallback onTap,
    Color iconBackgroundColor = const Color(0xFF002C58),
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8), // Spazio tra le voci
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: ShapeDecoration(
                    color: iconBackgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111416),
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (hasArrow)
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF6B7582),
              ),
          ],
        ),
      ),
    );
  }

  // Metodo per mostrare il dialogo di conferma
  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFE1EDFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text(
            'Are you sure?',
            style: TextStyle(
              color: Color(0xFF111416),
              fontSize: 20,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          content: const Text(
            'This action will permanently delete all scans.',
            style: TextStyle(
              color: Color(0xFF6B7582),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Azione per il tasto "NO"
                Navigator.of(context).pop(); // Chiude il popup
              },
              child: const Text(
                'NO',
                style: TextStyle(
                  color: Color(0xFF002C58),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Azione per il tasto "YES"
                // TODO: Implementare la logica di pulizia qui
                Navigator.of(context).pop(); // Chiude il popup
              },
              child: const Text(
                'YES',
                style: TextStyle(
                  color: Color(0xFFD32F2F),
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
