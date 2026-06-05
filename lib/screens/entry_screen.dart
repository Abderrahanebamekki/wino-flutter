import 'package:flutter/material.dart';
import 'package:winop/widgets/custom_button.dart';
import '../theme/app_colors.dart';
import '../widgets/circle_logo.dart';
import '../screens/singup_screen.dart';
import '../screens/login_screen.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  void _goToNextScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleLogo(),
            const SizedBox(height: 20),
            const Text(
              'WINO',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 100),
            CustomButton(
              text: "Get Started",
              backgroundColor: Colors.white,
              onPressed: _goToNextScreen,
            ),
            const SizedBox(height: 10),
            CustomButton(
              text: "Login",
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
