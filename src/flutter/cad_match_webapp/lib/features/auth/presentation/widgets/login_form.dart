import 'package:flutter/material.dart';
import 'custom_text_field.dart';
import '../../../../core/constants/app_colors.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sign in to continue managing your steps.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          
          CustomTextField(
            controller: _emailController,
            hintText: 'Email',
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _passwordController,
            hintText: 'Password',
            obscureText: true,
          ),
          const SizedBox(height: 16),
          
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                // Handle forgot password
              },
              child: Text(
                'Forgot Password?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Handle login
              },
              child: const Text('Sign In'),
            ),
          ),
          const SizedBox(height: 32),
          
          TextButton(
            onPressed: () {
              // Handle sign up
            },
            child: Text(
              'Don\'t have an account? Sign Up',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textLink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
