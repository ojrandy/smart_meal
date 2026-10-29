// Builds the LF01 food catalog from the reference files in docs/reference/.
//
//   dart run tool/food_catalog.dart nutrients <wafct-dir> <fdc-dir>
//       Rewrites docs/reference/ingredient-nutrients-cm.csv from the two
//       nutrient sources, following the codes in ingredient-catalog-cm.csv.
//   dart run tool/food_catalog.dart sql <migration.sql>
//       Rewrites the generated block of that migration (between the
//       BEGIN/END GENERATED markers) from the three reference CSVs. For a
//       price refresh, create a new migration holding only the two markers
//       and run this on it; test/tool/food_catalog_test.dart checks that the
//       newest such migration matches the CSVs.
//
// Sources (download once, outside the repo; neither needs an API key):
//   WAFCT 2019 — FAO/INFOODS Food Composition Table for Western Africa:
//     https://www.fao.org/fileadmin/user_upload/faoweb/2020/WAFCT_2019.xlsx
//     Unzip it (an .xlsx is a zip, e.g. `tar -xf WAFCT_2019.xlsx -C wafct`)
//     and pass that folder.
//   USDA FoodData Central, SR Legacy CSV (public domain, CC0):
//     https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip
//     Unzip it and pass the folder that holds food_nutrient.csv.
//
// Rules (docs/reference/ingredient-prices-cm.md, "Nutrients"):
//   * WAFCT first, per nutrient; USDA fills the gaps (always for sugars,
//     which WAFCT does not report). Each value's source is recorded.
//   * A missing value stays empty (unknown), never 0. WAFCT's "tr" (trace)
//     is 0; bracketed values (estimates) are used as given.
//   * Sugars never exceed available carbohydrate, nor saturated fat total
//     fat (mixed sources can disagree); a whole of 0 gives parts of 0.
import 'dart:io';

const pricesPath = 'docs/reference/ingredient-prices-cm.csv';
const catalogPath = 'docs/reference/ingredient-catalog-cm.csv';
const nutrientsPath = 'docs/reference/ingredient-nutrients-cm.csv';

/// Date the price list was checked; used as `price_updated_at` for rows
/// with no observation (owner, 2026-10-29).
const listCheckedOn = '2026-10-29';

const beginMarker =
    '-- BEGIN GENERATED: food catalog (tool/food_catalog.dart sql)';
const endMarker = '-- END GENERATED: food catalog';

/// Catalog nutrient column → WAFCT component tag and USDA nutrient id.
const nutrients = <(String, String?, String)>[
  ('kcal', 'ENERC_KCAL', '1008'),
  ('carbs_g', 'CHOAVLDF', '1005'),
  ('sugars_g', null, '2000'),
  ('fibre_g', 'FIBTG', '1079'),
  ('protein_g', 'PROTCNT', '1003'),
  ('fat_g', 'FAT', '1004'),
  ('sat_fat_g', 'FASAT', '1258'),
  ('sodium_mg', 'NA', '1093'),
  ('potassium_mg', 'K', '1092'),
  ('phosphorus_mg', 'P', '1091'),
  ('iron_mg', 'FE', '1089'),
  ('folate_ug', 'FOL', '1177'),
];

Future<void> main(List<String> args) async {
  if (args.length == 3 && args[0] == 'nutrients') {
    final out = buildNutrients(
      readCsv(catalogPath),
      readWafct(args[1]),
      readFdc(args[2]),
    );
    File(nutrientsPath).writeAsStringSync(toCsv(out));
    stdout.writeln('Wrote ${out.length - 1} rows to $nutrientsPath');
  } else if (args.length == 2 && args[0] == 'sql') {
    final file = File(args[1]);
    final sql = buildInsertSql(
      readCsv(pricesPath),
      readCsv(catalogPath),
      readCsv(nutrientsPath),
    );
    file.writeAsStringSync(replaceGeneratedBlock(file.readAsStringSync(), sql));
    stdout.writeln('Updated the generated block of ${args[1]}');
  } else {
    stderr.writeln(
      'Usage: dart run tool/food_catalog.dart nutrients <wafct-dir> <fdc-dir>\n'
      '       dart run tool/food_catalog.dart sql <migration.sql>',
    );
    exitCode = 64;
  }
}

// ── CSV ─────────────────────────────────────────────────────────────────────

