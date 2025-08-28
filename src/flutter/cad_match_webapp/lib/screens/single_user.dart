import 'package:flutter/material.dart';

// Devi importare la MainPage per poterla usare per la navigazione
import 'main_page.dart';

class SingleUserPage extends StatelessWidget {
  final bool isUserEnabled;
  final bool showControls;
  final int mainPageIndex;

  const SingleUserPage({
    super.key,
    this.isUserEnabled = true,
    this.showControls = true,
    this.mainPageIndex = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFE1EDFF,
      ), // Imposta il colore di sfondo per coerenza
      body: SafeArea(
        child: Column(
          children: [
            // Top bar con il pulsante "back"
            _buildTopBar(context),
            const SizedBox(height: 40),
            // Sezione centrale con l'icona e le informazioni dell'utente
            _buildUserInfoSection(isUserEnabled, 2),
            const SizedBox(height: 100),
            // Pulsanti di azione per la gestione dell'utente
            if (showControls) _buildActionButtons(context, isUserEnabled),
          ],
        ),
      ),
    );
  }

  // Costruisce la barra superiore con il pulsante per tornare indietro
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              // Usa Navigator.pushReplacement per tornare alla MainPage e impostare
              // la pagina iniziale su 3 (che corrisponde a UsersPage).
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MainPage(initialPageIndex: mainPageIndex),
                ),
              );
            },
            child: Row(
              children: const [
                Icon(Icons.arrow_back_ios, color: Color(0xFF111416), size: 24),
                SizedBox(width: 8),
                Text(
                  'BACK',
                  style: TextStyle(
                    color: Color(0xFF111416),
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            color: const Color(0xFF002C58),
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
            color: Color(0xFF111416),
            fontSize: 28,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'email@test.com',
          style: TextStyle(
            color: Color(0xFF6B7582),
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
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
                    color: isEnabled
                        ? const Color(0xFF03A411)
                        : const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEnabled ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  isEnabled ? 'Enabled' : 'Disabled',
                  style: const TextStyle(
                    color: Color(0xFF111416),
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$level',
                      style: const TextStyle(
                        color: Color(0xFF111416),
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
                    color: Color(0xFF111416),
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
        _buildActionButton(
          label: isEnabled ? 'Disable User' : 'Enable User',
          icon: isEnabled ? Icons.cancel : Icons.check_circle,
          color: isEnabled ? const Color(0xFFD32F2F) : const Color(0xFF03A411),
          onTap: () {
            // TODO: Logica per (dis)abilitare l'utente
            print("Pulsante 'Enable/Disable' premuto!");
          },
        ),
        const SizedBox(width: 70),
        // Pulsante per eliminare
        _buildActionButton(
          label: 'Delete User',
          icon: Icons.delete,
          color: const Color(0xFFD32F2F),
          onTap: () {
            _showConfirmationDialog(context);
          },
        ),
      ],
    );
  }

  // Metodo helper per costruire un singolo pulsante di azione
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            'This action will permanently delete the user and their associated scans.',
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
