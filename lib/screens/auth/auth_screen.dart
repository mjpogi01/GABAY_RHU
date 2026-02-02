import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';
import '../../providers/app_provider.dart';
import '../../models/user_model.dart';
import '../../models/child_model.dart';

/// Auth screen with Sign In / Sign Up toggle
/// Design: GABAY branding, red primary, tagline
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  final _formKey = GlobalKey<FormState>();

  // Sign In fields
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Sign Up fields
  final _signUpPhoneController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _numberOfChildrenController = TextEditingController();
  int? _numberOfChildren;
  String? _status;
  bool? _hasInfant;
  int _signUpStep = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _signUpPhoneController.dispose();
    _signUpPasswordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _numberOfChildrenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD32F2F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appTagline,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildToggleButtons(),
                const SizedBox(height: 24),
                if (_isSignUp)
                  _buildSignUpForm()
                else
                  _buildSignInForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isSignUp = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isSignUp ? Colors.white : const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Sign In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isSignUp ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isSignUp = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isSignUp ? const Color(0xFFD32F2F) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isSignUp ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            hintText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (v) => (v == null || v.isEmpty) ? 'Enter phone number' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(
            hintText: 'Password',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // TODO: Forgot password
            },
            child: const Text('Forgot Password?', style: TextStyle(color: Colors.blue)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _signIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black),
              ),
            ),
            child: const Text('Log In'),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have account? "),
            TextButton(
              onPressed: () => setState(() => _isSignUp = true),
              child: const Text('Sign Up', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    if (_signUpStep == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _signUpPhoneController,
            decoration: const InputDecoration(
              hintText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.isEmpty) ? 'Enter phone number' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signUpPasswordController,
            decoration: const InputDecoration(
              hintText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(
              hintText: 'Confirm Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm password';
              if (v != _signUpPasswordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _nextButton('Next', () => setState(() => _signUpStep = 1)),
        ],
      );
    }
    if (_signUpStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _numberOfChildrenController,
            decoration: const InputDecoration(
              hintText: 'Number of Children',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) => _numberOfChildren = int.tryParse(v),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter number' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              hintText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: AppConstants.userStatusOptions
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _status = v),
            validator: (v) => v == null ? 'Select status' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<bool>(
            value: _hasInfant,
            decoration: const InputDecoration(
              hintText: 'Do you have an infant?',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: true, child: Text('Yes')),
              DropdownMenuItem(value: false, child: Text('No')),
            ],
            onChanged: (v) => setState(() => _hasInfant = v),
            validator: (v) => v == null ? 'Select yes or no' : null,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _signUpStep = 0),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _nextButton('Next', () => setState(() => _signUpStep = 2)),
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _firstNameController,
          decoration: const InputDecoration(
            hintText: 'First Name',
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Enter first name' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(
            hintText: 'Last Name',
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Enter last name' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _ageController,
          decoration: const InputDecoration(
            hintText: 'Age',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            hintText: 'Address',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _signUpStep = 1),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _nextButton('Sign Up', _signUp),
            ),
          ],
        ),
      ],
    );
  }

  Widget _nextButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    await _demoLogin(context);
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final user = UserModel(
      id: 'user_$ts',
      anonymizedId: 'anon_$ts',
      role: 'parent',
      createdAt: DateTime.now(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _signUpPhoneController.text.trim(),
      address: _addressController.text.trim(),
      status: _status,
      numberOfChildren: _numberOfChildren ?? int.tryParse(_numberOfChildrenController.text),
      hasInfant: _hasInfant,
    );
    final child = ChildModel(
      id: 'child_$ts',
      caregiverId: user.id,
      dateOfBirth: DateTime.now().subtract(const Duration(days: 365)),
    );
    await provider.setUserAndChild(user, child);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.preTest);
  }

  Future<void> _demoLogin(BuildContext context) async {
    final provider = context.read<AppProvider>();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final user = UserModel(
      id: 'demo_$ts',
      anonymizedId: 'anon_$ts',
      role: 'parent',
      createdAt: DateTime.now(),
      firstName: 'Maritess',
      lastName: 'Cruz',
      status: 'Expecting Mother',
      numberOfChildren: 1,
      address: 'Sto Niño, Batangas City',
    );
    final child = ChildModel(
      id: 'child_$ts',
      caregiverId: user.id,
      dateOfBirth: DateTime.now().subtract(const Duration(days: 180)),
    );
    await provider.setUserAndChild(user, child);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.preTest);
  }
}
