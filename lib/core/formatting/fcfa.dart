import 'package:flutter/services.dart';

/// Money in the app is Central African CFA francs, shown the way people in
/// Cameroon read prices: whole francs, thousands grouped with a space,
/// "FCFA" after the number (owner, 2026-10-24). XAF has no minor unit, so
/// amounts are always integers.
///
/// The group separator is a no-break space (U+00A0) so "2 500 FCFA" never
/// wraps in the middle of a number.
const fcfaGroupSeparator = '\xA0';

/// `2500` → `2 500`.
String groupThousands(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer(amount < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(fcfaGroupSeparator);
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// `2500` → `2 500 FCFA`.
String formatFcfa(int amount) =>
    '${groupThousands(amount)}${fcfaGroupSeparator}FCFA';

/// The digits of [text] as an amount, ignoring spaces and other separators;
/// null when there are none.
int? parseFcfa(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

/// Keeps a money field to digits and shows them grouped as the user types
/// (`15000` → `15 000`). At most [maxDigits] digits.
class FcfaInputFormatter extends TextInputFormatter {
  const FcfaInputFormatter({this.maxDigits = 8});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) return oldValue;
    // No leading zeros: "0" alone stays so the user sees what they typed.
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final text = digits.isEmpty ? '' : groupThousands(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
