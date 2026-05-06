import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'liquid_glass_theme.dart';

/// A widget that wraps its [child] in an Apple-style "Liquid Glass" surface
/// with advanced depth, edge lighting, inner shadows, and noise grain.
///
/// [CupertinoLiquidGlass] applies a real-time backdrop blur with vibrancy
/// enhancement, then composites multiple layers — tint, specular highlight,
/// inner shadow, noise grain, and an edge-lit gradient border — to closely
/// match the native iOS 26 liquid glass design language.
///
/// The widget automatically adapts to the ambient [CupertinoTheme] brightness,
/// switching between [LiquidGlassThemeData.light] and
/// [LiquidGlassThemeData.dark] presets when no explicit [theme] is provided.
///
/// ## Performance
///
/// A [RepaintBoundary] is inserted around the composited layers so that only
/// this subtree is re-rasterized when the backdrop changes. The noise grain
/// and inner shadow are rendered via [CustomPainter] with efficient
/// `shouldRepaint` guards.
///
/// ## Example
///
/// ```dart
/// CupertinoLiquidGlass(
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Hello, Glass!'),
///   ),
/// )
/// ```
class CupertinoLiquidGlass extends StatelessWidget {
  /// The widget to display inside the glass surface.
  final Widget child;

  /// An optional explicit theme. When null the widget resolves a theme
  /// automatically from [CupertinoTheme.brightnessOf].
  final LiquidGlassThemeData? theme;

  /// Override the blur sigma regardless of the resolved theme.
  final double? blurSigma;

  /// Override the tint opacity regardless of the resolved theme.
  final double? tintOpacity;

  /// Override the border radius regardless of the resolved theme.
  final BorderRadius? borderRadius;

  /// Override the edge light color regardless of the resolved theme.
  final Color? edgeLightColor;

  /// Override the edge shadow color regardless of the resolved theme.
  final Color? edgeShadowColor;

  /// Override the border width regardless of the resolved theme.
  final double? borderWidth;

  /// Override the specular gradient regardless of the resolved theme.
  final Gradient? specularGradient;

  /// Optional padding applied inside the glass surface around [child].
  final EdgeInsetsGeometry? padding;

  /// Optional fixed width. When null the widget sizes to its child.
  final double? width;

  /// Optional fixed height. When null the widget sizes to its child.
  final double? height;

  /// An optional glow color that casts a soft bloom around the entire
  /// glass surface. Useful for floating action buttons or highlighted panels.
  final Color? glowColor;

  /// The blur radius of the [glowColor] bloom. Defaults to 24.0.
  final double glowRadius;

  /// Creates a [CupertinoLiquidGlass] widget.
  const CupertinoLiquidGlass({
    super.key,
    required this.child,
    this.theme,
    this.blurSigma,
    this.tintOpacity,
    this.borderRadius,
    this.edgeLightColor,
    this.edgeShadowColor,
    this.borderWidth,
    this.specularGradient,
    this.padding,
    this.width,
    this.height,
    this.glowColor,
    this.glowRadius = 24.0,
  });

