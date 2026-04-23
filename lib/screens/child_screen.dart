import 'package:flutter/material.dart';
import 'package:winop/widgets/back_title_bar.dart';
import 'package:winop/widgets/circle_logo.dart';
import 'package:winop/widgets/custom_button.dart';
import 'package:winop/widgets/custom_text_field.dart';

class ChildInfoScreen extends StatefulWidget {
  const ChildInfoScreen({super.key});

  @override
  State<ChildInfoScreen> createState() => _ChildInfoScreenState();
}

class _ChildInfoScreenState extends State<ChildInfoScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final ageController = TextEditingController();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  void _goToHome() {
    print('Go to Home');
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (_) => const HomeScreen()),
    // );
  }

  void _continue() {
    print('Child info submitted');
    _goToHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: BackTitleBar(
        title: 'Child Details',
        onTap: () => Navigator.pop(context),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              const CircleLogo(
                path: 'assets/images/person.svg',
                size: 140,
              ),

              const SizedBox(height: 20),

              const Text(
                'Add Your Child Information',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF012F39),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'You can skip this step and add it later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEAEAEA)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'First Name',
                      hint: 'Enter child first name',
                      controller: firstNameController,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Last Name',
                      hint: 'Enter child last name',
                      controller: lastNameController,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Age',
                      hint: 'Enter age',
                      controller: ageController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              FractionallySizedBox(
                widthFactor: 0.85,
                child: CustomButton(
                  text: 'Continue',
                  backgroundColor: const Color(0xFF012F39),
                  textColor: Colors.white,
                  onPressed: _continue,
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _goToHome,
                child: const Text(
                  'Skip for now',
                  style: TextStyle(
                    color: Color(0xFF012F39),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}