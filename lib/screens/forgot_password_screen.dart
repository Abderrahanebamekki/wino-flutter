import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/back_title_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();

  void sendResetLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset link sent if account exists')),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackTitleBar(
        title: 'Forgot Password',
        onTap: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppColors.screenPadding,
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.lock_outline, size: 80, color: AppColors.primaryDark),
                const SizedBox(height: 20),
                const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter your email and we\'ll send you',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'a link to reset your password',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: CustomTextField(
                    label: 'Email',
                    hint: 'Enter your email',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 100,
                  ),
                ),
                const SizedBox(height: 24),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: CustomButton(
                    text: 'Send Reset Link',
                    backgroundColor: AppColors.primaryDark,
                    onPressed: sendResetLink,
                    textColor: const Color(0xFFFFFFFF),
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
