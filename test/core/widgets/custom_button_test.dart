import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meal/core/theme/app_colors.dart';
import 'package:smart_meal/core/theme/app_theme.dart';
import 'package:smart_meal/core/widgets/custom_button.dart';

Future<void> _pump(WidgetTester tester, Widget button) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: button),
  ),
);

void main() {
  testWidgets('outline loading spinner uses the outline foreground', (
    tester,
  ) async {
    await _pump(
      tester,
      const CustomButton(text: 'Save', isOutline: true, isLoading: true),
    );

    final spinner = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    // White on the cream background was invisible.
    expect(spinner.color, AppColors.primary);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('primary loading spinner uses the primary foreground', (
    tester,
  ) async {
    await _pump(tester, const CustomButton(text: 'Save', isLoading: true));

    final spinner = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(spinner.color, AppColors.onPrimary);
    // The fill stays primary (not the disabled grey), so the spinner shows.
    final fill = tester.widget<Material>(
      find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.byType(Material),
      ),
    );
    expect(fill.color, AppColors.primary);
  });

  testWidgets('a disabled, non-loading primary button keeps the theme look', (
    tester,
  ) async {
    await _pump(tester, const CustomButton(text: 'Save'));

    final fill = tester.widget<Material>(
      find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.byType(Material),
      ),
    );
    expect(fill.color, isNot(AppColors.primary));
  });
}
