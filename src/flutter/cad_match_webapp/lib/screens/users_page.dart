import 'package:flutter/material.dart';
import 'single_user.dart';
import 'new_user.dart';
import '../shared_utils.dart';
import 'bulk_upload.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
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
            PopupMenuButton<String>(
              color: AppColors.white,
              child: InkWell(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: ShapeDecoration(
                    color: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
              onSelected: (String result) {
                if (result == 'single_user') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NewUser()),
                  );
                } else if (result == 'bulk_upload') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BulkUpload()),
                  );
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'single_user',
                  child: Row(
                    children: [
                      Icon(Icons.person_add, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Create single user'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'bulk_upload',
                  child: Row(
                    children: [
                      Icon(Icons.groups, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Bulk upload (CSV)'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Esempi di elementi della lista di utenti
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
