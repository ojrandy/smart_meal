import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meal/core/formatting/fcfa.dart';

const _nbsp = '\xA0';

void main() {
  group('formatFcfa', () {
    for (final (amount, expected) in [
      (0, '0${_nbsp}FCFA'),
      (500, '500${_nbsp}FCFA'),
      (1000, '1${_nbsp}000${_nbsp}FCFA'),
      (2500, '2${_nbsp}500${_nbsp}FCFA'),
      (25000, '25${_nbsp}000${_nbsp}FCFA'),
      (10000000, '10${_nbsp}000${_nbsp}000${_nbsp}FCFA'),
    ]) {
      test('$amount', () => expect(formatFcfa(amount), expected));
    }

    test('uses a no-break space so the price never wraps', () {
      expect(formatFcfa(2500).contains(' '), isFalse);
    });
  });

  group('parseFcfa', () {
    test('reads grouped and plain digits', () {
      expect(parseFcfa('15${_nbsp}000'), 15000);
      expect(parseFcfa('15 000 FCFA'), 15000);
      expect(parseFcfa('750'), 750);
    });

    test('nothing to read is null', () {
      expect(parseFcfa(''), isNull);
      expect(parseFcfa('FCFA'), isNull);
    });
  });

  group('FcfaInputFormatter', () {
    const formatter = FcfaInputFormatter();

    TextEditingValue type(String old, String next) =>
        formatter.formatEditUpdate(
          TextEditingValue(text: old),
          TextEditingValue(text: next),
        );

    test('groups as the user types', () {
      expect(type('1500', '15000').text, '15${_nbsp}000');
    });

    test('drops anything that is not a digit', () {
      expect(type('', '1a2-3,4').text, '1${_nbsp}234');
    });

    test('drops leading zeros', () {
      expect(type('', '0025').text, '25');
    });

    test('refuses more than 8 digits', () {
      expect(
        type('10${_nbsp}000${_nbsp}000', '100000000').text,
        '10${_nbsp}000${_nbsp}000',
      );
    });

    test('keeps the cursor at the end', () {
      final value = type('', '2500');
      expect(value.selection.baseOffset, value.text.length);
    });
  });
}
