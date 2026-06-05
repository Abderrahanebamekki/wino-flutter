import 'package:flutter/material.dart';
import 'package:winop/screens/forgot_password_screen.dart';
import 'package:winop/screens/home_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/back_title_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/circle_logo.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../service/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> login() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      backgroundColor: AppColors.background,
      appBar: BackTitleBar(
        title: 'Login',
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
                  'WELCOME BACK',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'WINO',
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
                        maxLength: 100,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: CustomButton(
                    text: 'Login',
                    backgroundColor: AppColors.primaryDark,
                    onPressed: _isLoading ? null : () => login(),
                    textColor: const Color(0xFFFFFFFF),
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
