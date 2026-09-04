import 'package:flutter/material.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_top_bar_controls.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Verify OTP'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: const [
          AppTopBarControls(showLabels: false),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter the 4-digit code',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Code sent to your mobile number.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 16,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '0000',
                      hintStyle: TextStyle(
                        fontSize: 32,
                        letterSpacing: 16,
                        color: Theme.of(context).dividerColor,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _otpController.text.length == 4 && !_isLoading ? _verifyOtp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Verify',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.check_circle_outline, size: 18),
                            ],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
