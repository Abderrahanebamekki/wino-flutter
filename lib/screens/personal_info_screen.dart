import 'package:flutter/material.dart';
import 'package:winop/screens/child_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/back_title_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/circle_logo.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChildInfoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackTitleBar(
        title: 'Personal Info',
        onTap: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppColors.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const CircleLogo(path: 'assets/images/person.svg', size: 160),
              const SizedBox(height: 28),
              const Text(
                'Complete Your Personal Information',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryAlt,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Let\u2019s get to know you before we continue.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              AppCard(
                padding: const EdgeInsets.all(18),
                borderColor: AppColors.cardBorderAlt,
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
                  backgroundColor: AppColors.primaryAlt,
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
