import 'dart:ui';

import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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

    testWidgets('paints radial and sweep specular gradients', (tester) async {
      Future<int> rectCount(Gradient gradient) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: Center(
              child: CupertinoLiquidGlass(
                specularGradient: gradient,
                child: const SizedBox(width: 100, height: 60),
              ),
            ),
          ),
        );
        // The layered surface painter sits right under the backdrop filter.
        final surface = tester.renderObject(
          find
              .descendant(
                of: find.byType(BackdropFilter),
                matching: find.byType(CustomPaint),
              )
              .first,
        );
        var rects = 0;
        expect(
          surface,
          paints..everything((method, arguments) {
            if (method == #drawRect) rects++;
            return true;
          }),
        );
        return rects;
      }

      const colors = [Color(0xFFFFFFFF), Color(0x00FFFFFF)];
      final linear = await rectCount(const LinearGradient(colors: colors));
      expect(await rectCount(const RadialGradient(colors: colors)), linear);
      expect(await rectCount(const SweepGradient(colors: colors)), linear);
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

    testWidgets('shrinks every label until the widest fits the selector', (
      tester,
    ) async {
      await tester.pumpWidget(
        _bottomBarHarness(
          itemInset: 0.0,
          labels: const [
            'Hi',
            'A tab label far too long to ever fit inside the selector pill',
          ],
        ),
      );

      final short = tester.widget<Text>(find.text('Hi')).style!.fontSize!;
      final long = tester
          .widget<Text>(
            find.text(
              'A tab label far too long to ever fit inside the selector pill',
            ),
          )
          .style!
          .fontSize!;

      // One size for the whole bar, driven by the label that would otherwise
      // spill out of the pill.
      expect(short, long);
      expect(short, lessThan(10.0));
    });

    testWidgets('leaves labels at full size when they already fit', (
      tester,
    ) async {
      await tester.pumpWidget(
        _bottomBarHarness(itemInset: 0.0, labels: const ['Hi', 'Yo']),
      );

      expect(tester.widget<Text>(find.text('Hi')).style!.fontSize, 10.0);
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

    testWidgets('dragging to the next tab commits it', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(_bottomBarHarness(onTap: taps.add));

      await _slowDrag(
        tester,
        tester.getCenter(find.text('Home')),
        tester.getCenter(find.text('Search')),
      );
      expect(taps, [1]);

      // Once the rubber band settles the bar is back to an exact identity
      // transform, which paints without a layer or any resampling.
      final rubberBand = tester.widget<Transform>(
        find
            .ancestor(
              of: find.byType(CupertinoLiquidGlass),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(MatrixUtils.isIdentity(rubberBand.transform), isTrue);
    });

    testWidgets('rubber banding does not remount the bar mid-drag', (
      tester,
    ) async {
      await tester.pumpWidget(_bottomBarHarness());
      final glass = tester.renderObject(find.byType(BackdropFilter));

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Home')),
      );
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(12.0, 0.0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      // Rebuilding the bar under a new parent would dispose the drag
      // recognizer and cancel the gesture.
      expect(tester.renderObject(find.byType(BackdropFilter)), same(glass));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('each tab announces its label once', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _bottomBarHarness(labels: const ['Home', 'Search', 'Settings']),
      );

      expect(
        tester.getSemantics(find.text('Home')),
        matchesSemantics(
          label: 'Home',
          hint: 'Tab 1 of 3',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('Search')),
        matchesSemantics(
          label: 'Search',
          hint: 'Tab 2 of 3',
          isButton: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('takes the tab hint from CupertinoLocalizations', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _bottomBarHarness(
          localizationsDelegates: const [_TabHintLocalizations.delegate],
        ),
      );

      expect(
        tester.getSemantics(find.text('Search')),
        matchesSemantics(
          label: 'Search',
          hint: 'tab 2/2',
          isButton: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });
  });

  group('CupertinoLiquidGlassBottomBar in RTL', () {
    const labels = ['Home', 'Search', 'Settings'];

    testWidgets('taps report the logical index of the tapped tab', (
      tester,
    ) async {
      final taps = <int>[];
      await tester.pumpWidget(
        _bottomBarHarness(
          labels: labels,
          textDirection: TextDirection.rtl,
          onTap: taps.add,
        ),
      );
      // Tab 0 is laid out on the right.
      expect(
        tester.getCenter(find.text('Home')).dx,
        greaterThan(tester.getCenter(find.text('Settings')).dx),
      );

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(taps, [0, 2]);
    });

    testWidgets('dragging to the next tab commits it', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(
        _bottomBarHarness(
          labels: labels,
          textDirection: TextDirection.rtl,
          onTap: taps.add,
        ),
      );

      await _slowDrag(
        tester,
        tester.getCenter(find.text('Home')),
        tester.getCenter(find.text('Search')),
      );
      expect(taps, [1]);
    });

    testWidgets('the selector pill sits under the selected tab', (
      tester,
    ) async {
      await tester.pumpWidget(
        _bottomBarHarness(labels: labels, textDirection: TextDirection.rtl),
      );

      // The pill painter is the closest CustomPaint above the tab labels.
      final selector = tester.renderObject<RenderBox>(
        find
            .ancestor(of: find.text('Home'), matching: find.byType(CustomPaint))
            .first,
      );
      final pills = <RRect>[];
      expect(
        selector,
        paints..everything((method, arguments) {
          if (method == #drawRRect) pills.add(arguments.first as RRect);
          return true;
        }),
      );

      // Every layer of the pill (glow rings, fill, highlight) shares a centre.
      expect(pills, isNotEmpty);
      expect(
        selector.localToGlobal(pills.first.center).dx,
        closeTo(tester.getCenter(find.text('Home')).dx, 0.5),
      );
    });
  });

  group('platform dark mode with no theme brightness', () {
    // CupertinoApp leaves CupertinoThemeData.brightness null, and Cupertino
    // widgets then follow the platform brightness. The glass must do the same.
    void useDarkPlatform(WidgetTester tester) {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    }

    testWidgets('CupertinoLiquidGlass uses the dark preset', (tester) async {
      useDarkPlatform(tester);
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoLiquidGlass(
              // No vibrancy, so the filter is the preset's plain blur.
              effectIntensity: 0.0,
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );

      final sigma = LiquidGlassThemeData.dark().blurSigma;
      expect(
        tester.widget<BackdropFilter>(find.byType(BackdropFilter)).filter,
        ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      );
    });

    testWidgets('the solid fallback uses the dark system grey', (tester) async {
      useDarkPlatform(tester);
      await tester.pumpWidget(const CupertinoApp(home: _SolidGlass()));
      expect(_solidColor(tester), const Color(0xFF1C1C1E));
    });

    testWidgets('an explicit theme brightness still wins', (tester) async {
      useDarkPlatform(tester);
      await tester.pumpWidget(
        const CupertinoApp(
          theme: CupertinoThemeData(brightness: Brightness.light),
          home: _SolidGlass(),
        ),
      );
      expect(_solidColor(tester), const Color(0xFFF2F2F7));
    });

    testWidgets('LiquidGlassDetachedButton uses the dark glass', (
      tester,
    ) async {
      useDarkPlatform(tester);
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: LiquidGlassDetachedButton(
              onTap: () {},
              child: const Icon(CupertinoIcons.plus),
            ),
          ),
        ),
      );

      final glass = tester.widget<CupertinoLiquidGlass>(
        find.byType(CupertinoLiquidGlass),
      );
      expect(glass.theme!.tintColor, LiquidGlassThemeData.dark().tintColor);
    });

    testWidgets('the bottom bar uses the dark inactive tab color', (
      tester,
    ) async {
      useDarkPlatform(tester);
      await tester.pumpWidget(_bottomBarHarness());

      final inactiveLabel = tester.widget<Text>(find.text('Search'));
      expect(
        inactiveLabel.style!.color,
        isSameColorAs(CupertinoColors.systemGrey),
      );
    });
  });
}

/// A glass surface with the solid (glass disabled) fallback.
class _SolidGlass extends StatelessWidget {
  const _SolidGlass();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CupertinoLiquidGlass(
        enabled: false,
        child: SizedBox(width: 40, height: 40),
      ),
    );
  }
}

