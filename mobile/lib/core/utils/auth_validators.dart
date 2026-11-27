import '../constants/app_strings.dart';

/// Form validation helper functions for auth and general forms.
class AuthValidators {
  AuthValidators._();

  // Email regex RFC 5322 simplified but robust standard
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  /// Validates email format.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errEmailEmpty;
    }
    final trimmed = value.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return AppStrings.errEmailInvalid;
    }
    return null;
  }

  /// Validates password: at least 8 characters, containing both letters and numbers.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.errPasswordEmpty;
    }
    if (value.length < 8) {
      return AppStrings.errPasswordTooShort;
    }
    final hasLetter = value.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));
    if (!hasLetter || !hasDigit) {
      return AppStrings.errPasswordMissingChar;
    }
    return null;
  }

  /// Validates confirm password matches password.
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return AppStrings.errConfirmPasswordEmpty;
    }
    if (value != password) {
      return AppStrings.errConfirmPasswordMismatch;
    }
    return null;
  }

  /// Validates display name: 2 - 50 characters.
  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errDisplayNameEmpty;
    }
    final len = value.trim().length;
    if (len < 2 || len > 50) {
      return AppStrings.errDisplayNameLength;
    }
    return null;
  }
}
