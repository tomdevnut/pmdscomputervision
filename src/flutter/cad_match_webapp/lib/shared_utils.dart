import 'package:flutter/material.dart';

// Definizione dei colori
class AppColors {
  static const Color primary = Color(0xFF002C58);
  static const Color secondary = Color(0xFF0C7FF2);
  static const Color backgroundColor = Color(0xFFE1EDFF);
  static const Color white = Colors.white;
  static const Color textPrimary = Color(0xFF111416);
  static const Color textSecondary = Color(0xFF6B7582);
  static const Color borderGray = Color(0xFFDDE0E2);
  static const Color textHint = Color(0xFF6B7582);
  static const Color disabledButton = Color(0xFF6B7582);
  static const Color red = Color(0xFFD94451);
  static const Color green = Color(0xFF03A411);
}

// Funzione ausiliaria per la barra superiore con il pulsante "BACK"
Widget buildTopBar(BuildContext context, {required String title}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16.0),
    child: InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: ShapeDecoration(
              color: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 24),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

// Funzione ausiliaria per i campi di input
Widget buildInputField({
  required String label,
  required String hintText,
  required IconData icon,
  TextEditingController? controller,
  bool obscureText = false,
  String? Function(String?)? validator,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          // Container for the icon
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
          const SizedBox(width: 12),
          // Label text
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.textHint,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.all(15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.secondary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.red),
          ),
          fillColor: AppColors.white,
          filled: true,
        ),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      ),
    ],
  );
}

// Funzione ausiliaria per i campi di testo informativi (non modificabili)
Widget buildInfoField({
  required String label,
  required String value,
  required IconData icon,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          // Container for the icon
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
          const SizedBox(width: 12),
          // Label text
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    ],
  );
}

// Funzione ausiliaria per i pulsanti di salvataggio/azione
Widget buildButton({
  required String label,
  required VoidCallback onTap,
  Color backgroundColor = AppColors.secondary,
  bool isEnabled = true,
  IconData? icon,
}) {
  return InkWell(
    onTap: isEnabled ? onTap : null,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 17),
      decoration: BoxDecoration(
        color: isEnabled ? backgroundColor : AppColors.disabledButton,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.white, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

// Funzione ausiliaria per gli elementi delle liste
Widget buildListItem({
  required String title,
  String? subtitle,
  required IconData icon,
  required bool hasArrow,
  required Function() onTap,
  Color iconColor = AppColors.primary,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: ShapeDecoration(
                  color: iconColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Icon(icon, color: AppColors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (hasArrow)
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    ),
  );
}

Widget buildAddButton(BuildContext context, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: ShapeDecoration(
        color: AppColors.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 20),
    ),
  );
}

// Mostra il dialogo di conferma per la cancellazione
void showConfirmationDialog({
  required BuildContext context,
  required VoidCallback onConfirm,
  String? message,
  String title = 'Are you sure?',
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
        content: Text(
          message ?? '',
          style: const TextStyle(
            color: AppColors.textSecondary,
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
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
              overlayColor: AppColors.borderGray,
            ),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () {
              // Azione per il tasto "YES"
              Navigator.of(context).pop(); // Chiude il popup
              onConfirm();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.red,
              textStyle: const TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
              overlayColor: AppColors.borderGray,
            ),
            child: const Text('YES'),
          ),
        ],
      );
    },
  );
}

// Restituisce la stringa verbale corrispondente all'integer dello stato
String getStatusText(int status) {
  switch (status) {
    case 0:
      return 'Pending';
    case 1:
      return 'Sent to Server';
    case 2:
      return 'Completed';
    case -1:
      return 'Error';
    default:
      return 'Unknown';
  }
}

void showResultDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(title),
        titleTextStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
              overlayColor: AppColors.borderGray,
            ),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
