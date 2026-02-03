import 'package:supabase_flutter/supabase_flutter.dart';

/// Phone + Password Authentication Service
/// 
/// Uses phone-as-email workaround: {E164_PHONE}@gmail.com
/// Sign-up: Phone + Password + OTP → Create user with fake email
/// Login: Phone + Password → Sign in with fake email
class PhoneAuthService {
  static SupabaseClient get _client => Supabase.instance.client;
  
  // Domain for fake email addresses (never expose in UI)
  // Using gmail.com to avoid email validation issues
  static const String _fakeEmailDomain = '@gmail.com';

  /// Normalize phone to E.164 format (e.g. +639171234567 for Philippines)
  static String normalizePhone(String input, {String defaultCountryCode = '+63'}) {
    print('🔍 [PhoneAuthService] normalizePhone called');
    print('   📱 Input: "$input"');
    print('   📱 Input is empty: ${input.isEmpty}');
    print('   📱 Input length: ${input.length}');
    
    if (input.isEmpty) {
      print('   ⚠️ WARNING: Input phone is empty!');
      return '';
    }
    
    String cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    print('   📱 After cleaning: "$cleaned"');
    
    if (cleaned.startsWith('0')) {
      cleaned = defaultCountryCode + cleaned.substring(1);
      print('   📱 After 0-prefix handling: "$cleaned"');
    } else if (!cleaned.startsWith('+')) {
      cleaned = defaultCountryCode + cleaned;
      print('   📱 After adding country code: "$cleaned"');
    }
    
    print('   ✅ Final normalized: "$cleaned"');
    return cleaned;
  }

  /// Convert phone number to fake email format
  /// Format: {E164_PHONE}@gmail.com
  /// Replaces + with 'p' to avoid email validation issues
  static String _phoneToFakeEmail(String phone) {
    print('🔍 [PhoneAuthService] _phoneToFakeEmail called');
    print('   📱 Input phone: $phone');
    print('   📱 Phone is empty: ${phone.isEmpty}');
    
    final normalized = normalizePhone(phone);
    print('   📱 Normalized phone: $normalized');
    print('   📱 Normalized is empty: ${normalized.isEmpty}');
    
    // Replace + with 'p' (for "plus") to avoid email validation issues
    // +639915397802 becomes p639915397802@gmail.com
    final emailSafePhone = normalized.replaceAll('+', 'p');
    print('   📱 Email-safe phone (after + replacement): $emailSafePhone');
    
    final fakeEmail = '$emailSafePhone$_fakeEmailDomain';
    print('   📧 Generated fake email: $fakeEmail');
    print('   📧 Fake email is empty: ${fakeEmail.isEmpty}');
    print('   📧 Fake email length: ${fakeEmail.length}');
    
    if (fakeEmail.isEmpty || fakeEmail == _fakeEmailDomain) {
      print('   ⚠️ WARNING: Fake email is invalid!');
      throw ArgumentError('Invalid phone number: cannot convert to email');
    }
    
    return fakeEmail;
  }

  // ========== SIGN-UP FLOW ==========

  /// Step 1: Send SMS OTP for sign-up
  /// This verifies the phone number before creating the account
  static Future<void> sendSignUpOtp(String phone) async {
    final normalized = normalizePhone(phone);
    await _client.auth.signInWithOtp(
      phone: normalized,
      channel: OtpChannel.sms,
    );
  }

