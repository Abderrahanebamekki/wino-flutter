import 'package:flutter/material.dart';
import 'package:winop/screens/personal_info_screen.dart';
import '../widgets/back_title_bar.dart';
import '../widgets/circle_logo.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final codeController = TextEditingController();
  int _secondsRemaining = 120; // 2 minutes

  String? codeError;
  late final Future<void> _timerFuture;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timerFuture = Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
        return true;
      }
      return false;
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void verifyCode() {
    setState(() {
      // Validate verification code
      if (codeController.text.isEmpty) {
        codeError = 'Please enter the verification code';
      } else if (codeController.text.length != 6) {
        codeError = 'Please enter a valid 6-digit code';
      } else if (!RegExp(r'^[0-9]+$').hasMatch(codeController.text)) {
        codeError = 'Please enter only numbers';
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PersonalInfoScreen()), // replace with your HomeScreen
        );
      }
    });

  }

  void _resendCode() {
    setState(() {
      _secondsRemaining = 120; // Reset to 2 minutes
      codeError = null;
      codeController.clear();
    });
    _startTimer(); // Restart timer
    print('Resend code tapped');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F6),
      appBar: BackTitleBar(
        title: 'Verify Email',
        onTap: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [

                const SizedBox(height: 24),

                // Circle logo with email.svg
                CircleLogo(
                  size: 160,
                  path: 'assets/images/email.svg',
                ),
                const SizedBox(height: 20),

                const Text(
                  "we've send a 6-digit of verification code to your email .please enter below.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),

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
                        label: 'Verification Code',
                        hint: 'Enter 6-digit code',
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        errorText: codeError,
                        maxLength: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Timer display
                Text(
                  'Code expires in: ${_formatTime(_secondsRemaining)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _secondsRemaining <= 30 ? Colors.red : Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: CustomButton(
                    text: 'Verify Code',
                    backgroundColor: const Color(0xFF05424E),
                    onPressed: verifyCode,
                    textColor: const Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 20),

                // Resend code option
                TextButton(
                  onPressed: _secondsRemaining > 0 ? null : _resendCode,
                  child: Text(
                    _secondsRemaining > 0
                        ? 'Resend code in ${_formatTime(_secondsRemaining)}'
                        : 'Didn\'t receive the code? Resend',
                    style: TextStyle(
                      color: _secondsRemaining > 0 ? Colors.grey : const Color(0xFF05424E),
                      fontSize: 14,
                      decoration: _secondsRemaining <= 0
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}