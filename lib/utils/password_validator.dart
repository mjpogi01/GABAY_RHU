/// Password validation utilities
class PasswordValidator {
  /// Minimum password length
  static const int minLength = 8;

  /// Validate password strength
  /// Returns null if valid, error message if invalid
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    // Add more strength requirements as needed
    // if (!password.contains(RegExp(r'[A-Z]'))) {
    //   return 'Password must contain at least one uppercase letter';
    // }
    // if (!password.contains(RegExp(r'[0-9]'))) {
    //   return 'Password must contain at least one number';
    // }
    return null;
  }

  /// Check if passwords match
  static String? validatePasswordMatch(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
}
