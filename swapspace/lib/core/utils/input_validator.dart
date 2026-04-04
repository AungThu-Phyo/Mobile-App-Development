class InputValidator {
  static String? validateRequiredText(
    String? value, {
    required String fieldName,
    int minLength = 1,
    int maxLength = 100,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return '$fieldName is required';
    if (text.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    if (text.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    if (_looksMalicious(text)) {
      return '$fieldName contains invalid characters';
    }
    return null;
  }

  static String? validateOptionalText(
    String? value, {
    required String fieldName,
    int maxLength = 300,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (text.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    if (_looksMalicious(text)) {
      return '$fieldName contains invalid characters';
    }
    return null;
  }

  static bool _looksMalicious(String input) {
    final lowered = input.toLowerCase();
    return lowered.contains('<script') ||
        lowered.contains('javascript:') ||
        lowered.contains('onerror=') ||
        lowered.contains('onload=');
  }
}