List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c == '"' && i + 1 < text.length && text[i + 1] == '"') {
        cell.write('"');
        i++;
      } else if (c == '"') {
        quoted = false;
      } else {
        cell.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      row.add(cell.toString());
      cell.clear();
    } else if (c == '\n') {
      row.add(cell.toString().replaceAll('\r', ''));
      cell.clear();
      rows.add(row);
      row = <String>[];
    } else {
      cell.write(c);
    }
  }
  if (cell.isNotEmpty || row.isNotEmpty) {
    row.add(cell.toString().replaceAll('\r', ''));
    rows.add(row);
  }
  return rows;
}

String toCsv(List<List<String>> rows) {
  String cell(String v) =>
      v.contains(RegExp('[,"\n]')) ? '"${v.replaceAll('"', '""')}"' : v;
  return '${rows.map((r) => r.map(cell).join(',')).join('\n')}\n';
}

/// Reads a CSV with a header row into maps keyed by column name.
List<Map<String, String>> readCsv(String path) =>
    recordsOf(parseCsv(File(path).readAsStringSync()));

List<Map<String, String>> recordsOf(List<List<String>> rows) {
  final header = rows.first;
  return [
    for (final r in rows.skip(1))
      if (r.any((c) => c.isNotEmpty))
        {
          for (var i = 0; i < header.length; i++)
            header[i]: i < r.length ? r[i] : '',
        },
  ];
}

// ── Nutrient sources ────────────────────────────────────────────────────────

/// WAFCT code → component tag → raw cell, from sheet "03 NV_sum_39".
Map<String, Map<String, String>> readWafct(String dir) {
  final rows = parseCsv(_xlsxSheetToCsv(dir, 'sheet3'));
  return wafctTable(rows);
}

Map<String, Map<String, String>> wafctTable(List<List<String>> rows) {
  // Row 3 holds the component tags; energy appears twice (kJ, then kcal).
  final tags = rows[2].map((t) => t.trim()).toList();
  final kcal = tags.lastIndexOf('ENERC');
  final table = <String, Map<String, String>>{};
  for (final r in rows.skip(3)) {
    if (r.isEmpty || !RegExp(r'^\d{2}_\d{3}$').hasMatch(r[0])) continue;
    final values = <String, String>{};
    for (var i = 0; i < tags.length && i < r.length; i++) {
      if (tags[i].isEmpty) continue;
      values[i == kcal ? 'ENERC_KCAL' : tags[i]] = r[i];
    }
    table[r[0]] = values;
  }
  return table;
}

/// USDA fdc_id → nutrient id → amount per 100 g.
Map<String, Map<String, String>> readFdc(String dir) {
  final wanted = {for (final n in nutrients) n.$3};
  final table = <String, Map<String, String>>{};
  final lines = File('$dir/food_nutrient.csv').readAsLinesSync();
  for (final line in lines.skip(1)) {
    final c = line.replaceAll('"', '').split(',');
    if (c.length < 4 || !wanted.contains(c[2])) continue;
    table.putIfAbsent(c[1], () => {})[c[2]] = c[3];
  }
  return table;
}

/// Parses a WAFCT cell: '' → null (unknown), 'tr' → 0, '[1.2]' → 1.2.
num? parseWafct(String? raw) {
  final v = (raw ?? '').trim();
  if (v.isEmpty) return null;
  if (v.toLowerCase() == 'tr') return 0;
  final n = num.tryParse(v.replaceAll(RegExp(r'[\[\]]'), ''));
  if (n == null) throw FormatException('Unreadable WAFCT value "$v"');
  return n;
}

/// Rounds to at most 3 decimals and drops a trailing zero part.
String formatNumber(num n) {
  final s = (n * 1000).round() / 1000;
  return s == s.roundToDouble() ? s.toInt().toString() : s.toString();
}