  /// Step 2: Verify OTP and create user account
  /// After OTP verification, creates user with phone-as-email + password
  static Future<AuthResponse> signUpWithPhonePassword({
    required String phone,
    required String password,
    required String otp,
  }) async {
    final normalized = normalizePhone(phone);
    // Note: _phoneToFakeEmail will normalize again, but that's okay for consistency
    final fakeEmail = _phoneToFakeEmail(phone);

    // Debug logging
    print('🔍 [PhoneAuthService] signUpWithPhonePassword called');
    print('   📱 Input phone: $phone');
    print('   📱 Normalized phone: $normalized');
    print('   📧 Fake email: $fakeEmail');
    print('   🔑 Password length: ${password.length}');
    print('   🔢 OTP length: ${otp.length}');

    // Step 1: Verify OTP (this creates a user and establishes a session)
    print('   ⏳ Step 1: Verifying OTP...');
    final otpResponse = await _client.auth.verifyOTP(
      type: OtpType.sms,
      phone: normalized,
      token: otp,
    );

    print('   ✅ OTP verified');
    print('   👤 User ID: ${otpResponse.user?.id}');
    print('   📧 User email before update: ${otpResponse.user?.email}');
    print('   📱 User phone: ${otpResponse.user?.phone}');
    print('   🔐 Session exists: ${otpResponse.session != null}');

    if (otpResponse.user == null || otpResponse.session == null) {
      print('   ❌ OTP verification failed - user or session is null');
      throw AuthException('OTP verification failed');
    }

    try {
      // Step 2: Sign up with email+password to create proper credentials
      // We'll use the same user ID by signing up first, then the OTP user will be merged
      print('   ⏳ Step 2: Signing up with email+password...');
      print('   📧 Email: $fakeEmail');
      print('   📧 Email is empty: ${fakeEmail.isEmpty}');
      print('   📧 Email length: ${fakeEmail.length}');
      
      if (fakeEmail.isEmpty) {
        print('   ❌ ERROR: Fake email is empty! Cannot proceed.');
        throw AuthException('Email conversion failed: empty email');
      }

      // Store the current session before signing out
      final currentSession = otpResponse.session;
      final currentUserId = otpResponse.user!.id;
      
      print('   📝 Current user ID from OTP: $currentUserId');
      print('   🔐 Current session token: ${currentSession?.accessToken?.substring(0, 20)}...');

      // Sign out from OTP session
      print('   ⏳ Step 3: Signing out from OTP session...');
      await _client.auth.signOut();

      // Step 3: Sign up with email+password
      // This should create a new user or link to existing phone user
      print('   ⏳ Step 4: Signing up with email+password...');
      print('   📧 Signing up with email: $fakeEmail');
      
      try {
        final signUpResponse = await _client.auth.signUp(
          email: fakeEmail,
          password: password,
          data: {
            'phone': normalized, // Store real phone in metadata
          },
        );

        print('   ✅ Sign-up successful');
        print('   👤 Sign-up user ID: ${signUpResponse.user?.id}');
        print('   📧 Sign-up user email: ${signUpResponse.user?.email}');
        print('   📱 Sign-up user phone: ${signUpResponse.user?.phone}');
        print('   🔐 Sign-up session exists: ${signUpResponse.session != null}');

        if (signUpResponse.user == null) {
          print('   ❌ Sign-up failed - user is null');
          throw AuthException('Failed to create account');
        }

        // If we got a session, return it
        if (signUpResponse.session != null) {
          print('   ✅ Account created with session');
          return signUpResponse;
        }

        // If no session (email confirmation required), sign in
        print('   ⏳ Step 5: Signing in with email+password...');
        final signInResponse = await _client.auth.signInWithPassword(
          email: fakeEmail,
          password: password,
        );

        print('   ✅ Sign-in successful');
        print('   👤 Final user ID: ${signInResponse.user?.id}');
        print('   📧 Final user email: ${signInResponse.user?.email}');
        print('   🔐 Final session exists: ${signInResponse.session != null}');

        return signInResponse;
      } catch (signUpError) {
        print('   ⚠️ Sign-up failed, trying sign-in instead...');
        print('   📧 Error: $signUpError');
        
        // If sign-up fails (user might already exist), try sign-in
        if (signUpError.toString().contains('already registered') || 
            signUpError.toString().contains('already exists')) {
          print('   ⏳ User exists, signing in...');
          final signInResponse = await _client.auth.signInWithPassword(
            email: fakeEmail,
            password: password,
          );
          print('   ✅ Sign-in successful');
          return signInResponse;
        }
        rethrow;
      }
    } catch (e) {
      print('   ❌ Error during account setup: $e');
      print('   📧 Email that failed: $fakeEmail');
      print('   📧 Email empty check: ${fakeEmail.isEmpty}');
      // If update fails, clean up by signing out
      await _client.auth.signOut();
      rethrow;
    }
  }

  // ========== LOGIN FLOW ==========

  /// Sign in with phone + password
  /// Converts phone to fake email and authenticates
  static Future<AuthResponse> signInWithPhonePassword({
    required String phone,
    required String password,
  }) async {
    print('🔍 [PhoneAuthService] signInWithPhonePassword called');
    print('   📱 Input phone: $phone');
    
    final normalized = normalizePhone(phone);
    print('   📱 Normalized phone: $normalized');
    
    final fakeEmail = _phoneToFakeEmail(normalized);
    print('   📧 Fake email for login: $fakeEmail');

    return await _client.auth.signInWithPassword(
      email: fakeEmail,
      password: password,
    );
  }

  // ========== UTILITIES ==========
  
  static Session? get currentSession => _client.auth.currentSession;
  static User? get currentUser => _client.auth.currentUser;
  static Future<void> signOut() => _client.auth.signOut();
  
  /// Check if user is authenticated
  static bool get isAuthenticated => _client.auth.currentSession != null;

  /// Get the real phone number from user metadata
  static String? getPhoneFromUser(User? user) {
    if (user == null) return null;
    return user.phone ?? user.userMetadata?['phone'] as String?;
  }
}
