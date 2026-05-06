import 'dart:ui';

import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiquidGlassThemeData', () {
    test('default constructor provides sensible defaults', () {
      const theme = LiquidGlassThemeData();
      expect(theme.blurSigma, 25.0);
      expect(theme.tintOpacity, 0.65);
      expect(theme.borderWidth, 0.75);
    });

    test('light factory produces non-null specular gradient', () {
      final theme = LiquidGlassThemeData.light();
      expect(theme.specularGradient, isNotNull);
      expect(theme.shadows, isNotNull);
      expect(theme.shadows, isNotEmpty);
    });

    test('dark factory uses darker tint', () {
      final theme = LiquidGlassThemeData.dark();
      expect(theme.tintColor, const Color(0xFF1C1C1E));
      expect(theme.blurSigma, greaterThanOrEqualTo(28.0));
    });

    test('copyWith replaces only specified fields', () {
      final original = LiquidGlassThemeData.light();
      final modified = original.copyWith(blurSigma: 50.0);
      expect(modified.blurSigma, 50.0);
      expect(modified.tintColor, original.tintColor);
    });

    test('lerp interpolates between two themes', () {
      final a = LiquidGlassThemeData.light();
      final b = LiquidGlassThemeData.dark();
      final mid = LiquidGlassThemeData.lerp(a, b, 0.5);
      expect(mid.blurSigma, closeTo(26.5, 0.1));
    });
  });

  group('CupertinoLiquidGlass', () {
    Widget buildTestWidget({
      Brightness brightness = Brightness.light,
      LiquidGlassThemeData? theme,
      double? blurSigma,
    }) {
      return CupertinoApp(
        theme: CupertinoThemeData(brightness: brightness),
        home: CupertinoPageScaffold(
          child: Center(
            child: CupertinoLiquidGlass(
              theme: theme,
              blurSigma: blurSigma,
              child: const Text('Glass'),
            ),
          ),
        ),
      );
    }

    testWidgets('renders child text', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.text('Glass'), findsOneWidget);
    });

    testWidgets('contains a BackdropFilter', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('wraps content in a RepaintBoundary', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('applies explicit blurSigma override', (tester) async {
      await tester.pumpWidget(buildTestWidget(blurSigma: 10.0));
      final backdrop = tester.widget<BackdropFilter>(
        find.byType(BackdropFilter),
      );
      final filter = backdrop.filter as ImageFilter;
      expect(filter, isNotNull);
    });

    testWidgets('adapts to dark mode', (tester) async {
      await tester.pumpWidget(buildTestWidget(brightness: Brightness.dark));
      expect(find.byType(CupertinoLiquidGlass), findsOneWidget);
    });
  });

  group('CupertinoLiquidGlassNavBar', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: Column(
              children: [
                CupertinoLiquidGlassNavBar(title: Text('Nav Title')),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Nav Title'), findsOneWidget);
    });
  });

  group('CupertinoLiquidGlassBottomBar', () {
    testWidgets('renders all tab items', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoLiquidGlassBottomBar(
                  items: const [
                    LiquidGlassBottomBarItem(
                      icon: CupertinoIcons.home,
                      label: 'Home',
                    ),
                    LiquidGlassBottomBarItem(
                      icon: CupertinoIcons.search,
                      label: 'Search',
                    ),
                  ],
                  onTap: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('calls onTap with correct index', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoLiquidGlassBottomBar(
                  items: const [
                    LiquidGlassBottomBarItem(
                      icon: CupertinoIcons.home,
                      label: 'Home',
                    ),
                    LiquidGlassBottomBarItem(
                      icon: CupertinoIcons.search,
                      label: 'Search',
                    ),
                  ],
                  onTap: (i) => tappedIndex = i,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search'));
      expect(tappedIndex, 1);
    });
  });
}
