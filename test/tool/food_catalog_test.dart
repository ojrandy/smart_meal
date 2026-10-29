import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/food_catalog.dart';

void main() {
  group('parseWafct', () {
    test('empty is unknown, never 0', () {
      expect(parseWafct(''), isNull);
      expect(parseWafct(null), isNull);
    });

    test('trace is 0 and bracketed estimates are used as given', () {
      expect(parseWafct('tr'), 0);
      expect(parseWafct('[0.6]'), 0.6);
      expect(parseWafct('4.0999999999999996'), closeTo(4.1, 1e-9));
    });

    test('anything else is refused', () {
      expect(() => parseWafct('n.a.'), throwsFormatException);
    });
  });

  group('buildNutrients', () {
    final wafct = {
      '01_001': {
        'EDIBLE1': '0.8',
        'ENERC_KCAL': '100',
        'CHOAVLDF': '0',
        'FAT': '0',
        'NA': '',
      },
    };
    final fdc = {
      '9': {'1093': '12', '2000': '3'},
    };
    List<String> row(Map<String, String> food) =>
        buildNutrients([food], wafct, fdc)[1];
    Map<String, String> food({
      String wafct = '01_001',
      String fdc = '9',
      String edible = '',
    }) => {
      'slug': 'x',
      'wafct_code': wafct,
      'fdc_id': fdc,
      'edible_portion': edible,
    };
    int col(String name) =>
        buildNutrients([food()], wafct, fdc)[0].indexOf(name);

    test('WAFCT first, USDA fills the gaps, each recorded', () {
      final r = row(food());
      expect(r[col('kcal')], '100');
      expect(r[col('sodium_mg')], '12');
      expect(r.last, contains('WAFCT 2019 01_001: kcal'));
      expect(r.last, contains('SR Legacy 9: sugars_g sodium_mg'));
      expect(r.last, contains('capped at the carbohydrate or fat total'));
    });

    test('a part cannot exceed the whole: no carbs → no sugars', () {
      final r = row(food());
      expect(
        r[col('sugars_g')],
        '0',
        reason: 'carbs are 0, so the USDA 3 g is not used',
      );
      expect(r[col('sat_fat_g')], '0');
    });

    test('missing values stay empty', () {
      final r = row(food(fdc: ''));
      expect(r[col('sodium_mg')], '');
      expect(r[col('folate_ug')], '');
    });

    test('edible portion: override, else WAFCT, else 1', () {
      expect(row(food())[col('edible_portion')], '0.8');
      expect(row(food(edible: '0'))[col('edible_portion')], '0');
      expect(row(food(wafct: '', fdc: ''))[col('edible_portion')], '1');
    });

    test('a food with no data says so', () {
      expect(row(food(wafct: '', fdc: '')).last, 'No composition data found');
    });

    test('an unknown source code fails loudly', () {
      expect(() => row(food(wafct: '99_999')), throwsStateError);
    });
  });

  group('SQL', () {
    test('text and arrays are escaped', () {
      expect(sqlText("cube d'assaisonnement"), "'cube d''assaisonnement'");
      expect(sqlArray('', 'text'), "'{}'::text[]");
      expect(
        sqlArray('a; b', 'public.allergen'),
        "array['a', 'b']::public.allergen[]",
      );
    });

    test('the newest catalog migration matches the reference CSVs', () {
      // Prices and sources must match docs/reference line by line (LF01).
      final migrations =
          Directory('supabase/migrations')
              .listSync()
              .whereType<File>()
              .where((f) => f.readAsStringSync().contains(beginMarker))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      expect(migrations, isNotEmpty);
      final current = migrations.last.readAsStringSync();
      final expected = replaceGeneratedBlock(
        current,
        buildInsertSql(
          readCsv(pricesPath),
          readCsv(catalogPath),
          readCsv(nutrientsPath),
        ),
      );
      expect(
        current,
        expected,
        reason:
            'run: dart run tool/food_catalog.dart sql ${migrations.last.path}',
      );
    });

    test('the reference files cover the same foods', () {
      final prices = readCsv(pricesPath);
      expect(
        readCsv(catalogPath).map((c) => c['slug']),
        prices.map((p) => p['slug']),
      );
      expect(
        readCsv(nutrientsPath).map((n) => n['slug']),
        prices.map((p) => p['slug']),
      );
    });
  });
}
