import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/app_routes.dart';
import '../../core/design_system.dart';
import '../../core/supabase_config.dart';
import '../../providers/app_provider.dart';
import '../../models/user_model.dart';
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

  // Phone OTP flow (for sign in)
  final _otpController = TextEditingController();
  // Sign-up: after Create Account we show Complete Your Profile, then OTP screen
  bool _showProfileStep = false;
  bool _signUpOtpSent = false;
  bool _isLoading = false;
  String? _authError;

  // Complete Your Profile (before OTP)
  final _profileCommunityController = TextEditingController();
  final _profileIdNumberController = TextEditingController();
  String? _profileRole; // Profession/Role dropdown
  int? _profileNumberOfChildren; // Number of children dropdown

  // OTP one-box-per-digit (6 boxes) – initialized in initState for web/hot-reload safety
  List<TextEditingController>? _otpDigitControllers;
  List<FocusNode>? _otpFocusNodes;

  // Resend OTP countdown (seconds remaining; 0 = can resend). Nullable for web/hot-reload.
  int? _resendOtpCountdown = 0;
  Timer? _resendOtpTimer;

  int get _resendCountdown => _resendOtpCountdown ?? 0;

  bool _obscureLoginPassword = true;
  bool _obscureSignUpPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
    _otpDigitControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());
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
    _profileCommunityController.dispose();
    _profileIdNumberController.dispose();
    final controllers = _otpDigitControllers;
    if (controllers != null) {
      for (var i = 0; i < controllers.length; i++) {
        controllers[i].dispose();
      }
    }
    final nodes = _otpFocusNodes;
    if (nodes != null) {
      for (var i = 0; i < nodes.length; i++) {
        nodes[i].dispose();
      }
    }
    _resendOtpTimer?.cancel();
    super.dispose();
  }

  void _startResendOtpCountdown() {
    _resendOtpTimer?.cancel();
    _resendOtpCountdown = 60;
    _resendOtpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _resendOtpTimer?.cancel();
        return;
      }
      final current = _resendOtpCountdown ?? 0;
      if (current <= 0) {
        _resendOtpTimer?.cancel();
        return;
      }
      setState(() {
        _resendOtpCountdown = current - 1;
        if (_resendOtpCountdown! <= 0) {
          _resendOtpTimer?.cancel();
          _resendOtpCountdown = 0;
        }
      });
    });
  }

  Future<void> _resendSignUpOtp() async {
    if (_resendCountdown > 0) return;
    setState(() {
      _isLoading = true;
      _authError = null;
    });
    try {
      if (SupabaseConfig.isConfigured) {
        await PhoneAuthService.sendOtp(_signUpPhoneController.text.trim());
      }
      if (!mounted) return;
      _startResendOtpCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent again')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authError = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getOtpFromDigits() {
    final list = _otpDigitControllers;
    if (list == null || list.isEmpty) return '';
    final sb = StringBuffer();
    for (var i = 0; i < list.length; i++) {
      sb.write(list[i].text);
    }
    return sb.toString();
  }

  void _clearOtpDigits() {
    final list = _otpDigitControllers;
    if (list == null) return;
    for (var i = 0; i < list.length; i++) {
      list[i].clear();
    }
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
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: DesignSystem.maxContentWidth,
                    ),
                    child: Form(
                      key: _formKey,
                      child: _isSignUp ? _buildSignUpLayout(context) : _buildSignInLayout(context),
                    ),
                  ),
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
              _signUpOtpSent
                  ? 'Verify your phone'
                  : _showProfileStep
                      ? 'Complete Your Profile'
                      : 'Create Account',
              style: TextStyle(
                fontSize: DesignSystem.sectionTitleSize(context),
                fontWeight: FontWeight.w600,
                color: DesignSystem.textPrimary,
              ),
            ),
            SizedBox(height: DesignSystem.s(context, 4)),
            if (_signUpOtpSent) ...[
              Text(
                'Enter the 6-digit code sent to',
                style: TextStyle(
                  fontSize: DesignSystem.bodyTextSize(context),
                  fontWeight: FontWeight.w400,
                  color: DesignSystem.textPrimary,
                ),
              ),
              SizedBox(height: DesignSystem.s(context, 2)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _signUpPhoneController.text.trim(),
                    style: TextStyle(
                      fontSize: DesignSystem.bodyTextSize(context),
                      fontWeight: FontWeight.w600,
                      color: DesignSystem.textPrimary,
                    ),
                  ),
                  SizedBox(width: DesignSystem.s(context, 8)),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () => setState(() {
                              _signUpOtpSent = false;
                              _clearOtpDigits();
                              _otpController.clear();
                              _authError = null;
                              _resendOtpTimer?.cancel();
                              _resendOtpCountdown = 0;
                            }),
                    child: Text(
                      'Change number',
                      style: TextStyle(
                        color: DesignSystem.primary,
                        fontSize: DesignSystem.helperLinkSize(context),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_showProfileStep)
              Text(
                'Help us personalize your learning experience',
                style: TextStyle(
                  fontSize: DesignSystem.bodyTextSize(context),
                  fontWeight: FontWeight.w400,
                  color: DesignSystem.textSecondary,
                ),
              )
            else
              Text(
                'Register to start your learning journey',
                style: TextStyle(
                  fontSize: DesignSystem.bodyTextSize(context),
                  fontWeight: FontWeight.w400,
                  color: DesignSystem.textSecondary,
                ),
              ),
            SizedBox(height: DesignSystem.spacingLarge(context)),
            _signUpOtpSent
                ? _buildSignUpOtpForm(context)
                : _showProfileStep
                    ? _buildProfileForm(context)
                    : _buildSignUpForm(context),
          ],
        ),
      ),
    );
  }

  static const List<String> _profileRoleOptions = [
    'New Mother',
    'Expecting Mother',
    'Parent',
    'Grandparent',
    'Caregiver',
    'Daycare Provider',
    'Healthcare Worker',
    'Student',
    'Other',
  ];

  /// Only child-related user data we collect: number of children.
  /// (label, value). Use -1 for Not Applicable (saved as null).
  static const int _notApplicableChildren = -1;
  static const List<(String, int)> _profileNumberOfChildrenOptions = [
    ('Expecting First Child', 0),
    ('1 Child', 1),
    ('2 Children', 2),
    ('3 Children', 3),
    ('4 Children', 4),
    ('5 or More Children', 5),
    ('Not Applicable', _notApplicableChildren),
  ];

  Widget _buildProfileForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Profession / Role *
        Text(
          'Profession / Role *',
          style: TextStyle(
            fontSize: DesignSystem.bodyTextSize(context),
            fontWeight: FontWeight.w400,
            color: DesignSystem.textPrimary,
          ),
        ),
        SizedBox(height: DesignSystem.s(context, 6)),
        DropdownButtonFormField<String>(
          value: _profileRole,
          decoration: InputDecoration(
            hintText: 'Select your role',
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
          items: _profileRoleOptions
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _profileRole = v),
          validator: (v) => (v == null || v.isEmpty) ? 'Select your role' : null,
        ),
        SizedBox(height: DesignSystem.spacingMedium(context)),
        // Community / Location *
        _buildLabeledField(
          context,
          label: 'Community / Location *',
          controller: _profileCommunityController,
          hint: 'Enter your community or location',
          keyboardType: TextInputType.streetAddress,
          validator: (v) => (v == null || v.isEmpty) ? 'Enter your community or location' : null,
        ),
        SizedBox(height: DesignSystem.spacingMedium(context)),
        // Number of Children * (only child detail we collect)
        Text(
          'Number of Children *',
          style: TextStyle(
            fontSize: DesignSystem.bodyTextSize(context),
            fontWeight: FontWeight.w400,
            color: DesignSystem.textPrimary,
          ),
        ),
        SizedBox(height: DesignSystem.s(context, 6)),
        DropdownButtonFormField<int>(
          value: _profileNumberOfChildren,
          decoration: InputDecoration(
            hintText: 'Select number of children',
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
          items: _profileNumberOfChildrenOptions
              .map((e) => DropdownMenuItem<int>(
                    value: e.$2,
                    child: Text(e.$1),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _profileNumberOfChildren = v),
          validator: (v) => v == null ? 'Select number of children' : null,
        ),
        SizedBox(height: DesignSystem.spacingMedium(context)),
        // ID Number (Optional)
        _buildLabeledField(
          context,
          label: 'ID Number (Optional)',
          controller: _profileIdNumberController,
          hint: 'Enter your ID number',
          keyboardType: TextInputType.text,
          validator: (_) => null,
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
            onPressed: _isLoading ? null : _saveProfileAndSendOtp,
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
                : const Text('Save Profile and Continue'),
          ),
        ),
        SizedBox(height: DesignSystem.spacingMedium(context)),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: _isLoading
              ? null
              : () => setState(() {
                    _showProfileStep = false;
                    _authError = null;
                  }),
          child: Text(
            'Back',
            style: TextStyle(
              color: DesignSystem.primary,
              fontSize: DesignSystem.helperLinkSize(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpOtpForm(BuildContext context) {
    final controllers = _otpDigitControllers;
    final nodes = _otpFocusNodes;
    if (controllers == null ||
        nodes == null ||
        controllers.length != 6 ||
        nodes.length != 6) {
      return _buildSignUpOtpFormFallback(context);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              child: Focus(
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace &&
                      controllers[index].text.isEmpty &&
                      index > 0) {
                    FocusScope.of(context).requestFocus(nodes[index - 1]);
                    controllers[index - 1].clear();
                    setState(() {});
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextFormField(
                  controller: controllers[index],
                  focusNode: nodes[index],
                  decoration: InputDecoration(
                    counterText: '',
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
                      borderSide: const BorderSide(color: DesignSystem.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: TextStyle(
                    color: DesignSystem.textPrimary,
                    fontSize: DesignSystem.inputTextSize(context),
                    fontWeight: FontWeight.w600,
                  ),
                  enabled: !_isLoading,
                  onChanged: (value) {
                    setState(() {});
                    if (value.isNotEmpty && index < 5) {
                      FocusScope.of(context).requestFocus(nodes[index + 1]);
                    }
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            );
          }),
        ),
        SizedBox(height: DesignSystem.s(context, 4)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: (_resendCountdown > 0 || _isLoading)
                ? null
                : _resendSignUpOtp,
            child: Text(
              _resendCountdown > 0
                  ? 'Resend OTP ($_resendCountdown)'
                  : 'Resend OTP',
              style: TextStyle(
                color: _resendCountdown > 0
                    ? DesignSystem.textMuted
                    : DesignSystem.primary,
                fontSize: DesignSystem.helperLinkSize(context),
              ),
            ),
          ),
        ),
        if (_authError != null) ...[
          Text(
            _authError!,
            style: TextStyle(
              color: Colors.red,
              fontSize: DesignSystem.bodyTextSize(context),
            ),
          ),
          SizedBox(height: DesignSystem.spacingSmall(context)),
        ],
        SizedBox(height: DesignSystem.spacingMedium(context)),
        Row(
          children: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size(0, DesignSystem.buttonHeight),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _isLoading
                  ? null
                  : () => setState(() {
                        _signUpOtpSent = false;
                        _showProfileStep = true;
                        _clearOtpDigits();
                        _otpController.clear();
                        _authError = null;
                        _resendOtpTimer?.cancel();
                        _resendOtpCountdown = 0;
                      }),
              child: Text(
                'Back',
                style: TextStyle(
                  color: DesignSystem.primary,
                  fontSize: DesignSystem.buttonTextSize(context),
                ),
              ),
            ),
            SizedBox(width: DesignSystem.s(context, 12)),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifySignUpOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(100, DesignSystem.buttonHeight),
                  padding: DesignSystem.buttonPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text('Verify'),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Fallback when OTP digit controllers are not ready (e.g. after hot reload on web).
  Widget _buildSignUpOtpFormFallback(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _otpController,
          decoration: InputDecoration(
            hintText: '000000',
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
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: TextStyle(
            color: DesignSystem.textPrimary,
            fontSize: DesignSystem.inputTextSize(context),
          ),
          enabled: !_isLoading,
        ),
        SizedBox(height: DesignSystem.s(context, 4)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: (_resendCountdown > 0 || _isLoading)
                ? null
                : _resendSignUpOtp,
            child: Text(
              _resendCountdown > 0
                  ? 'Resend OTP ($_resendCountdown)'
                  : 'Resend OTP',
              style: TextStyle(
                color: _resendCountdown > 0
                    ? DesignSystem.textMuted
                    : DesignSystem.primary,
                fontSize: DesignSystem.helperLinkSize(context),
              ),
            ),
          ),
        ),
        if (_authError != null) ...[
          Text(
            _authError!,
            style: TextStyle(
              color: Colors.red,
              fontSize: DesignSystem.bodyTextSize(context),
            ),
          ),
          SizedBox(height: DesignSystem.spacingSmall(context)),
        ],
        SizedBox(height: DesignSystem.spacingMedium(context)),
        Row(
          children: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size(0, DesignSystem.buttonHeight),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _isLoading
                  ? null
                  : () => setState(() {
                        _signUpOtpSent = false;
                        _showProfileStep = true;
                        _clearOtpDigits();
                        _otpController.clear();
                        _authError = null;
                        _resendOtpTimer?.cancel();
                        _resendOtpCountdown = 0;
                      }),
              child: Text(
                'Back',
                style: TextStyle(
                  color: DesignSystem.primary,
                  fontSize: DesignSystem.buttonTextSize(context),
                ),
              ),
            ),
            SizedBox(width: DesignSystem.s(context, 12)),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifySignUpOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(100, DesignSystem.buttonHeight),
                  padding: DesignSystem.buttonPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text('Verify'),
                      ),
              ),
            ),
          ],
        ),
      ],
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
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword ? Icons.visibility_off : Icons.visibility,
                color: DesignSystem.textMuted,
              ),
              onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
            ),
          ),
          obscureText: _obscureLoginPassword,
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
              "Don't have account?",
              style: TextStyle(
                color: DesignSystem.textPrimary,
                fontSize: DesignSystem.bodyTextSize(context),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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
          obscureText: _obscureSignUpPassword,
          onToggleObscure: () => setState(() => _obscureSignUpPassword = !_obscureSignUpPassword),
          validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
        ),
        SizedBox(height: DesignSystem.spacingMedium(context)),
        _buildLabeledField(
          context,
          label: 'Confirm Password',
          controller: _confirmPasswordController,
          hint: 'Confirm your password',
          obscureText: _obscureConfirmPassword,
          onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Create Account'),
          ),
        ),
        SizedBox(height: DesignSystem.spacingMedium(context)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account?',
              style: TextStyle(
                color: DesignSystem.textPrimary,
                fontSize: DesignSystem.bodyTextSize(context),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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
    VoidCallback? onToggleObscure,
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
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: DesignSystem.textMuted,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
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

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _authError = null;
    });
    try {
      if (SupabaseConfig.isConfigured) {
        await PhoneAuthService.signInWithPhonePassword(
          _phoneController.text.trim(),
          _passwordController.text,
        );
        if (!context.mounted) return;
        final provider = context.read<AppProvider>();
        await provider.init();
        if (!context.mounted) return;
        if (provider.user == null && PhoneAuthService.currentUser != null) {
          final u = PhoneAuthService.currentUser!;
          final minimalUser = UserModel(
            id: u.id,
            anonymizedId: 'anon_${u.id}',
            role: 'parent',
            createdAt: DateTime.now(),
            phoneNumber: u.phone ?? _phoneController.text.trim(),
          );
          await provider.setUser(minimalUser);
          if (!context.mounted) return;
        }
        if (provider.user != null) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        } else {
          setState(() => _authError = 'Could not load session. Please try again.');
        }
      } else {
        await _demoLogin(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authError = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _showProfileStep = true;
      _authError = null;
    });
  }

  Future<void> _saveProfileAndSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _authError = null;
    });
    try {
      if (SupabaseConfig.isConfigured) {
        await PhoneAuthService.sendOtp(_signUpPhoneController.text.trim());
      }
      if (!mounted) return;
      setState(() {
        _showProfileStep = false;
        _signUpOtpSent = true;
        _clearOtpDigits();
      });
      _startResendOtpCountdown();
      if (SupabaseConfig.isConfigured && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to your phone')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authError = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifySignUpOtp() async {
    final controllers = _otpDigitControllers;
    final otp = (controllers != null && controllers.length == 6)
        ? _getOtpFromDigits()
        : _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _authError = 'Enter 6-digit code');
      return;
    }
    setState(() {
      _isLoading = true;
      _authError = null;
    });
    try {
      if (SupabaseConfig.isConfigured) {
        await PhoneAuthService.verifyOtp(
          _signUpPhoneController.text.trim(),
          otp,
        );
      }
      if (!mounted) return;
      await _performSignUp();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _authError = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performSignUp() async {
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
      status: _profileRole,
      address: _profileCommunityController.text.trim().isEmpty
          ? null
          : _profileCommunityController.text.trim(),
      numberOfChildren: _profileNumberOfChildren == _notApplicableChildren
          ? null
          : _profileNumberOfChildren,
      idNumber: _profileIdNumberController.text.trim().isEmpty
          ? null
          : _profileIdNumberController.text.trim(),
    );
    await provider.setUser(user);
    if (!context.mounted) return;
    // Set auth user email/password for future phone+password login, then store hash in public.users
    if (SupabaseConfig.isConfigured) {
      try {
        await PhoneAuthService.setAuthEmailPasswordForCurrentUser(
          _signUpPasswordController.text,
        );
        await PhoneAuthService.setUserPasswordByPhoneInDatabase(
          _signUpPhoneController.text.trim(),
          _signUpPasswordController.text,
        );
      } catch (_) {
        // Edge Function or RPC may be missing; login may still work if already set
      }
    }
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
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
    await provider.setUser(user);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }
}
