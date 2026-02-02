import 'package:supabase_flutter/supabase_flutter.dart';

/// Phone number authentication via Supabase OTP
///
/// Prerequisites:
/// 1. Enable Phone auth in Supabase Dashboard: Authentication > Providers > Phone
/// 2. Configure Twilio (or similar) in Supabase for SMS delivery
/// 3. Add SUPABASE_URL and SUPABASE_ANON_KEY to your config
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

  /// Verify OTP and sign in
  static Future<AuthResponse> verifyOtp(String phone, String token) async {
    final normalized = normalizePhone(phone);
    return _client.auth.verifyOTP(
      type: OtpType.sms,
      phone: normalized,
      token: token,
    );
  }

  /// Get current session (null if not signed in)
  static Session? get currentSession => _client.auth.currentSession;

  /// Get current user (null if not signed in)
  static User? get currentUser => _client.auth.currentUser;

  /// Sign out
  static Future<void> signOut() => _client.auth.signOut();
}
