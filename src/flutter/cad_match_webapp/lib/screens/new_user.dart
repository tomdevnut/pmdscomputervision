import 'package:flutter/material.dart';
import 'main_page.dart';
import 'package:flutter/services.dart';
import 'dart:math';

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

  // Generates a random password
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

  // Builds the top bar with the "BACK" button
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16.0),
      child: InkWell(
        onTap: () {
          // Navigates back to the main page, specifically the users tab.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainPage(initialPageIndex: 3),
            ),
          );
        },
        child: Row(
          children: const [
            Icon(Icons.arrow_back_ios, color: Color(0xFF111416), size: 24),
            SizedBox(width: 8),
            Text(
              'BACK',
              style: TextStyle(
                color: Color(0xFF111416),
                fontSize: 20,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds a generic input field with an icon and label
  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String hintText,
    bool isMultiLine = false,
    TextEditingController? controller,
  }) {
    return Column(
      // Ensure the column content aligns to the start (left)
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Container for the icon
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF002C58),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            // Label text
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF111416),
                fontSize: 20,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          // Constraints are removed to allow the field to expand
          // within the new two-column layout.
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE0E2)),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: isMultiLine ? 5 : 1,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF6B7582),
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.all(15),
              border: InputBorder.none,
            ),
            style: const TextStyle(color: Color(0xFF111416), fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Builds the password field with the "Generate password" button
  Widget _buildPasswordInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          context,
          label: 'Password',
          icon: Icons.lock,
          hintText: 'Enter a password',
          controller: _passwordController,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            final newPassword = _generateRandomPassword();
            _passwordController.value = _passwordController.value.copyWith(
              text: newPassword,
              selection: TextSelection.collapsed(offset: newPassword.length),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Generate random password',
              style: TextStyle(
                color: Color(0xFF0C7FF2),
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Builds the level selector field
  Widget _buildLevelSelector() {
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
                color: const Color(0xFF002C58),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.onetwothree, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            // Label text
            Text(
              'Level',
              style: const TextStyle(
                color: Color(0xFF111416),
                fontSize: 20,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE0E2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedLevel,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 15),
                hintText: 'Select a level',
                hintStyle: TextStyle(
                  color: Color(0xFF6B7582),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              items: ['0', '1', '2'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF111416),
                      fontSize: 16,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLevel = newValue;
                });
              },
              style: const TextStyle(color: Color(0xFF111416), fontSize: 16),
              dropdownColor: Colors.white,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7582)),
            ),
          ),
        ),
      ],
    );
  }

  // Builds the "Save" button
  Widget _buildSaveButton() {
    return InkWell(
      onTap: () {
        // TODO: Implementare la logica per salvare i dati inseriti.
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF002C58),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Save',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1EDFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            // Use a Column to stack the top bar, title, and form content
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTopBar(context),
              const Text(
                'CREATE A NEW USER',
                style: TextStyle(
                  color: Color(0xFF111416),
                  fontSize: 28,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              // Use a Center widget to center the entire Row
              Center(
                // Use a Row to create the two-column layout for the input fields
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First column for Email and Name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          context,
                          label: 'Email',
                          icon: Icons.email,
                          hintText: 'Enter the email',
                          controller: _emailController,
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(
                          context,
                          label: 'Name',
                          icon: Icons.person,
                          hintText: 'Enter the name',
                          controller: _nameController,
                        ),
                        const SizedBox(height: 24),
                        _buildLevelSelector(),
                      ],
                    ),
                    const SizedBox(width: 24), // Space between the columns
                    // Second column for Surname, Password, and Level
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          context,
                          label: 'Surname',
                          icon: Icons.person,
                          hintText: 'Enter the surname',
                          controller: _surnameController,
                        ),
                        const SizedBox(height: 24),
                        _buildPasswordInputField(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Center(child: _buildSaveButton()),
            ],
          ),
        ),
      ),
    );
  }
}
