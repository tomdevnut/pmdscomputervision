import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils.dart';

// Definizione della pagina come StatefulWidget per gestire lo stato del form
class AddScanPage extends StatefulWidget {
  const AddScanPage({super.key});

  @override
  State<AddScanPage> createState() => _AddScanPageState();
}

// Stato della pagina
class _AddScanPageState extends State<AddScanPage> {
  // Chiave globale per validare il form
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controller per il campo 'name'
  final TextEditingController _nameCtrl = TextEditingController();

  // Variabili per lo step
  String? _selectedStepId;
  String? _selectedStepName;
  Stream<QuerySnapshot>? _stepsStream;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Inizializza il listener per recuperare gli step da Firestore
    _stepsStream = FirebaseFirestore.instance.collection('steps').snapshots();
  }

  // Libera la memoria dei controller
  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // Helper per lo stile del campo di testo
  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.cardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x66FFFFFF)),
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
    );
  }

  // Funzione per mostrare un messaggio di stato
  Widget _buildMessage(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textPrimary),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Funzione per gestire il salvataggio dei dati e navigare
  Future<void> _onStartScanning() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _selectedStepId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a step and fill the name field.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'stepId': _selectedStepId,
        'stepName': _selectedStepName,
      };

      if (!mounted) return;

      // Navigare alla prossima pagina passando il payload
      //Navigator.of(context).push(
        //MaterialPageRoute(
        //  builder: (context) => NextPage(payload: payload),
        //),
      //);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        shadowColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0.5,
        title: const Text('New Scan'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.white),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Insert scan details',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo per il nome
                    Text(
                      'Name',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _decoration('Enter name'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Campo a discesa per lo step
                    Text(
                      'Step',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StreamBuilder<QuerySnapshot>(
                      stream: _stepsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return _buildMessage('Error loading steps');
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _buildMessage('No steps available');
                        }

                        final steps = snapshot.data!.docs;

                        return DropdownButtonFormField<String>(
                          initialValue: _selectedStepId,
                          style: const TextStyle(color: AppColors.textPrimary),
                          dropdownColor: AppColors.cardBackground,
                          decoration: _decoration('Select a step'),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.textPrimary,
                          ),
                          items: steps.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final stepName =
                                (data['name'] as String?)?.isNotEmpty == true
                                ? data['name'] as String
                                : 'No name';
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(
                                stepName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStepId = value;
                              _selectedStepName =
                                  steps
                                          .firstWhere((doc) => doc.id == value)
                                          .get('name')
                                      as String;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: _saving ? null : _onStartScanning,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined),
                            SizedBox(width: 8),
                            Text('Start Scanning'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
