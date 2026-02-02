// GABAY App - Core Constants
// Philippine Data Privacy Act (RA 10173) compliant

class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'GABAY';
  static const String appTagline = 'Alalay mo sa ligtas at tamang pag-aaruga.';
  static const String appTaglineEn = 'Your guide to safe and proper care.';

  // User status options (Sign Up)
  static const List<String> userStatusOptions = [
    'New Mother',
    'Expecting Mother',
    'Caregiver/Guardian',
  ];

  // User roles
  static const String roleParent = 'parent';
  static const String roleBHW = 'bhw';
  static const String roleAdmin = 'admin';

  // Post-test timing (2 months ± 1 week in days)
  static const int postTestMinDays = 54; // ~7.7 weeks
  static const int postTestMaxDays = 68; // ~9.7 weeks

  // Knowledge domains (for adaptive logic)
  static const List<String> knowledgeDomains = [
    'newborn_care',
    'nutrition',
    'responsive_caregiving',
    'safety',
    'development',
    'caregiver_wellbeing',
  ];

  // Benchmark for certificate (e.g., 80% post-test score)
  static const double certificateBenchmark = 0.8;

  // Sync
  static const int syncRetryAttempts = 3;
}
