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
