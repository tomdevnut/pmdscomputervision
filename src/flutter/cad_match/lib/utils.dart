import 'package:flutter/material.dart';
class AppColors {
  static const Color primary = Color(
    0xFF306BAC,
  ); 
  static const Color secondary = Color(
    0xFF6F9CEB,
  ); 

  static const Color backgroundColor = Color(
    0xFF000807,
  ); 
  static const Color cardBackground = Color(
    0xFF1F1F1F,
  );
  static const Color textFieldBackground = Color(
    0xFF2C2C2C,
  );

  static const Color textPrimary = Color(
    0xFFE0E0E0,
  ); 
  static const Color textSecondary = Color(
    0xFFB0B0B0,
  );
  static const Color textHint = Color(
    0xFF757575,
  ); 

  static const Color unselected = Color(
    0xFF424242,
  ); 

  static const Color error = Color(
    0xFFD94451,
  ); 
  static const Color success = Color(
    0xFF03A411,
  ); 
  static const Color warning = Color(0xFFFFDB3B); 
  static const Color boxborder = Color(
    0x1AE0E0E0);
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
Widget cardField(String label, String value, IconData? icon) {
  return Row (children: [
  Icon( icon ?? Icons.chevron_right, color: AppColors.secondary, size: 16),
  const SizedBox(width: 15),  
  Column(
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
  )]);
}

Widget buildButton(
  String title, {
  required VoidCallback onPressed,
  Color? color,
  IconData? icon,
}) {
  return SizedBox(
    width: 300,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.textPrimary),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
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
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
            child: Text(cancelText),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
                      backgroundColor: AppColors.success,
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
                      backgroundColor: AppColors.error,
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
