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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _stepsStream = FirebaseFirestore.instance.collection('steps').snapshots();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.textFieldBackground,
      hintStyle: const TextStyle(color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      errorStyle: const TextStyle(
        color: AppColors.error,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _onStartScanning() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedStepId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Please select a step.',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      setState(() => _isSaving = true);

      final payload = {
        'name': _nameCtrl.text.trim(),
        'stepId': _selectedStepId,
        'stepName': _selectedStepName,
      };

      if (!mounted) return;
      await Future.delayed(Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LidarScannerScreen(payload: payload),
        ),
      );

      if (mounted) setState(() => _isSaving = false);
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
        elevation: 0,
        title: const Text('New Scan'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.boxborder),
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
                    const Text(
                      'Name',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      cursorColor: AppColors.primary,
                      decoration: _inputDecoration('Enter scan name'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Step',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StreamBuilder<QuerySnapshot>(
                      stream: _stepsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(
                            'Error loading steps: ${snapshot.error}',
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text(
                            'No steps available. Please use the web app to add them.',
                            style: TextStyle(color: AppColors.textPrimary),
                            textAlign: TextAlign.center,
                          );
                        }

                        final steps = snapshot.data!.docs;

                        return DropdownButtonFormField<String>(
                          style: const TextStyle(color: AppColors.textPrimary),
                          dropdownColor: AppColors.cardBackground,
                          decoration: _inputDecoration('Select a step'),
                          icon: const Icon(
                            Icons.arrow_drop_down_rounded,
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
              buildButton(
                _isSaving ? 'STARTING...' : 'START SCANNING',
                onPressed: _isSaving ? () {} : _onStartScanning,
                icon: Icons.camera_alt_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
