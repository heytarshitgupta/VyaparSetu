import 'package:flutter/material.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/routes/app_router.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    setState(() => _isLoading = true);
    // Mock delay
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushNamed(context, AppRouter.homeRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the 4-digit code',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Code sent to your mobile number.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
              decoration: const InputDecoration(
                counterText: '',
                hintText: '0000',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Verify',
              isLoading: _isLoading,
              onPressed: _otpController.text.length == 4 ? _verifyOtp : null,
            ),
          ],
        ),
      ),
    );
  }
}