List<List<String>> buildNutrients(
  List<Map<String, String>> catalog,
  Map<String, Map<String, String>> wafct,
  Map<String, Map<String, String>> fdc,
) {
  final out = <List<String>>[
    [
      'slug',
      'edible_portion',
      for (final n in nutrients) n.$1,
      'nutrient_source',
    ],
  ];
  for (final food in catalog) {
    final slug = food['slug']!;
    final code = food['wafct_code']!;
    final fdcId = food['fdc_id']!;
    if (code.isNotEmpty && !wafct.containsKey(code)) {
      throw StateError('$slug: WAFCT code $code not found');
    }
    if (fdcId.isNotEmpty && !fdc.containsKey(fdcId)) {
      throw StateError('$slug: USDA fdc_id $fdcId not found');
    }
    final w = wafct[code] ?? const <String, String>{};
    final u = fdc[fdcId] ?? const <String, String>{};
    final values = <String, num?>{};
    final fromWafct = <String>[];
    final fromFdc = <String>[];
    for (final (column, tag, id) in nutrients) {
      final wv = tag == null ? null : parseWafct(w[tag]);
      final uv = num.tryParse(u[id] ?? '');
      values[column] = wv ?? uv;
      if (wv != null) {
        fromWafct.add(column);
      } else if (uv != null) {
        fromFdc.add(column);
      }
    }
    // Mixed sources can disagree (USDA sugars above WAFCT carbohydrate);
    // a part never exceeds its whole, and a whole of 0 has parts of 0.
    final derived = <String>[];
    void cap(String part, String whole) {
      final w = values[whole];
      final p = values[part];
      if (w != null && (p == null ? w == 0 : p > w)) {
        values[part] = w;
        derived.add(part);
      }
    }

    cap('sugars_g', 'carbs_g');
    cap('sat_fat_g', 'fat_g');
    final edible = food['edible_portion']!.isNotEmpty
        ? num.parse(food['edible_portion']!)
        : parseWafct(w['EDIBLE1']) ?? 1;
    final source = [
      if (fromWafct.isNotEmpty)
        'FAO/INFOODS WAFCT 2019 $code: ${fromWafct.join(' ')}',
      if (fromFdc.isNotEmpty)
        'USDA FoodData Central SR Legacy $fdcId: ${fromFdc.join(' ')}',
      if (derived.isNotEmpty)
        'capped at the carbohydrate or fat total: ${derived.join(' ')}',
      if (fromWafct.isEmpty && fromFdc.isEmpty) 'No composition data found',
    ].join('; ');
    out.add([
      slug,
      formatNumber(edible),
      for (final n in nutrients)
        values[n.$1] == null ? '' : formatNumber(values[n.$1]!),
      source,
    ]);
  }
  return out;
}

// ── SQL ─────────────────────────────────────────────────────────────────────

String sqlText(String v) => "'${v.replaceAll("'", "''")}'";
String sqlOrNull(String v) => v.isEmpty ? 'null' : v;
String sqlTextOrNull(String v) => v.isEmpty ? 'null' : sqlText(v);
String sqlArray(String semicolonList, String type) {
  final items = semicolonList
      .split(';')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty);
  return items.isEmpty
      ? "'{}'::$type[]"
      : 'array[${items.map(sqlText).join(', ')}]::$type[]';
}

const insertColumns = [
  'slug',
  'name_en',
  'name_fr',
  'aliases',
  'category',
  'pricing_unit',
  'price_xaf',
  'price_low_xaf',
  'price_high_xaf',
  'price_confidence',
  'price_updated_at',
  'price_source',
  'grams_per_piece',
  'density_g_per_ml',
  'edible_portion',
  'kcal',
  'carbs_g',
  'sugars_g',
  'fibre_g',
  'protein_g',
  'fat_g',
  'sat_fat_g',
  'sodium_mg',
  'potassium_mg',
  'phosphorus_mg',
  'iron_mg',
  'folate_ug',
  'nutrient_source',
  'wafct_code',
  'fdc_id',
  'allergens',
  'flags',
  'is_kitchen_staple',
  'is_active',
];

