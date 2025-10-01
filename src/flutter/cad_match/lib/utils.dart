import 'package:flutter/material.dart';

class AppColors {
  // Colori primari e secondari (mantenuti come richiesto)
  static const Color primary = Color(0xFF306BAC);
  static const Color secondary = Color(0xFF6F9CEB);

  // Sfondi
  static const Color backgroundColor = Color(0xFFF5F5F5); // Grigio molto chiaro
  static const Color cardBackground = Color(0xFFFFFFFF); // Bianco
  static const Color textFieldBackground = Color(0xFFEEEEEE);

  // Testi
  static const Color textPrimary = Color(
    0xFF212121,
  ); // Grigio scuro (quasi nero)
  static const Color textSecondary = Color(0xFF616161); // Grigio medio-scuro
  static const Color textHint = Color(0xFF9E9E9E); // Grigio per i placeholder
  static const Color buttonText = Color(
    0xFFFFFFFF,
  ); // Bianco per il testo dei bottoni

  // Altri elementi UI
  static const Color unselected = Color(
    0xFFBDBDBD,
  ); // Grigio per elementi non selezionati
  static const Color boxborder = Color(
    0x1A000000,
  ); // Bordo nero con bassa opacità

  // Colori semantici
  static const Color error = Color(0xFFD94451);
  static const Color success = Color(0xFF03A411);
  static const Color warning = Color(0xFFFFDB3B);
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

Widget cardField(String label, String value, IconData? icon) {
  return Row(
    children: [
      Icon(icon ?? Icons.chevron_right, color: AppColors.secondary, size: 16),
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
      ),
    ],
  );
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
        foregroundColor: AppColors.buttonText,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.buttonText),
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

Future<void> showConfirmationDialog(
  BuildContext context,
  String message,
  Function onConfirm, {
  String title = 'Confirm Deletion',
  String confirmText = 'Delete',
  String cancelText = 'Cancel',
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
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
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Success!',
                        style: TextStyle(color: AppColors.buttonText),
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed: $e',
                        style: TextStyle(color: AppColors.buttonText),
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
