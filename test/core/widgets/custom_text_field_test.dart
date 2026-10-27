import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meal/core/l10n/l10n.dart';
import 'package:smart_meal/core/theme/app_theme.dart';
import 'package:smart_meal/core/widgets/custom_text_field.dart';

void main() {
  Future<void> pumpFields(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Column(
          children: [
            CustomTextField(
              key: const Key('plain'),
              label: 'Email',
              hint: 'user@email.com',
              prefixIcon: Icons.mail,
              controller: TextEditingController(),
            ),
            CustomTextField(
              key: const Key('password'),
              label: 'Password',
              hint: '••••••••',
              prefixIcon: Icons.lock,
              isPassword: true,
              controller: TextEditingController(text: 'secret'),
            ),
          ],
        ),
      ),
    ),
  );

  EditableText editable(WidgetTester tester) => tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(const Key('password')),
      matching: find.byType(EditableText),
    ),
  );

  testWidgets('password toggle is a labelled 48 dp button', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpFields(tester);

    final toggle = find.byType(IconButton);
    expect(toggle, findsOneWidget);
    expect(find.bySemanticsLabel('Show password'), findsOneWidget);
    final size = tester.getSize(toggle);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    expect(editable(tester).obscureText, isTrue);
    await tester.tap(toggle);
    await tester.pump();
    expect(editable(tester).obscureText, isFalse);
    expect(find.bySemanticsLabel('Hide password'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('the toggle does not make the field taller', (tester) async {
    await pumpFields(tester);

    expect(
      tester.getSize(find.byKey(const Key('password'))).height,
      tester.getSize(find.byKey(const Key('plain'))).height,
    );
  });
}
