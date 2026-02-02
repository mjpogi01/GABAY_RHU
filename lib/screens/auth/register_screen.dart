import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_routes.dart';
import '../../providers/app_provider.dart';
import '../../models/user_model.dart';
import '../../models/child_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  DateTime? _childDob;
  bool _isLoading = false;
  bool _otpSent = false;
  String? _verificationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Register as a parent or caregiver',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
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
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365)),
                    firstDate: DateTime.now().subtract(const Duration(days: 730)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _childDob = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Child\'s date of birth',
                    hintText: 'Tap to select',
                  ),
                  child: Text(
                    _childDob != null
                        ? '${_childDob!.year}-${_childDob!.month.toString().padLeft(2, '0')}-${_childDob!.day.toString().padLeft(2, '0')}'
                        : '',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_otpSent ? 'Verify OTP' : 'Send OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_childDob == null) return;

    setState(() => _isLoading = true);

    try {
      if (!_otpSent) {
        // Send OTP to phone number
        await Supabase.instance.client.auth.signInWithOtp(
          phone: _phoneController.text.trim(),
        );
        setState(() => _otpSent = true);
      } else {
        // Verify OTP and create account
        final response = await Supabase.instance.client.auth.verifyOTP(
          phone: _phoneController.text.trim(),
          token: _otpController.text.trim(),
          type: OtpType.sms,
        );

        if (response.user == null) {
          throw Exception('Failed to verify OTP');
        }

        final provider = context.read<AppProvider>();
        final user = UserModel(
          id: response.user!.id,
          anonymizedId: 'anon_${response.user!.id.substring(0, 8)}',
          role: 'parent',
          createdAt: DateTime.now(),
        );
        final child = ChildModel(
          id: 'child_${response.user!.id}',
          caregiverId: user.id,
          dateOfBirth: _childDob!,
        );

        await provider.setUserAndChild(user, child);

        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.preTest);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
