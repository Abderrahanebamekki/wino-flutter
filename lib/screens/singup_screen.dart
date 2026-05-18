import 'package:flutter/material.dart';
import 'package:winop/screens/verify_email_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/back_title_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/circle_logo.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/social_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? passwordError;

  void createAccount() {
    setState(() {
      if (passwordController.text.length < 8) {
        passwordError = 'Password must be at least 8 characters';
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackTitleBar(
        title: 'Create Account',
        onTap: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppColors.screenPadding,
            child: Column(
              children: [
                const SizedBox(height: 24),
                const CircleLogo(size: 140),
                const SizedBox(height: 20),
                const Text(
                  'JOIN WINO',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Protect what matters most with the serene',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'sentinel',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Email',
                        hint: 'Enter your email',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 100,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: passwordController,
                        isPassword: true,
                        errorText: passwordError,
                        maxLength: 100,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: CustomButton(
                    text: 'Create Account',
                    backgroundColor: AppColors.primaryDark,
                    onPressed: createAccount,
                    textColor: const Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 14),
                SocialButton(
                  text: 'Continue with Google',
                  iconPath: 'assets/images/google.svg',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
