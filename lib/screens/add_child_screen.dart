import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/custom_text_field.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();

  String? _firstNameError;
  String? _lastNameError;
  String? _ageError;

  void _addChild() {
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _ageError = null;
    });

    bool hasError = false;

    if (_firstNameController.text.trim().isEmpty) {
      _firstNameError = 'First name is required';
      hasError = true;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _lastNameError = 'Last name is required';
      hasError = true;
    }
    if (_ageController.text.trim().isEmpty) {
      _ageError = 'Age is required';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Child Added Successfully')),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Child'),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Child Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your child details',
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
              const SizedBox(height: 30),
              AppCard(
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'First Name',
                      hint: 'Enter first name',
                      controller: _firstNameController,
                      errorText: _firstNameError,
                    ),
                    const SizedBox(height: 18),
                    CustomTextField(
                      label: 'Last Name',
                      hint: 'Enter last name',
                      controller: _lastNameController,
                      errorText: _lastNameError,
                    ),
                    const SizedBox(height: 18),
                    CustomTextField(
                      label: 'Age',
                      hint: 'Enter age',
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      errorText: _ageError,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _addChild,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusLarge),
                    ),
                  ),
                  child: const Text(
                    'Add Child',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
