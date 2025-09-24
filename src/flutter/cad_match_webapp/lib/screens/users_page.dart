import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  // Riferimento alla collezione "users"
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

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

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _usersCollection.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No users found.'));
              }

              // Se i dati sono disponibili, costruisci la lista di utenti
              final users = snapshot.data!.docs;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userDoc = users[index];
                  final userData = userDoc.data() as Map<String, dynamic>;
                  final isUserEnabled = userData['enabled'] ?? true;
                  final userLevel = userData['level'] ?? 0;
                  final userName = userData['name'] ?? 'No name';
                  final userSurname = userData['surname'] ?? 'No surname';

                  final title = '$userName $userSurname';
                  final subtitle =
                      'Level $userLevel - ${isUserEnabled ? 'Enabled' : 'Disabled'}';
                  final iconColor = isUserEnabled
                      ? AppColors.primary
                      : AppColors.disabledButton;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: buildListItem(
                      title: title,
                      subtitle: subtitle,
                      icon: Icons.person,
                      iconColor: iconColor,
                      hasArrow: true,
                      onTap: () {
                        // Passa l'ID del documento e i dati alla schermata SingleUserPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SingleUserPage(userId: userDoc.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
