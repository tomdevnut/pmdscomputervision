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
  static const Color buttonTextSemiTransparent = Color(
    0x99FFFFFF,
  ); // Bianco semi-trasparente
  static const Color shadows = Colors.black12;

  // Colori semantici
  static const Color error = Color(0xFFD94451);
  static const Color success = Color(0xFF03A411);
  static const Color warning = Color(0xFFFFDB3B);
}

Widget buildButton(
  String title, {
  required VoidCallback? onPressed,
  Color? color,
  bool isLoading = false,
}) {
  return SizedBox(
    height: 55,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.primary,
        foregroundColor: AppColors.buttonText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Bordo più arrotondato
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    ),
  );
}

/// Costruisce un TextButton con lo stile per i link (es. "Forgot Password").
Widget buildTextButton(String title, {required VoidCallback onPressed}) {
  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: AppColors.secondary,
      padding: const EdgeInsets.symmetric(vertical: 8),
    ),
    child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
  bool pop = true,
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
                    SnackBar(
                      content: Text(
                        'Success!',
                        style: TextStyle(color: AppColors.buttonText),
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  Navigator.of(dialogContext).pop();
                  if (pop) Navigator.of(context).pop();
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
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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

/// Costruisce una card rettangolare per un elemento nella lista delle scansioni.
Widget buildScanListItem({
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  IconData? statusIcon,
  Color? statusIconColor,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadows,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icona a sinistra
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusIcon ?? Icons.qr_code_scanner_rounded,
                  color: statusIconColor ?? AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              // Titolo e sottotitolo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Icona a destra
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.unselected,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
