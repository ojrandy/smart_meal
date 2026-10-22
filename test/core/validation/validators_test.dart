import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meal/core/validation/validators.dart';

void main() {
  group('validateEmail', () {
    for (final email in [
      'a+b@x.company',
      'first.last@sub.domain.cm',
      'cook@example.com',
      '  padded@example.com  ',
    ]) {
      test('accepts "$email"', () => expect(validateEmail(email), isNull));
    }

    final tooLong = '${'a' * 243}@example.com'; // 255 characters
    for (final (label, email) in [
      ('no domain dot', 'a@b'),
      ('a space', 'a b@c.com'),
      ('255 characters', tooLong),
      ('two @', 'a@b@c.com'),
      ('one-letter TLD', 'a@b.c'),
    ]) {
      test('rejects $label', () {
        expect(validateEmail(email), 'Please enter a valid email');
      });
    }

    for (final empty in [null, '', '   ']) {
      test(
        'asks for an email when given ${empty == null ? 'null' : '"$empty"'}',
        () {
          expect(validateEmail(empty), 'Please enter your email');
        },
      );
    }

    test('254 characters is the limit', () {
      expect(validateEmail('${'a' * 242}@example.com'), isNull);
    });
  });

  group('validateNewPassword', () {
    test('accepts every character class at 8 characters', () {
      expect(validateNewPassword('Abcdef1!'), isNull);
    });

    for (final (label, password, message) in [
      ('empty', '', 'Please enter a password'),
      ('7 characters', 'Abcde1!', 'Password must be at least 8 characters'),
      (
        'no uppercase',
        'abcdefg1!',
        'Use upper- and lowercase letters, a number and a symbol',
      ),
      (
        'no lowercase',
        'ABCDEFG1!',
        'Use upper- and lowercase letters, a number and a symbol',
      ),
      (
        'no digit',
        'Abcdefgh!',
        'Use upper- and lowercase letters, a number and a symbol',
      ),
      (
        'no symbol',
        'Abcdefgh1',
        'Use upper- and lowercase letters, a number and a symbol',
      ),
      ('73 bytes', 'Aa1!${'x' * 69}', 'Password is too long'),
      // 39 characters, but 'é' is two UTF-8 bytes: 74 bytes in all.
      ('over 72 bytes in UTF-8', 'Aa1!${'é' * 35}', 'Password is too long'),
    ]) {
      test('rejects $label', () {
        expect(validateNewPassword(password), message);
      });
    }

    test('72 bytes is the limit', () {
      expect(validateNewPassword('Aa1!${'x' * 68}'), isNull);
    });
  });

  group('validateLoginPassword', () {
    test('accepts any non-empty password, even under the sign-up policy', () {
      expect(validateLoginPassword('short'), isNull);
    });

    test('asks for a password when empty', () {
      expect(validateLoginPassword(''), 'Please enter your password');
      expect(validateLoginPassword(null), 'Please enter your password');
    });
  });

  group('validatePasswordConfirmation', () {
    test('accepts a match', () {
      expect(validatePasswordConfirmation('Abcdef1!', 'Abcdef1!'), isNull);
    });

    test('rejects a mismatch', () {
      expect(
        validatePasswordConfirmation('Abcdef1?', 'Abcdef1!'),
        'Passwords do not match',
      );
    });

    test('asks for confirmation when empty', () {
      expect(
        validatePasswordConfirmation('', 'Abcdef1!'),
        'Please confirm your password',
      );
    });
  });
}
