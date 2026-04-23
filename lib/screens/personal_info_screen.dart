import 'package:flutter/material.dart';
import 'package:winop/widgets/circle_logo.dart';
import 'package:winop/widgets/custom_button.dart';
import 'package:winop/widgets/custom_text_field.dart';

import '../widgets/back_title_bar.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => PersonalInfoScreenState();
}

class PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _goToChildInfoScreen() {
    print('Navigate to child info screen');
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (_) => const ChildInfoScreen()),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BackTitleBar(
        title: 'Personal Info',
        onTap: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              const CircleLogo(
                path: 'assets/images/person.svg',
                size: 160,
              ),

              const SizedBox(height: 28),

              const Text(
                'Complete Your Personal Information',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF012F39),
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Let’s get to know you before we continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 28),

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
                      hint: 'Enter your first name',
                      controller: firstNameController,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Last Name',
                      hint: 'Enter your last name',
                      controller: lastNameController,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              FractionallySizedBox(
                widthFactor: 0.85,
                child: CustomButton(
                  text: 'Continue to Child Details',
                  backgroundColor: const Color(0xFF012F39),
                  textColor: Colors.white,
                  onPressed: _goToChildInfoScreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}