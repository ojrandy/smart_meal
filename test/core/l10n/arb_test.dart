import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String language) =>
    jsonDecode(File('lib/core/l10n/app_$language.arb').readAsStringSync())
        as Map<String, dynamic>;

Iterable<String> _messages(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@'));

void main() {
  final en = _arb('en');
  final fr = _arb('fr');

  test('French has exactly the English keys', () {
    expect(_messages(fr).toSet(), _messages(en).toSet());
  });

  test('every English key is described for translators', () {
    for (final key in _messages(en)) {
      final meta = en['@$key'] as Map<String, dynamic>?;
      expect(meta?['description'], isA<String>(), reason: key);
    }
  });

  // Same text in both languages only where that is right: brand names,
  // dish names, units.
  const sameInBoth = {
    'appName',
    'cuisineCameroonianHint',
    'cuisineIndianHint',
    'cookTimeMinutes',
    'cookTimeOneHour',
    'cookTimeOneHourThirty',
    'cookTimeTwoHours',
  };

  test('nothing is left untranslated', () {
    final untranslated = [
      for (final key in _messages(en))
        if (!sameInBoth.contains(key) &&
            (fr[key] as String).replaceAll('\xA0', ' ') == en[key])
          key,
    ];
    expect(untranslated, isEmpty);
  });
}
