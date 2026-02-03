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
  bool _showOtpField = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _isSupabaseConnected() ? 'Connected' : 'Disconnected',
              style: TextStyle(
                color: _isSupabaseConnected() ? Colors.green : Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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
                  hintText: '+639XXXXXXXXX',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(value)) {
                    return 'Please enter a valid phone number with country code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_showOtpField) ...[
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'OTP Code',
                    hintText: 'Enter 6-digit code',
                    prefixIcon: Icon(Icons.lock),
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
                const SizedBox(height: 16),
              ],
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
                    : Text(_showOtpField ? 'Verify & Register' : 'Send OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (!_showOtpField) {
        // Send OTP
        await Supabase.instance.client.auth.signInWithOtp(
          phone: _phoneController.text.trim(),
        );
        setState(() => _showOtpField = true);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to your phone')),
        );
      } else {
        // Verify OTP and register
        if (_childDob == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select child\'s date of birth')),
          );
          return;
        }

        final response = await Supabase.instance.client.auth.verifyOTP(
          phone: _phoneController.text.trim(),
          token: _otpController.text.trim(),
          type: OtpType.sms,
        );

        if (response.user != null) {
          // Create user and child records
          final provider = context.read<AppProvider>();
          final ts = DateTime.now().millisecondsSinceEpoch;
          final user = UserModel(
            id: response.user!.id,
            anonymizedId: 'anon_$ts',
            role: 'parent',
            createdAt: DateTime.now(),
          );
          final child = ChildModel(
            id: 'child_$ts',
            caregiverId: user.id,
            dateOfBirth: _childDob!,
          );
          await provider.setUserAndChild(user, child);
          if (!context.mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.preTest);
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isSupabaseConnected() {
    try {
      // Check if Supabase is initialized and has a valid session
      final supabase = Supabase.instance.client;
      return supabase.auth.currentSession != null;
    } catch (e) {
      return false;
    }
  }
}
