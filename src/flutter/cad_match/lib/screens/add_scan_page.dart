import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'scanning_page.dart';
import '../utils.dart';

class AddScanPage extends StatefulWidget {
  const AddScanPage({super.key});

  @override
  State<AddScanPage> createState() => _AddScanPageState();
}

class _AddScanPageState extends State<AddScanPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();

  String? _selectedStepId;
  String? _selectedStepName;
  Stream<QuerySnapshot>? _stepsStream;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _stepsStream = FirebaseFirestore.instance
        .collection('steps')
        .orderBy('name')
        .snapshots();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {Widget? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textHint),
      prefixIcon: icon,
      filled: true,
      fillColor: AppColors.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  Future<void> _onStartScanning() async {
    // Il validator del form ora gestisce tutti i controlli
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isStarting = true);

    final payload = {
      'name': _nameCtrl.text.trim(),
      'stepId': _selectedStepId,
      'stepName': _selectedStepName,
    };

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LidarScannerScreen(payload: payload),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.buttonText,
        title: const Text(
          'New Scan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    children: [
                      const Text(
                        'Add Scan Details',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter a name and select the desired step to begin.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        cursorColor: AppColors.primary,
                        decoration: _inputDecoration(
                          'Scan Name',
                          icon: const Icon(
                            Icons.label_outline_rounded,
                            color: AppColors.textHint,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a name'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      StreamBuilder<QuerySnapshot>(
                        stream: _stepsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.textFieldBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'No steps available.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }

                          final steps = snapshot.data!.docs;
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedStepId,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                            dropdownColor: AppColors.cardBackground,
                            decoration: _inputDecoration(
                              'Select a Step',
                              icon: const Icon(
                                Icons.file_copy_outlined,
                                color: AppColors.textHint,
                              ),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textHint,
                            ),
                            items: steps.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final stepName =
                                  (data['name'] as String?)?.isNotEmpty == true
                                  ? data['name'] as String
                                  : 'No name';
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(stepName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              final selectedDoc = steps.firstWhere(
                                (doc) => doc.id == value,
                              );
                              final data =
                                  selectedDoc.data() as Map<String, dynamic>;
                              setState(() {
                                _selectedStepId = value;
                                _selectedStepName = data['name'] as String?;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Please select a step' : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: buildButton(
                    'START SCANNING',
                    isLoading: _isStarting,
                    onPressed: _onStartScanning,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
