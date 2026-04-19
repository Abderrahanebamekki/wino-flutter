import 'package:flutter/material.dart';
import 'package:winop/widgets/custombutton.dart';
import './../widgets/circlelogo.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {

  @override
  void initState() {
    super.initState();
    // _goToNextScreen();
  }

  void _goToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));

    // Navigate to next screen (example: Home)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Placeholder()), // replace with your HomeScreen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF05424E), // change if needed
      body:Center(
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
                  fontStyle: FontStyle.italic
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              "the serene essential for your",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            const Text(
              "family's daily journey",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 100),

            CustomButton(
              text: "Get Started",
              backgroundColor: Colors.white,
              onPressed: () {
                print("Clicked");
              },
            ),
            const SizedBox(height: 10),

            CustomButton(
              text: "Login",
              textColor: Colors.white,
              onPressed: () {
                print("Clicked");
              },
            ),
          ],
        ),
      )

    );
  }
}