String buildInsertSql(
  List<Map<String, String>> prices,
  List<Map<String, String>> catalog,
  List<Map<String, String>> nutrientRows,
) {
  final bySlug = {for (final c in catalog) c['slug']!: c};
  final nutrientsBySlug = {for (final n in nutrientRows) n['slug']!: n};
  final slugs = prices.map((p) => p['slug']!).toList();
  for (final set in [bySlug.keys.toSet(), nutrientsBySlug.keys.toSet()]) {
    final missing = slugs.toSet().difference(set);
    final extra = set.difference(slugs.toSet());
    if (missing.isNotEmpty || extra.isNotEmpty) {
      throw StateError(
        'Reference files disagree: missing $missing, extra $extra',
      );
    }
  }
  final rows = <String>[];
  for (final p in prices) {
    final slug = p['slug']!;
    final c = bySlug[slug]!;
    final n = nutrientsBySlug[slug]!;
    final status = p['status']!;
    if (!{'ready', 'field_check', 'missing'}.contains(status)) {
      throw StateError('$slug: unknown status $status');
    }
    final updated = p['observed_to']!.isEmpty
        ? listCheckedOn
        : p['observed_to']!;
    final values = [
      sqlText(slug),
      sqlText(p['name_en']!),
      sqlText(p['name_fr']!),
      sqlArray(c['aliases']!, 'text'),
      sqlText(p['category']!),
      sqlText(p['pricing_unit']!),
      sqlOrNull(p['price_xaf']!),
      sqlOrNull(p['range_low_xaf']!),
      sqlOrNull(p['range_high_xaf']!),
      sqlTextOrNull(p['confidence']!),
      sqlText(updated),
      sqlText(p['source']!),
      sqlOrNull(c['grams_per_piece']!),
      sqlOrNull(c['density_g_per_ml']!),
      n['edible_portion']!,
      for (final col in nutrients) sqlOrNull(n[col.$1]!),
      sqlText(n['nutrient_source']!),
      sqlTextOrNull(c['wafct_code']!),
      sqlOrNull(c['fdc_id']!),
      sqlArray(c['allergens']!, 'public.allergen'),
      sqlArray(c['flags']!, 'public.ingredient_flag'),
      c['is_kitchen_staple'] == 'true' ? 'true' : 'false',
      status == 'ready' ? 'true' : 'false',
    ];
    rows.add('  (${values.join(', ')})');
  }
  // An upsert, so a monthly refresh is a new migration with a regenerated
  // block (docs/reference/ingredient-prices-cm.md, "Refresh").
  final updates = insertColumns
      .where((c) => c != 'slug')
      .map((c) => '  $c = excluded.$c')
      .join(',\n');
  return 'insert into public.ingredients (\n'
      '  ${insertColumns.join(', ')}\n'
      ') values\n'
      '${rows.join(',\n')}\n'
      'on conflict (slug) do update set\n'
      '$updates;\n';
}

String replaceGeneratedBlock(String migration, String sql) {
  final start = migration.indexOf(beginMarker);
  final end = migration.indexOf(endMarker);
  if (start < 0 || end < start) {
    throw StateError('Generated-block markers not found');
  }
  return '${migration.substring(0, start)}$beginMarker\n'
      '-- Do not edit by hand: change docs/reference/*.csv and re-run.\n'
      '$sql${migration.substring(end)}';
}

// ── .xlsx (unzipped) → CSV, enough for the WAFCT workbook ──────────────────

String _xmlText(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

String _xlsxSheetToCsv(String dir, String sheet) {
  final shared = File('$dir/xl/sharedStrings.xml').readAsStringSync();
  final strings = [
    for (final si in RegExp(r'<si>(.*?)</si>', dotAll: true).allMatches(shared))
      _xmlText(
        RegExp(
          r'<t[^>]*>(.*?)</t>',
          dotAll: true,
        ).allMatches(si.group(1)!).map((m) => m.group(1)!).join(),
      ),
  ];
  final xml = File('$dir/xl/worksheets/$sheet.xml').readAsStringSync();
  final rows = <List<String>>[];
  for (final row in RegExp(
    r'<row [^>]*>(.*?)</row>',
    dotAll: true,
  ).allMatches(xml)) {
    final cells = <int, String>{};
    final cellPattern = RegExp(
      r'<c r="([A-Z]+)\d+"([^>]*?)(?:/>|>(.*?)</c>)',
      dotAll: true,
    );
    for (final c in cellPattern.allMatches(row.group(1)!)) {
      var col = 0;
      for (final u in c.group(1)!.codeUnits) {
        col = col * 26 + (u - 64);
      }
      final body = c.group(3) ?? '';
      final v = RegExp(
        r'<v>(.*?)</v>',
        dotAll: true,
      ).firstMatch(body)?.group(1);
      final inline = RegExp(
        r'<t[^>]*>(.*?)</t>',
        dotAll: true,
      ).firstMatch(body)?.group(1);
      cells[col - 1] = v == null
          ? _xmlText(inline ?? '')
          : c.group(2)!.contains('t="s"')
          ? strings[int.parse(v)]
          : _xmlText(v);
    }
    if (cells.isEmpty) continue;
    final last = cells.keys.reduce((a, b) => a > b ? a : b);
    rows.add([
      for (var i = 0; i <= last; i++) (cells[i] ?? '').replaceAll('\n', ' '),
    ]);
  }
  return toCsv(rows);
}
