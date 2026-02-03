import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_routes.dart';
import '../../core/design_system.dart';
import '../../core/supabase_config.dart';
import '../../providers/app_provider.dart';
import '../../models/user_model.dart';
import '../../models/child_model.dart';
import '../../services/phone_auth_service.dart';

/// Auth screen with Sign In / Sign Up toggle
/// Design: GABAY branding, red primary, tagline
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialIsSignUp = false});

  final bool initialIsSignUp;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isSignUp;
  final _formKey = GlobalKey<FormState>();

  // Sign In fields
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Sign Up fields
  final _fullNameController = TextEditingController();
  final _signUpPhoneController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Legacy (kept for _signUp user creation)
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();

  // Phone OTP flow (for sign up when Supabase configured - legacy)
  bool _otpSent = false;
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _signUpPhoneController.dispose();
    _signUpPasswordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: DesignSystem.s(context, 24),
            vertical: DesignSystem.s(context, 24),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Form(
                  key: _formKey,
                  child: _isSignUp ? _buildSignUpLayout(context) : _buildSignInLayout(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInLayout(BuildContext context) {
    return Card(
      elevation: 2,
      color: DesignSystem.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(DesignSystem.s(context, 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: DesignSystem.sectionTitleSize(context),
                fontWeight: FontWeight.w600,
                color: DesignSystem.textPrimary,
              ),
            ),
            SizedBox(height: DesignSystem.s(context, 4)),
            Text(
              'Login to continue your learning.',
              style: TextStyle(
                fontSize: DesignSystem.bodyTextSize(context),
                fontWeight: FontWeight.w400,
                color: DesignSystem.textPrimary,
              ),
            ),
            SizedBox(height: DesignSystem.spacingLarge(context)),
            _buildSignInForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpLayout(BuildContext context) {
    return Card(
      elevation: 2,
      color: DesignSystem.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(DesignSystem.s(context, 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Account',
              style: TextStyle(
                fontSize: DesignSystem.sectionTitleSize(context),
                fontWeight: FontWeight.w600,
                color: DesignSystem.textPrimary,
              ),
            ),
            SizedBox(height: DesignSystem.s(context, 4)),
            Text(
              'Register to start your learning journey',
              style: TextStyle(
                fontSize: DesignSystem.bodyTextSize(context),
                fontWeight: FontWeight.w400,
                color: DesignSystem.textPrimary,
              ),
            ),
            SizedBox(height: DesignSystem.spacingLarge(context)),
            _buildSignUpForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: DesignSystem.inputBorder),
        borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isSignUp = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isSignUp ? DesignSystem.cardSurface : DesignSystem.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Sign In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: DesignSystem.buttonTextSize(context),
                    fontWeight: FontWeight.w600,
                    color: _isSignUp ? DesignSystem.textPrimary : Colors.white,
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
                  color: _isSignUp ? DesignSystem.primary : DesignSystem.cardSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: DesignSystem.buttonTextSize(context),
                    fontWeight: FontWeight.w600,
                    color: _isSignUp ? Colors.white : DesignSystem.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: DesignSystem.bodyTextSize(context),
            fontWeight: FontWeight.w400,
            color: DesignSystem.textPrimary,
          ),
        ),
        SizedBox(height: DesignSystem.s(context, 6)),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            hintText: 'Enter your phone number',
            hintStyle: TextStyle(color: DesignSystem.textMuted, fontSize: DesignSystem.inputTextSize(context)),
            filled: true,
            fillColor: DesignSystem.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
              borderSide: const BorderSide(color: DesignSystem.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
              borderSide: const BorderSide(color: DesignSystem.primary),
            ),
            contentPadding: DesignSystem.inputPadding,
          ),
          keyboardType: TextInputType.phone,
          style: TextStyle(color: DesignSystem.textPrimary, fontSize: DesignSystem.inputTextSize(context)),
          validator: (v) => (v == null || v.isEmpty) ? 'Enter phone number' : null,
          enabled: !_isLoading,
        ),
        SizedBox(height: DesignSystem.spacingMedium(context)),
        Text(
          'Password',
          style: TextStyle(
            fontSize: DesignSystem.bodyTextSize(context),
            fontWeight: FontWeight.w400,
            color: DesignSystem.textPrimary,
          ),
        ),
        SizedBox(height: DesignSystem.s(context, 6)),
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: TextStyle(color: DesignSystem.textMuted, fontSize: DesignSystem.inputTextSize(context)),
            filled: true,
            fillColor: DesignSystem.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
              borderSide: const BorderSide(color: DesignSystem.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
              borderSide: const BorderSide(color: DesignSystem.primary),
            ),
            contentPadding: DesignSystem.inputPadding,
          ),
          obscureText: true,
          style: TextStyle(color: DesignSystem.textPrimary, fontSize: DesignSystem.inputTextSize(context)),
          validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
          enabled: !_isLoading,
        ),
        SizedBox(height: DesignSystem.spacingSmall(context)),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                color: DesignSystem.primary,
                fontSize: DesignSystem.helperLinkSize(context),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        if (_authError != null) ...[
          SizedBox(height: DesignSystem.spacingSmall(context)),
          Text(
            _authError!,
            style: TextStyle(color: Colors.red, fontSize: DesignSystem.bodyTextSize(context)),
          ),
        ],
        SizedBox(height: DesignSystem.spacingSmall(context)),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(DesignSystem.buttonHeight),
              padding: DesignSystem.buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Login'),
          ),
        ),
        SizedBox(height: DesignSystem.spacingMedium(context)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have account? ",
              style: TextStyle(
                color: DesignSystem.textPrimary,
                fontSize: DesignSystem.bodyTextSize(context),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _isSignUp = true;
                _authError = null;
              }),
              child: Text(
                'Register',
                style: TextStyle(
                  color: DesignSystem.primary,
                  fontSize: DesignSystem.bodyTextSize(context),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpForm(BuildContext context, String phone, Future<void> Function() onVerify) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the 6-digit code sent to $phone',
          style: TextStyle(color: DesignSystem.textSecondary, fontSize: DesignSystem.bodyTextSize(context)),
        ),
        SizedBox(height: DesignSystem.spacingMedium(context)),
        TextFormField(
          controller: _otpController,
          decoration: InputDecoration(
            hintText: '000000',
            filled: true,
            fillColor: DesignSystem.inputBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
              borderSide: const BorderSide(color: DesignSystem.inputBorder),
            ),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          validator: (v) => (v == null || v.length != 6) ? 'Enter 6-digit code' : null,
          enabled: !_isLoading,
        ),
        if (_authError != null) ...[
          SizedBox(height: DesignSystem.spacingSmall(context)),
          Text(_authError!, style: TextStyle(color: Colors.red, fontSize: DesignSystem.bodyTextSize(context))),
        ],
        SizedBox(height: DesignSystem.spacingMedium(context)),
        Row(
          children: [
            TextButton(
              onPressed: _isLoading ? null : () => setState(() {
                _otpSent = false;
                _otpController.clear();
                _authError = null;
              }),
              child: Text('Change number', style: TextStyle(color: DesignSystem.primary, fontSize: DesignSystem.helperLinkSize(context))),
            ),
            const Spacer(),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => onVerify(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(DesignSystem.buttonHeight),
                  padding: DesignSystem.buttonPadding,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Verify'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _signInWithOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _authError = null;
    });
    try {
      await PhoneAuthService.verifyOtp(_phoneController.text, _otpController.text);
      if (!context.mounted) return;
      final provider = context.read<AppProvider>();
      await provider.init(); // Refresh from Supabase
      if (!context.mounted) return;
      if (provider.preTestResult == null) {
        Navigator.pushReplacementNamed(context, AppRoutes.preTest);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } catch (e) {
      if (!context.mounted) return;
      setState(() {
        _isLoading = false;
        _authError = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  Widget _buildSignUpForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabeledField(
          context,
          label: 'Full Name',
          controller: _fullNameController,
          hint: 'Enter your full name',
          keyboardType: TextInputType.name,
          validator: (v) => (v == null || v.isEmpty) ? 'Enter your full name' : null,
        ),
        SizedBox(height: DesignSystem.spacingMedium(context)),
        _buildLabeledField(
          context,
          label: 'Phone Number',
          controller: _signUpPhoneController,
          hint: 'Enter your phone number',
          keyboardType: TextInputType.phone,
          validator: (v) => (v == null || v.isEmpty) ? 'Enter phone number' : null,
        ),
        SizedBox(height: DesignSystem.spacingMedium(context)),
        _buildLabeledField(
          context,
          label: 'Password',
          controller: _signUpPasswordController,
          hint: 'Create a password',
          obscureText: true,
          validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
        ),
        SizedBox(height: DesignSystem.spacingMedium(context)),
        _buildLabeledField(
          context,
          label: 'Confirm Password',
          controller: _confirmPasswordController,
          hint: 'Confirm your password',
          obscureText: true,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Confirm password';
            if (v != _signUpPasswordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        if (_authError != null) ...[
          SizedBox(height: DesignSystem.spacingSmall(context)),
          Text(
            _authError!,
            style: TextStyle(color: Colors.red, fontSize: DesignSystem.bodyTextSize(context)),
          ),
        ],
        SizedBox(height: DesignSystem.spacingLarge(context)),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(DesignSystem.buttonHeight),
              padding: DesignSystem.buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
              ),
            ),
            child: const Text('Create Account'),
          ),
        ),
        SizedBox(height: DesignSystem.spacingMedium(context)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: TextStyle(
                color: DesignSystem.textPrimary,
                fontSize: DesignSystem.bodyTextSize(context),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _isSignUp = false;
                _authError = null;
              }),
              child: Text(
                'Login',
                style: TextStyle(
                  color: DesignSystem.primary,
                  fontSize: DesignSystem.bodyTextSize(context),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabeledField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: DesignSystem.bodyTextSize(context),
            fontWeight: FontWeight.w400,
            color: DesignSystem.textPrimary,
          ),
        ),
        SizedBox(height: DesignSystem.s(context, 6)),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: DesignSystem.textMuted, fontSize: DesignSystem.inputTextSize(context)),
            filled: true,
            fillColor: DesignSystem.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
              borderSide: const BorderSide(color: DesignSystem.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
              borderSide: const BorderSide(color: DesignSystem.primary),
            ),
            contentPadding: DesignSystem.inputPadding,
          ),
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(color: DesignSystem.textPrimary, fontSize: DesignSystem.inputTextSize(context)),
          validator: validator,
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _nextButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignSystem.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(DesignSystem.buttonHeight),
          padding: DesignSystem.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _authError = null;
    });
    try {
      if (SupabaseConfig.isConfigured) {
        await PhoneAuthService.signInWithPassword(
          _phoneController.text,
          _passwordController.text,
        );
        if (!context.mounted) return;
        final provider = context.read<AppProvider>();
        await provider.init();
        if (!context.mounted) return;
        if (provider.preTestResult == null) {
          Navigator.pushReplacementNamed(context, AppRoutes.preTest);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      } else {
        await _demoLogin(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _authError = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final ts = DateTime.now().millisecondsSinceEpoch;
    String userId;
    if (SupabaseConfig.isConfigured && PhoneAuthService.currentUser != null) {
      userId = PhoneAuthService.currentUser!.id;
    } else {
      userId = 'user_$ts';
    }
    final fullName = _fullNameController.text.trim();
    final parts = fullName.split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
    final user = UserModel(
      id: userId,
      anonymizedId: 'anon_$ts',
      role: 'parent',
      createdAt: DateTime.now(),
      firstName: firstName.isNotEmpty ? firstName : null,
      lastName: lastName?.isNotEmpty == true ? lastName : null,
      phoneNumber: _signUpPhoneController.text.trim(),
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

  Future<void> _testDatabaseConnection(BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;
      // Try to query the users table to test connection
      final response = await supabase.from('users').select('count').limit(1);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database connection successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Database connection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  bool _isSupabaseConnected() {
    try {
      // Check if Supabase is initialized
      final supabase = Supabase.instance.client;
      print('Supabase client initialized: ${supabase != null}');

      // Check if we have a current user
      final user = supabase.auth.currentUser;
      print('Current user: ${user?.email ?? 'null'}');

      // For now, just check if Supabase client exists and we can access auth
      return supabase != null;
    } catch (e) {
      print('Supabase connection error: $e');
      return false;
    }
  }
}
