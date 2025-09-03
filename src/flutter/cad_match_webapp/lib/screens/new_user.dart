import 'package:flutter/material.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared_utils.dart';

const String kNewUserUrl = 'https://new-user-5ja5umnfkq-ey.a.run.app';

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
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackbar({required String message, bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppColors.white)),
        backgroundColor: isError ? Colors.red : AppColors.green,
      ),
    );
  }

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

  Future<void> _createUser() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final password = _passwordController.text;
    final level = _selectedLevel;

    if (email.isEmpty ||
        name.isEmpty ||
        surname.isEmpty ||
        password.isEmpty ||
        level == null) {
      _showSnackbar(
        message: 'Please fill all fields and select a level.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      if (idToken == null) {
        throw Exception('User not authenticated.');
      }

      final data = {
        'email': email,
        'password': password,
        'level': int.parse(level),
        'name': name,
        'surname': surname,
      };

      final response = await http.post(
        Uri.parse(kNewUserUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(data),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _showSnackbar(
          message: responseData['message'] ?? 'User created successfully!',
        );
        Navigator.of(context).pop();
      } else {
        final responseData = json.decode(response.body);
        final errorMessage =
            responseData['message'] ?? 'An unknown error occurred.';
        _showSnackbar(
          message: 'Failed to create user: $errorMessage',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackbar(message: 'Error creating user: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Funzione che gestisce l'onTap e lo rende compatibile con il tipo 'dynamic Function()'
  void _onButtonTap() {
    if (!_isLoading) {
      _createUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTopBar(context, title: 'CREATE A NEW USER'),
              const Text(
                'An email will be sent to the user with their login credentials.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(width: 24),
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
                              _buildPasswordInputField(),
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
                  buildButton(
                    label: _isLoading ? 'Creating...' : 'Create user',
                    icon: _isLoading
                        ? Icons.hourglass_full
                        : Icons.check_circle,
                    onTap: _onButtonTap, // Passiamo la nuova funzione sincrona
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.password,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Password',
                  style: TextStyle(
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
                  color: AppColors.secondary,
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

  Widget _buildLevelSelector() {
    final levels = ['0', '1', '2'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.onetwothree,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Level',
              style: TextStyle(
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
              dropdownColor: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}