/// The background color of the solid fallback surface.
Color? _solidColor(WidgetTester tester) {
  final box = tester.widget<Container>(
    find.descendant(
      of: find.byType(CupertinoLiquidGlass),
      matching: find.byType(Container),
    ),
  );
  return (box.decoration! as BoxDecoration).color;
}

/// Drags slowly enough that the release is not a fling, so the selection is
/// decided by where the finger stops.
Future<void> _slowDrag(WidgetTester tester, Offset from, Offset to) async {
  final gesture = await tester.startGesture(from);
  const steps = 20;
  for (var i = 1; i <= steps; i++) {
    await gesture.moveTo(Offset.lerp(from, to, i / steps)!);
    await tester.pump(const Duration(milliseconds: 32));
  }
  await tester.pump(const Duration(milliseconds: 200));
  await gesture.up();
  await tester.pumpAndSettle();
}

/// English Cupertino strings with a recognisable tab hint.
class _TabHintLocalizations extends DefaultCupertinoLocalizations {
  const _TabHintLocalizations();

  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      _TabHintLocalizationsDelegate();

  @override
  String tabSemanticsLabel({required int tabIndex, required int tabCount}) =>
      'tab $tabIndex/$tabCount';
}

class _TabHintLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _TabHintLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(const _TabHintLocalizations());

  @override
  bool shouldReload(_TabHintLocalizationsDelegate old) => false;
}

Widget _bottomBarHarness({
  double? itemInset,
  ValueChanged<int>? onTap,
  List<String> labels = const ['Home', 'Search'],
  TextDirection textDirection = TextDirection.ltr,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
}) {
  return CupertinoApp(
    localizationsDelegates: localizationsDelegates,
    builder: (context, child) =>
        Directionality(textDirection: textDirection, child: child!),
    home: CupertinoPageScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CupertinoLiquidGlassBottomBar(
            itemInset: itemInset,
            items: [
              for (final label in labels)
                LiquidGlassBottomBarItem(
                  icon: CupertinoIcons.home,
                  label: label,
                ),
            ],
            onTap: onTap ?? (_) {},
          ),
        ],
      ),
    ),
  );
}
