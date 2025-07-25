import 'package:flutter/material.dart';
import '../widgets/login_form.dart';
import '../../../../core/constants/app_colors.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Text(
                'CADmatch',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 40),
            
            // Welcome section
            Text(
              'Welcome Back',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 60),
            
            // Login form
            const LoginForm(),
            
            const SizedBox(height: 100),
            
            // Footer
            Container(
              width: double.infinity,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
