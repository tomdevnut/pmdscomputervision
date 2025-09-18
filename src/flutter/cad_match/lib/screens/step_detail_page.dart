import 'package:flutter/material.dart';
import '../utils.dart';

// Widget stateless per la pagina dei dettagli dello step
class StepDetailPage extends StatelessWidget {
  final Map<String, dynamic> step;

  const StepDetailPage({super.key, required this.step});

  // helper per normalizzare un valore
  String _v(dynamic v) =>
      (v == null || (v is String && v.trim().isEmpty)) ? '—' : v.toString();

  // metodo build principale con scaffold, safearea e listview
  @override
  Widget build(BuildContext context) {
    // Usa le costanti dal file utils per una coerenza visiva
    const bg = AppColors.backgroundColor;
    const cardColor = AppColors.cardBackground;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        shadowColor: cardColor,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0,
        title: const Text('Step Details'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
            children: [
              // container con funzione di card dei dettagli con 4 campi
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.boxborder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _v(step['name']),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${_v(step['stepId'])}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.boxborder),
                    const SizedBox(height: 10),
                    cardField(
                      'Uploader',
                      _v(step['user']),
                      Icons.person_rounded,
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: AppColors.boxborder),
                    const SizedBox(height: 10),
                    cardField(
                      'Description',
                      _v(step['description']),
                      Icons.description_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
