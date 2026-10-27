import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meal/core/l10n/l10n.dart';
import 'package:smart_meal/core/theme/app_theme.dart';
import 'package:smart_meal/core/widgets/recipe_card.dart';

void main() {
  testWidgets('favorite toggle is a labelled 48 dp button', (tester) async {
    final semantics = tester.ensureSemantics();
    var toggles = 0;
    var taps = 0;
    Future<void> pump({required bool isFavorite}) => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: RecipeCard(
              title: 'Jollof rice',
              price: '\$4.50',
              time: '30 min',
              difficulty: 'Easy',
              imageUrl: '',
              matchPercentage: 92,
              isFavorite: isFavorite,
              onFavoriteToggle: () => toggles++,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );

    await pump(isFavorite: false);
    expect(find.bySemanticsLabel('Add to favorites'), findsOneWidget);
    final size = tester.getSize(find.byType(IconButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    await tester.tap(find.byType(IconButton));
    expect(toggles, 1);
    expect(taps, 0);

    await pump(isFavorite: true);
    expect(find.bySemanticsLabel('Remove from favorites'), findsOneWidget);

    semantics.dispose();
  });
}
