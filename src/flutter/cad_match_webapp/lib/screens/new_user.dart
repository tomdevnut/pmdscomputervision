import 'package:flutter/material.dart';
import 'dart:math';
import '../shared_utils.dart'; // Importa il file di utility condiviso

class NewUser extends StatefulWidget {
  const NewUser({super.key});

  @override
  State<NewUser> createState() => _NewUserState();
}

class _NewUserState extends State<NewUser> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedLevel;
  bool _obscurePassword =
      true; // Nuova variabile per gestire la visibilità della password

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Genera una password casuale
  String _generateRandomPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_-+=';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        12,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTopBar(context, title: 'CREATE A NEW USER'),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Prima colonna per Email, Name, e Level
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildInputField(
                                label: 'Name',
                                hintText: 'Enter the name',
                                controller: _nameController,
                                icon: Icons.person,
                              ),
                              const SizedBox(height: 24),
                              buildInputField(
                                label: 'Email',
                                hintText: 'Enter the email',
                                controller: _emailController,
                                icon: Icons.email,
                              ),
                              const SizedBox(height: 24),
                              _buildLevelSelector(), 
                            ],
                          ),
                        ),
                        const SizedBox(width: 24), // Spazio tra le colonne
                        // Seconda colonna per Surname e Password
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildInputField(
                                label: 'Surname',
                                hintText: 'Enter the surname',
                                controller: _surnameController,
                                icon: Icons.person,
                              ),
                              const SizedBox(height: 24),
                              _buildPasswordInputField(), // Mantenuta come funzione specifica
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildInputField(
                          label: 'Name',
                          hintText: 'Enter the name',
                          controller: _nameController,
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 24),
                        buildInputField(
                          label: 'Email',
                          hintText: 'Enter the email',
                          controller: _emailController,
                          icon: Icons.email,
                        ),
                        const SizedBox(height: 24),
                        buildInputField(
                          label: 'Surname',
                          hintText: 'Enter the surname',
                          controller: _surnameController,
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 24),
                        _buildPasswordInputField(),
                        const SizedBox(height: 24),
                        _buildLevelSelector(),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Utilizzo della funzione buildSaveButton da shared_utils.dart
                  buildButton(
                    label: 'Save',
                    onTap: () {
                      // TODO: Implementa la logica di salvataggio
                  },
                ),],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Costruisce il campo di input per la password con il pulsante "Generate" e l'icona di visibilità
  Widget _buildPasswordInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  child: Icon(Icons.password, color: AppColors.white, size: 20),
                ),
                const SizedBox(width: 12),
                // Label text
                Text(
                  'Password',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _passwordController.text = _generateRandomPassword();
                });
              },
              child: const Text(
                'Generate password',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Enter the password',
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.all(15),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.textSecondary,
                ),
                padding: const EdgeInsets.only(right: 12),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Costruisce il selettore del livello
  Widget _buildLevelSelector() {
    final levels = ['0', '1', '2'];
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
              child: Icon(Icons.onetwothree, color: AppColors.white, size: 20),
            ),
            const SizedBox(width: 12),
            // Label text
            Text(
              'Level',
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
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedLevel,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select a level',
                  style: TextStyle(color: AppColors.textHint),
                ),
              ),
              items: levels.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      value,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLevel = newValue;
                });
              },
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ),
              dropdownColor: AppColors.white, // Sfondo del menu a tendina
            ),
          ),
        ),
      ],
    );
  }
}
