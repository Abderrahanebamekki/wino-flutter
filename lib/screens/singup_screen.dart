import 'package:flutter/material.dart';
import '../widgets/back_title_bar.dart';
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
        passwordError = null;
      }
    });

    if (passwordError == null) {
      print('Create account clicked');
    }
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
      backgroundColor: const Color(0xFFF7F6F6),
      appBar: BackTitleBar(
        title: 'Create Account',
        onTap: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    color: Color(0xFF05424E),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Protect what matters most with the serene',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),

                const Text(
                  'sentinel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
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
                    backgroundColor: const Color(0xFF05424E),
                    onPressed: createAccount,
                    textColor: const Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 14),

                SocialButton(
                  text: 'Continue with Google',
                  iconPath: 'assets/images/google.svg',
                  onPressed: () {
                    print('Google clicked');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}