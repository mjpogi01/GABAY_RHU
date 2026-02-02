import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_routes.dart';
import '../../providers/app_provider.dart';
import '../../models/user_model.dart';
import '../../models/child_model.dart';

/// Login screen with Supabase authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String? _verificationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to GABAY')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Care for your little one',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+63XXXXXXXXXX',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(value)) {
                    return 'Please enter a valid phone number (e.g., +639123456789)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_otpSent)
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'OTP Code',
                    hintText: 'Enter the 6-digit code',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the OTP code';
                    }
                    if (value.length != 6) {
                      return 'OTP must be 6 digits';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_otpSent ? 'Verify OTP' : 'Send OTP'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (!_otpSent) {
        // Send OTP to phone number
        await Supabase.instance.client.auth.signInWithOtp(
          phone: _phoneController.text.trim(),
        );
        setState(() => _otpSent = true);
      } else {
        // Verify OTP and login
        final response = await Supabase.instance.client.auth.verifyOTP(
          phone: _phoneController.text.trim(),
          token: _otpController.text.trim(),
          type: OtpType.sms,
        );

        if (response.user == null) {
          throw Exception('Failed to verify OTP');
        }

        // Get user and child data from database
        final provider = context.read<AppProvider>();
        final dataSource = await provider.dataSource;

        final user = await dataSource.getCurrentUser();
        final child = await dataSource.getCurrentChild();

        if (user == null || child == null) {
          throw Exception('User data not found. Please register first.');
        }

        await provider.setUserAndChild(user, child);

        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.preTest);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
