import 'package:flutter/material.dart';
import 'single_user.dart';
import 'new_user.dart';
import '../shared_utils.dart'; // Importa il file di utility condiviso

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
                color: AppColors.textPrimary,
                fontSize: 28,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            // TODO: mostrare il pulsante + solo se utente di livello >= 1
            buildAddButton(context, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewUser()),
              );
            }),
          ],
        ),
        const SizedBox(height: 20),
        // Lista di utenti
        buildListItem(
          title: 'John Doe',
          subtitle: 'Level 2 - Enabled',
          icon: Icons.person,
          hasArrow: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SingleUserPage()),
            );
          },
        ),
        const SizedBox(height: 12),
        buildListItem(
          title: 'Jane Smith',
          subtitle: 'Level 1 - Disabled',
          icon: Icons.person,
          hasArrow: true,
          iconColor: AppColors.disabledButton,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const SingleUserPage(isUserEnabled: false),
              ),
            );
          },
        ),
      ],
    );
  }
}
