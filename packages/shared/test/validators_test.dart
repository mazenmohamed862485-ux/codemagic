// packages/shared/test/validators_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared/utils/validators.dart';

void main() {
  group('Email Validator', () {
    test('rejects empty email', () {
      expect(AppValidators.email(''), isNotNull);
    });

    test('rejects malformed email', () {
      expect(AppValidators.email('not-an-email'), isNotNull);
    });

    test('accepts valid email', () {
      expect(AppValidators.email('user@example.com'), isNull);
    });
  });

  group('Password Validator', () {
    test('rejects short password', () {
      expect(AppValidators.password('123'), isNotNull);
    });

    test('accepts 8+ character password', () {
      expect(AppValidators.password('password123'), isNull);
    });
  });

  group('Confirm Password Validator', () {
    test('rejects mismatched passwords', () {
      expect(AppValidators.confirmPassword('abc12345', 'xyz98765'), isNotNull);
    });

    test('accepts matching passwords', () {
      expect(AppValidators.confirmPassword('abc12345', 'abc12345'), isNull);
    });
  });

  group('Height Validator', () {
    test('rejects out-of-range height', () {
      expect(AppValidators.height('50'), isNotNull);
      expect(AppValidators.height('300'), isNotNull);
    });

    test('accepts valid height', () {
      expect(AppValidators.height('175'), isNull);
    });
  });

  group('Weight Validator', () {
    test('rejects out-of-range weight', () {
      expect(AppValidators.weight('10'), isNotNull);
      expect(AppValidators.weight('400'), isNotNull);
    });

    test('accepts valid weight', () {
      expect(AppValidators.weight('75'), isNull);
    });
  });

  group('OTP Validator', () {
    test('rejects non-6-digit codes', () {
      expect(AppValidators.otp('123'), isNotNull);
      expect(AppValidators.otp('1234567'), isNotNull);
      expect(AppValidators.otp('abcdef'), isNotNull);
    });

    test('accepts 6-digit code', () {
      expect(AppValidators.otp('123456'), isNull);
    });
  });
}
