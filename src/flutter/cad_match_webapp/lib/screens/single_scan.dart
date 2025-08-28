import 'package:flutter/material.dart';
import 'main_page.dart';

class SingleScan extends StatelessWidget {
  const SingleScan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1EDFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra superiore con il pulsante "BACK"
              _buildTopBar(context),
              const SizedBox(height: 40),
              // Titolo della pagina
              const Text(
                'SCAN INFO',
                style: TextStyle(
                  color: Color(0xFF111416),
                  fontSize: 28,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              // Layout 2x2 per i campi informativi
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prima colonna
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoField(
                          label: 'Name',
                          value: 'Scan 1',
                          icon: Icons.abc,
                        ),
                        const SizedBox(height: 24),
                        _buildInfoField(
                          label: 'Status',
                          value: 'Completed',
                          isMultiLine: true,
                          icon: Icons.checklist,
                        ),
                        const SizedBox(height: 24),
                        _buildInfoField(
                          label: 'Progrss',
                          value: '100%',
                          icon: Icons.bar_chart,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40), // Spazio tra le colonne
                  // Seconda colonna
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoField(
                          label: 'Step ID',
                          value: '1234567890',
                          icon: Icons.tag,
                        ),
                        const SizedBox(height: 24),
                        _buildInfoField(
                          label: 'Upload Date',
                          value: '10/01/2024',
                          icon: Icons.calendar_today,
                        ),
                        const SizedBox(height: 24),
                        _buildInfoField(
                          label: 'User',
                          value: 'Pippo Baudo',
                          isMultiLine: true,
                          icon: Icons.person,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60), // Spazio prima del pulsante
              // Pulsante "Delete" corretto
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [_buildDeleteButton(context)],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Costruisce la barra superiore con il pulsante "BACK"
  Widget _buildTopBar(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainPage(initialPageIndex: 0),
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
    );
  }

  // Helper per creare un campo informativo con lo stile dei box bianchi e icona
  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    bool isMultiLine = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Contenitore per l'icona
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF002C58),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            // Testo della label
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF111416),
                fontSize: 20,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE0E2)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111416),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
            maxLines: isMultiLine ? null : 1,
            overflow: isMultiLine ? null : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Costruisce il pulsante "Delete"
  Widget _buildDeleteButton(BuildContext context) {
    return InkWell(
      onTap: () {
        _showConfirmationDialog(context);
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFC70039),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'DELETE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // Mostra il dialogo di conferma per la cancellazione
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
            'This action will permanently delete the scan.',
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
