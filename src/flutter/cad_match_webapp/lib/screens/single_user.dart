import 'package:flutter/material.dart';
import 'change_password.dart';
import '../shared_utils.dart';

class SingleUserPage extends StatelessWidget {
  final bool isUserEnabled;
  final bool
  showControls; // se provengo dalla pagina settings non mostro i controlli, TODO: se l'utente ha livello 2 non posso cancellarlo/disabilitarlo

  const SingleUserPage({
    super.key,
    this.isUserEnabled = true,
    this.showControls = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),

          child: Column(
            children: [
              // Top bar con il pulsante "back"
              buildTopBar(context, title: 'USER INFO'),
              const SizedBox(height: 40),
              // Sezione centrale con l'icona e le informazioni dell'utente
              _buildUserInfoSection(isUserEnabled, 2),
              const SizedBox(height: 80),
              // Pulsanti di azione per la gestione dell'utente
              if (showControls) _buildActionButtons(context, isUserEnabled),
            ],
          ),
        ),
      ),
    );
  }

  // Costruisce la sezione con l'icona, il nome e l'email dell'utente
  Widget _buildUserInfoSection(bool isEnabled, int level) {
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
        const Text(
          'User Xyz',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'email@test.com',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24), // Spazio tra email e i nuovi box
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Box di stato abilitato/disabilitato
            Column(
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
                const SizedBox(width: 16),
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
            ),
            const SizedBox(width: 70), // Spazio tra i due box
            // Box del livello
            Column(
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
                const SizedBox(width: 16),
                Text(
                  'Level',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Costruisce la sezione con i pulsanti di gestione (Abilita/Disabilita e Elimina)
  Widget _buildActionButtons(BuildContext context, bool isEnabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsante per abilitare/disabilitare
        buildButton(
          label: isEnabled ? 'Disable user' : 'Enable user',
          icon: isEnabled ? Icons.cancel : Icons.check_circle,
          backgroundColor: isEnabled ? AppColors.red : AppColors.green,
          onTap: () {
            // TODO: Logica per (dis)abilitare l'utente
          },
        ),
        const SizedBox(width: 30),
        // Pulsante per modificare la password
        buildButton(
          label: 'Change user\'s password',
          icon: Icons.lock,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChangePassword(),
              )
            );
          },
        ),
        const SizedBox(width: 30),
        // Pulsante per rimandare la mail con le info di accesso
        buildButton(
          label: 'Send password email',
          icon: Icons.email,
          onTap: () {
            // TODO: Logica per rimandare l'email
          },
        ),
        const SizedBox(width: 30),
        // Pulsante per eliminare
        buildButton(
          label: 'Delete user',
          icon: Icons.delete,
          backgroundColor: AppColors.red,
          onTap: () {
            showConfirmationDialog(
              context: context,
              message:
                  'This action will permanently delete the user and their associated scans.',
              onConfirm: () {
                // TODO: Logica per eliminare l'utente
              },
            );
          },
        ),
      ],
    );
  }
}
