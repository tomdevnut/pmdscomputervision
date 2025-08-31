import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF7C00);
  static const Color backgroundColor = black;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color textPrimary = white;
  static const Color textSecondary = Color(0xFF6B7582);
  static const Color textHint = Color(0x89FFFFFF);
  static const Color red = Color(0xFFD94451);
  static const Color green = Color(0xFF03A411);
  static const Color textFieldBackground = Color(0xFF212121);
  static const Color unselected = Color(0xB3FFFFFF);
  static const Color tileBackground = Color(0xFF424242);
  static const Color yellow = Color(0xFFFFDB3B);
  static const Color cardBackground = Color(0xFF1E1E1E);
}

Widget buildHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
    child: Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// funzione per costruire un campo di dettaglio in modo coerente
Widget cardField(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

Widget buildButton(
  String title, {
  required VoidCallback onPressed,
  Color? color,
}) {
  return SizedBox(
    width: 300,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

// funzione per mappare lo stato in una stringa leggibile
String getStatusString(int status) {
  switch (status) {
    case 2:
      return 'Completed';
    case 1:
      return 'Sent to server';
    case 0:
      return 'Received';
    default:
      return 'Error';
  }
}

// Dialogo di conferma per l'eliminazione
Future<void> showConfirmationDialog(
  BuildContext context,
  String message,
  Function onConfirm,
  {
    String title = 'Confirm Deletion',
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
  }
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // L'utente deve premere un bottone
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(
          title,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(message, style: TextStyle(color: AppColors.textHint)),
        backgroundColor: AppColors.tileBackground,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
            child: Text(cancelText),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: Text(confirmText),
            onPressed: () async {
              try {
                await onConfirm();
                // Mostra un messaggio di successo e chiudi i pop-up/pagine
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Successfully deleted!',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      backgroundColor: AppColors.green,
                    ),
                  );
                  Navigator.of(dialogContext).pop(); // Chiude il dialogo
                  Navigator.of(context).pop(); // Chiude la pagina
                }
              } catch (e) {
                // Mostra un messaggio di errore
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to delete: $e',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      backgroundColor: AppColors.red,
                    ),
                  );
                  Navigator.of(dialogContext).pop();
                }
              }
            },
          ),
        ],
      );
    },
  );
}
