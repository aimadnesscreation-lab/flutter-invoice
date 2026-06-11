/// Shared form validation utility functions.
///
/// Usage: `validator: Validators.required('Name')`
class Validators {
  Validators._();

  /// Returns an error string if [value] is null or whitespace-only.
  static String? required(String fieldName, String? value) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Returns an error string if [value] is not a valid email.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null; // not required
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Returns an error string if [value] is not a valid phone number.
  /// Accepts digits, +, -, spaces, and parentheses.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // not required
    final phoneRegex = RegExp(r'^[\d\s\-+()]{7,20}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid phone number (7-20 digits)';
    }
    return null;
  }

  /// Returns an error string if [value] is not a valid positive number.
  static String? positiveNumber(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final num = double.tryParse(value.trim());
    if (num == null || num < 0) {
      return 'Enter a valid positive number';
    }
    return null;
  }

  /// Returns an error string if [value] is not a valid number (zero or positive).
  static String? number(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (double.tryParse(value.trim()) == null) {
      return 'Enter a valid number';
    }
    return null;
  }
}
