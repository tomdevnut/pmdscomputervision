import 'package:flutter/material.dart';
import 'single_user.dart';
import 'new_user.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'USERS MANAGEMENT',
              style: TextStyle(
                color: Color(0xFF111416),
                fontSize: 28,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewUser()),
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: ShapeDecoration(
                  color: const Color(0xFF002C58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Lista di utenti
        _buildUserItem(context, 'User 1', 1, true),
        const SizedBox(height: 12),
        _buildUserItem(context, 'User 2', 1, false),
        const SizedBox(height: 12),
        _buildUserItem(context, 'User 3', 0, true),
        const SizedBox(height: 12),
        _buildUserItem(context, 'User 4', 2, true),
      ],
    );
  }

  // Metodo helper per costruire gli elementi della lista utenti
  Widget _buildUserItem(
    BuildContext context,
    String userName,
    int level,
    bool isEnabled,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SingleUserPage(isUserEnabled: true),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8), // Spazio tra le voci
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white, // Sfondo bianco
          borderRadius: BorderRadius.circular(10), // Bordi arrotondati
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
                    color: (isEnabled
                        ? const Color(0xFF002C58)
                        : const Color(0xFF6B7582)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  userName,
                  style: TextStyle(
                    color: const Color(0xFF111416),
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Level $level - ${isEnabled ? "Enabled" : "Disabled"}',
                  style: const TextStyle(
                    color: Color(0xFF6B7582),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF6B7582),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
