import 'package:flutter/material.dart';
import 'package:winop/screens/home_screen.dart';
import 'package:winop/screens/scan_device_screen.dart';
import 'package:winop/service/child_service.dart';
import '../theme/app_colors.dart';
import '../widgets/back_title_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/circle_logo.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _continue() async {
    try {
      final child = await ChildService.addChild(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        age: int.tryParse(ageController.text.trim()) ?? 0,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScanDeviceScreen(childId: child.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding child: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackTitleBar(
        title: 'Child Details',
        onTap: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppColors.screenPadding,
          child: Column(
            children: [
              const SizedBox(height: 10),
              const CircleLogo(path: 'assets/images/person.svg', size: 140),
              const SizedBox(height: 20),
              const Text(
                'Add Your Child Information',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryAlt,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'You can skip this step and add it later.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 30),
              AppCard(
                padding: const EdgeInsets.all(18),
                borderColor: AppColors.cardBorderAlt,
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
                  backgroundColor: AppColors.primaryAlt,
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
                    color: AppColors.primaryAlt,
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
