import 'package:supabase_flutter/supabase_flutter.dart';

/// Phone authentication: OTP for sign-up, phone + password for login via Edge Function.
///
/// Prerequisites:
/// 1. Enable Phone auth in Supabase Dashboard: Authentication > Providers > Phone
/// 2. Configure Twilio (or similar) for SMS
/// 3. Deploy Edge Function `login-phone-password` and set secret SUPABASE_JWT_SECRET
/// 4. RPCs: login_by_phone(p_phone, p_password), set_user_password_by_phone(p_phone, p_password)
class PhoneAuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Normalize phone to E.164 format (e.g. +639171234567 for Philippines)
  static String normalizePhone(String input, {String defaultCountryCode = '+63'}) {
    String cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = defaultCountryCode + cleaned.substring(1);
    } else if (!cleaned.startsWith('+')) {
      cleaned = defaultCountryCode + cleaned;
    }
    return cleaned;
  }

  /// Send OTP to phone number
  static Future<void> sendOtp(String phone) async {
    final normalized = normalizePhone(phone);
    await _client.auth.signInWithOtp(
      phone: normalized,
      channel: OtpChannel.sms,
    );
  }

  /// Sign in with phone and password via Edge Function (no synthetic email).
  /// Calls login-phone-password Edge Function, then sets session with returned refresh token.
  /// Phone is normalized to E.164 so it matches public.users.phone_number.
  static Future<AuthResponse> signInWithPhonePassword(String phone, String password) async {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) throw ArgumentError('Phone number is required');
    if (password.isEmpty) throw ArgumentError('Password is required');
    final normalized = normalizePhone(trimmed);

    final res = await _client.functions.invoke(
      'login-phone-password',
      body: {'phone': normalized, 'password': password},
    );

    if (res.status != 200) {
      final data = res.data is Map ? res.data as Map<String, dynamic>? : null;
      final msg = data?['error']?.toString() ?? 'Invalid phone or password';
      throw AuthException(msg, statusCode: res.status.toString());
    }

    final data = res.data is Map ? res.data as Map<String, dynamic>? : null;
    if (data == null) throw AuthException('Invalid response from login', statusCode: '500');

    final refreshToken = data['refresh_token'] as String?;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw AuthException('Invalid response from login', statusCode: '500');
    }

    return await _client.auth.setSession(refreshToken);
  }

  /// Set auth user's email to id@phone.gabay and password so phone+password login works.
  /// Call after OTP verify (while session is active). Requires Edge Function set-auth-email-password.
  static Future<void> setAuthEmailPasswordForCurrentUser(String password) async {
    if (password.isEmpty) return;
    final res = await _client.functions.invoke(
      'set-auth-email-password',
      body: {'password': password},
    );
    if (res.status != 200) {
      final data = res.data is Map ? res.data as Map<String, dynamic>? : null;
      final msg = data?['error']?.toString() ?? 'Failed to set login credentials';
      throw AuthException(msg, statusCode: res.status.toString());
    }
  }

  /// Store password hash in public.users via RPC (after registration / OTP).
  static Future<void> setUserPasswordByPhoneInDatabase(String phone, String password) async {
    final normalized = normalizePhone(phone.trim());
    await _client.rpc(
      'set_user_password_by_phone',
      params: {'p_phone': normalized, 'p_password': password},
    );
  }

  /// Verify OTP and sign in
  static Future<AuthResponse> verifyOtp(String phone, String token) async {
    final normalized = normalizePhone(phone);
    return _client.auth.verifyOTP(
      type: OtpType.sms,
      phone: normalized,
      token: token,
    );
  }

  static Session? get currentSession => _client.auth.currentSession;
  static User? get currentUser => _client.auth.currentUser;
  static Future<void> signOut() => _client.auth.signOut();
}
