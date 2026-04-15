import 'package:flutter_test/flutter_test.dart';
import 'package:swapspace/core/utils/input_validator.dart';

void main() {
  test('validateRequiredText enforces empty and length rules', () async {
    expect(
      InputValidator.validateRequiredText('', fieldName: 'Title'),
      'Title is required',
    );
    expect(
      InputValidator.validateRequiredText(
        'ab',
        fieldName: 'Title',
        minLength: 3,
      ),
      'Title must be at least 3 characters',
    );
    expect(
      InputValidator.validateRequiredText(
        'a' * 6,
        fieldName: 'Title',
        maxLength: 5,
      ),
      'Title must be at most 5 characters',
    );
  });

  test('validateRequiredText blocks malicious input', () async {
    expect(
      InputValidator.validateRequiredText(
        '<script>alert(1)</script>',
        fieldName: 'Title',
      ),
      'Title contains invalid characters',
    );
  });

  test('validateOptionalText allows empty and limits length', () async {
    expect(
      InputValidator.validateOptionalText('', fieldName: 'Bio'),
      isNull,
    );
    expect(
      InputValidator.validateOptionalText(
        'a' * 6,
        fieldName: 'Bio',
        maxLength: 5,
      ),
      'Bio must be at most 5 characters',
    );
  });
}
