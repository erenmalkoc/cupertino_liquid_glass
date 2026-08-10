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

    test('implements value equality and hashCode', () {
      const a = LiquidGlassThemeData(blurSigma: 10.0);
      const b = LiquidGlassThemeData(blurSigma: 10.0);
      const c = LiquidGlassThemeData(blurSigma: 12.0);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
      expect(
        LiquidGlassThemeData.light(),
        equals(LiquidGlassThemeData.light()),
      );
      expect(
        LiquidGlassThemeData.light(),
        isNot(equals(LiquidGlassThemeData.dark())),
      );
    });

    test('light/dark factories return canonical instances', () {
      // Painter shouldRepaint short-circuits rely on this staying true.
      expect(
        identical(LiquidGlassThemeData.light(), LiquidGlassThemeData.light()),
        isTrue,
      );
      expect(
        identical(LiquidGlassThemeData.dark(), LiquidGlassThemeData.dark()),
        isTrue,
      );
    });

    test('copyWith with no arguments returns the same instance', () {
      final theme = LiquidGlassThemeData.light();
      expect(identical(theme.copyWith(), theme), isTrue);
    });

    test('lerp short-circuits at the endpoints', () {
      final a = LiquidGlassThemeData.light();
      final b = LiquidGlassThemeData.dark();
      expect(identical(LiquidGlassThemeData.lerp(a, b, 0.0), a), isTrue);
      expect(identical(LiquidGlassThemeData.lerp(a, b, 1.0), b), isTrue);
      expect(identical(LiquidGlassThemeData.lerp(a, a, 0.5), a), isTrue);
    });

    test('lerp preserves null shadows', () {
      const a = LiquidGlassThemeData();
      const b = LiquidGlassThemeData(blurSigma: 40.0);
      expect(LiquidGlassThemeData.lerp(a, b, 0.5).shadows, isNull);
    });

    test('scaleEffects scales decoration but not the material', () {
      final theme = LiquidGlassThemeData.light();
      final scaled = theme.scaleEffects(0.5);
      expect(
        scaled.specularOpacity,
        closeTo(theme.specularOpacity * 0.5, 1e-9),
      );
      expect(scaled.noiseOpacity, closeTo(theme.noiseOpacity * 0.5, 1e-9));
      expect(
        scaled.vibrancyIntensity,
        closeTo(theme.vibrancyIntensity * 0.5, 1e-9),
      );
      expect(
        scaled.edgeLightColor.a,
        closeTo(theme.edgeLightColor.a * 0.5, 1e-6),
      );
      // Material properties stay untouched.
      expect(scaled.blurSigma, theme.blurSigma);
      expect(scaled.tintOpacity, theme.tintOpacity);
      expect(scaled.borderRadius, theme.borderRadius);
      expect(scaled.shadows, theme.shadows);
    });

    test('scaleEffects(1.0) returns the same instance', () {
      final theme = LiquidGlassThemeData.light();
      expect(identical(theme.scaleEffects(1.0), theme), isTrue);
      expect(identical(theme.scaleEffects(2.0), theme), isTrue);
    });

    test('scaleEffects(0.0) zeroes all decorative layers', () {
      final plain = LiquidGlassThemeData.dark().scaleEffects(0.0);
      expect(plain.specularOpacity, 0.0);
      expect(plain.noiseOpacity, 0.0);
      expect(plain.vibrancyIntensity, 0.0);
      expect(plain.edgeLightColor.a, 0.0);
      expect(plain.innerShadowColor.a, 0.0);
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
              children: [CupertinoLiquidGlassNavBar(title: Text('Nav Title'))],
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

    testWidgets('touch-down pre-move does not commit a selection', (
      tester,
    ) async {
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

      // Press down on a tab (pill starts pre-moving) but cancel the gesture:
      // the consumer callback must not fire and the bar must settle back.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Search')),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(tappedIndex, isNull);

      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(tappedIndex, isNull);
    });

    testWidgets('itemInset moves the outer tabs off the rounded ends', (
      tester,
    ) async {
      Future<double> firstTabCenter(double inset) async {
        await tester.pumpWidget(_bottomBarHarness(itemInset: inset));
        return tester.getCenter(find.text('Home')).dx;
      }

      // Insetting the strip by `i` shifts an outer tab's centre by `i / 2`:
      // it starts `i` further in but its share of the strip shrinks by `i / 2`.
      final flush = await firstTabCenter(0.0);
      final inset = await firstTabCenter(20.0);
      expect(inset - flush, closeTo(10.0, 0.01));
    });

    testWidgets('taps on the inset margin still hit the outer tabs', (
      tester,
    ) async {
      int? tappedIndex;
      await tester.pumpWidget(
        _bottomBarHarness(itemInset: 20.0, onTap: (i) => tappedIndex = i),
      );

      // The strip is inset but the gesture box still spans the full bar, so
      // the dead-looking margin at each end belongs to its neighbouring tab.
      final bar = tester.getRect(find.byType(CupertinoLiquidGlassBottomBar));
      await tester.tapAt(Offset(bar.left + 10.0, bar.center.dy));
      expect(tappedIndex, 0);

      await tester.tapAt(Offset(bar.right - 10.0, bar.center.dy));
      expect(tappedIndex, 1);
    });
  });
}

Widget _bottomBarHarness({required double itemInset, ValueChanged<int>? onTap}) {
  return CupertinoApp(
    home: CupertinoPageScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CupertinoLiquidGlassBottomBar(
            itemInset: itemInset,
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
            onTap: onTap ?? (_) {},
          ),
        ],
      ),
    ),
  );
}