  /// Resolves the effective theme by merging explicit overrides on top of
  /// either the supplied [theme] or the brightness-derived default.
  LiquidGlassThemeData _resolveTheme(BuildContext context) {
    final brightness =
        CupertinoTheme.of(context).brightness ?? Brightness.light;
    final base =
        theme ??
        (brightness == Brightness.dark
            ? LiquidGlassThemeData.dark()
            : LiquidGlassThemeData.light());

    return base.copyWith(
      blurSigma: blurSigma,
      tintOpacity: tintOpacity,
      borderRadius: borderRadius,
      edgeLightColor: edgeLightColor,
      edgeShadowColor: edgeShadowColor,
      borderWidth: borderWidth,
      specularGradient: specularGradient,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveTheme(context);

    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: resolved.borderRadius,
          boxShadow: [
            ...?resolved.shadows,
            if (glowColor != null)
              BoxShadow(
                color: glowColor!.withValues(alpha: 0.45),
                blurRadius: glowRadius,
                spreadRadius: 2.0,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: resolved.borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: resolved.blurSigma,
              sigmaY: resolved.blurSigma,
              tileMode: TileMode.decal,
            ),
            child: _GlassSurface(
              theme: resolved,
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal widget that composites vibrancy, tint, inner shadow, specular
/// highlight, noise, and edge-lit border layers on top of the blurred backdrop.
class _GlassSurface extends StatelessWidget {
  final LiquidGlassThemeData theme;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  const _GlassSurface({
    required this.theme,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return CustomPaint(
      painter: _GlassBackgroundPainter(theme: theme),
      foregroundPainter: _GlassForegroundPainter(theme: theme, devicePixelRatio: dpr),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

/// Paints the vibrancy overlay, tint, specular gradient, and inner shadow
/// behind the child content.
class _GlassBackgroundPainter extends CustomPainter {
  final LiquidGlassThemeData theme;

  const _GlassBackgroundPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = theme.borderRadius.toRRect(rect);

    // 1. Vibrancy / saturation boost — a subtle overlay blend that
    //    perceptually increases the contrast and saturation of the
    //    blurred backdrop, simulating Apple's vibrancy effect.
    if (theme.vibrancyIntensity > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, theme.vibrancyIntensity)
          ..blendMode = BlendMode.overlay,
      );
    }

    // 2. Tint layer — the primary coloured overlay.
    canvas.drawRRect(
      rrect,
      Paint()..color = theme.tintColor.withValues(alpha: theme.tintOpacity),
    );

    // 3. Specular gradient — the "liquid" sheen.
    if (theme.specularGradient case final LinearGradient src) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            begin: src.begin,
            end: src.end,
            colors: src.colors
                .map(
                  (c) =>
                      c.withValues(alpha: c.a * theme.specularOpacity),
                )
                .toList(),
            stops: src.stops,
          ).createShader(rect),
      );
    }

    // 4. Inner shadow — the "carved out of glass" depth.
    //    Draws a large rect with an evenOdd hole punched out, then blurs
    //    it so only the soft inner edge is visible inside the clip region.
    if (theme.innerShadowBlurRadius > 0) {
      canvas.save();
      canvas.clipRRect(rrect);

      final inflate = theme.innerShadowBlurRadius * 2;
      final shadowPath = Path()
        ..addRect(rect.inflate(inflate))
        ..addRRect(rrect);
      shadowPath.fillType = PathFillType.evenOdd;

      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = theme.innerShadowColor
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            theme.innerShadowBlurRadius,
          ),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GlassBackgroundPainter oldDelegate) =>
      !identical(theme, oldDelegate.theme);
}

/// Paints the noise grain overlay and edge-lit gradient border on top of
/// the child content.
class _GlassForegroundPainter extends CustomPainter {
  final LiquidGlassThemeData theme;
  final double devicePixelRatio;

  const _GlassForegroundPainter({
    required this.theme,
    required this.devicePixelRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = theme.borderRadius.toRRect(rect);

    // 1. Noise grain overlay — microscopic texture that prevents banding
    //    and makes the glass surface look physical.
    if (theme.noiseOpacity > 0) {
      _drawNoise(canvas, rrect, rect);
    }

    // 2. Edge-lit gradient border — a 1px stroke with a LinearGradient
    //    from bright (top-left) to dark (bottom-right), simulating
    //    directional light catching the glass edge.
    if (theme.borderWidth > 0) {
      final borderRRect = rrect.deflate(theme.borderWidth / 2);
      canvas.drawRRect(
        borderRRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = theme.borderWidth
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.edgeLightColor,
              Color.lerp(
                theme.edgeLightColor,
                theme.edgeShadowColor,
                0.5,
              )!,
              theme.edgeShadowColor,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(rect),
      );
    }
  }

  void _drawNoise(Canvas canvas, RRect rrect, Rect rect) {
    canvas.save();
    canvas.clipRRect(rrect);

    final random = math.Random(42);
    final density =
        (rect.width * rect.height / 20).toInt().clamp(100, 5000);

    final lightPoints = <Offset>[];
    final darkPoints = <Offset>[];

    for (int i = 0; i < density; i++) {
      final offset = Offset(
        rect.left + random.nextDouble() * rect.width,
        rect.top + random.nextDouble() * rect.height,
      );
      if (random.nextBool()) {
        lightPoints.add(offset);
      } else {
        darkPoints.add(offset);
      }
    }

    final grainSize = 1.0 / devicePixelRatio;

    if (lightPoints.isNotEmpty) {
      canvas.drawPoints(
        PointMode.points,
        lightPoints,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, theme.noiseOpacity)
          ..strokeWidth = grainSize
          ..strokeCap = StrokeCap.round,
      );
    }

    if (darkPoints.isNotEmpty) {
      canvas.drawPoints(
        PointMode.points,
        darkPoints,
        Paint()
          ..color = Color.fromRGBO(0, 0, 0, theme.noiseOpacity)
          ..strokeWidth = grainSize
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlassForegroundPainter oldDelegate) =>
      !identical(theme, oldDelegate.theme) ||
      devicePixelRatio != oldDelegate.devicePixelRatio;
}

/// A widget that casts a soft colored glow (bloom effect) behind its child.
///
/// Use inside a [CupertinoLiquidGlass] surface to simulate the glow that
/// active or highlighted elements cast onto the glass, as seen with the
/// selected tab indicator in iOS 26.
///
/// ## Example
///
/// ```dart
/// LiquidGlassBloom(
///   color: CupertinoColors.activeBlue,
///   child: Icon(CupertinoIcons.house_fill, color: CupertinoColors.activeBlue),
/// )
/// ```
class LiquidGlassBloom extends StatelessWidget {
  /// The widget to display on top of the bloom glow.
  final Widget child;

  /// The color of the bloom glow.
  final Color color;

  /// The blur radius of the bloom effect.
  final double radius;

  /// The spread of the bloom beyond the child bounds.
  final double spread;

  /// The opacity of the bloom glow (0.0–1.0).
  final double intensity;

  /// Creates a [LiquidGlassBloom] widget.
  const LiquidGlassBloom({
    super.key,
    required this.child,
    required this.color,
    this.radius = 20.0,
    this.spread = 8.0,
    this.intensity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BloomPainter(
        color: color,
        spread: spread,
        intensity: intensity,
      ),
      child: child,
    );
  }
}

/// Paints a soft radial gradient behind the child to simulate a bloom /
/// light-spill effect on the glass surface.
class _BloomPainter extends CustomPainter {
  final Color color;
  final double spread;
  final double intensity;

  const _BloomPainter({
    required this.color,
    required this.spread,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height) / 2 + spread;

    final gradient = RadialGradient(
      colors: [
        color.withValues(alpha: intensity),
        color.withValues(alpha: intensity * 0.4),
        color.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    canvas.drawCircle(
      center,
      maxRadius,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: maxRadius),
        ),
    );
  }

  @override
  bool shouldRepaint(_BloomPainter oldDelegate) =>
      color != oldDelegate.color ||
      spread != oldDelegate.spread ||
      intensity != oldDelegate.intensity;
}

/// A circular floating glass button, visually detached from a bar.
///
/// Mirrors the "detached sidebar button" pattern seen in iOS 26 apps such as
/// Apple News, where a prominent action is separated from the main tab strip
/// and given a more transparent, prismatic glass treatment.
///
/// Pass this widget to the [detachedButton] parameter of
/// [CupertinoLiquidGlassBottomBar] or [CupertinoLiquidGlassNavBar].
///
/// ## Example
///
/// ```dart
/// CupertinoLiquidGlassBottomBar(
///   items: [...],
///   currentIndex: _index,
///   onTap: (i) => setState(() => _index = i),
///   detachedButton: LiquidGlassDetachedButton(
///     onTap: () {},
///     child: Icon(CupertinoIcons.search, color: CupertinoColors.activeBlue),
///   ),
/// )
/// ```
class LiquidGlassDetachedButton extends StatelessWidget {
  /// The icon or widget displayed inside the button.
  final Widget child;

  /// Called when the button is tapped.
  final VoidCallback? onTap;

  /// Diameter of the circular button. Defaults to 56 pt (matches bottom bar).
  final double size;

  /// When true, a subtle sweep gradient simulating prismatic light refraction
  /// is composited over the glass surface — matching the iridescent quality
  /// of iOS 26 detached buttons when placed over colorful content.
  final bool iridescent;

  /// Optional explicit glass theme. When null, a more transparent variant of
  /// the brightness-derived preset is used to let backdrop colors bleed through.
  final LiquidGlassThemeData? theme;

  /// Creates a [LiquidGlassDetachedButton].
  const LiquidGlassDetachedButton({
    super.key,
    required this.child,
    this.onTap,
    this.size = 56.0,
    this.iridescent = true,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final brightness =
        CupertinoTheme.of(context).brightness ?? Brightness.light;
    final isDark = brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(size / 2);

    final resolvedTheme = theme ??
        (isDark
            ? LiquidGlassThemeData.dark().copyWith(
                tintOpacity: 0.28,
                blurSigma: 20.0,
              )
            : LiquidGlassThemeData.light().copyWith(
                tintOpacity: 0.28,
                blurSigma: 20.0,
              ));

    Widget button = SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CupertinoLiquidGlass(
            theme: resolvedTheme,
            borderRadius: borderRadius,
            width: size,
            height: size,
            child: Center(child: child),
          ),
          if (iridescent)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: CustomPaint(
                    painter: _IridescentPainter(isDark: isDark),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap != null) {
      button = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: button,
      );
    }

    return button;
  }
}

/// Paints a subtle sweep gradient that simulates prismatic light refraction —
/// the rainbow-sheen quality visible on iOS 26 detached buttons placed over
/// colorful content.
class _IridescentPainter extends CustomPainter {
  final bool isDark;

  const _IridescentPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final opacity = isDark ? 0.10 : 0.12;

    final gradient = SweepGradient(
      center: Alignment.center,
      colors: [
        Color.fromRGBO(255, 0, 128, opacity),
        Color.fromRGBO(255, 120, 0, opacity * 0.8),
        Color.fromRGBO(80, 220, 120, opacity),
        Color.fromRGBO(0, 160, 255, opacity),
        Color.fromRGBO(140, 0, 255, opacity),
        Color.fromRGBO(255, 0, 128, opacity),
      ],
    );

    canvas.drawOval(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_IridescentPainter oldDelegate) =>
      isDark != oldDelegate.isDark;
}
