import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

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

  /// When false, the backdrop blur and all decorative glass layers (vibrancy,
  /// specular, inner shadow, noise grain, edge light) are skipped and the
  /// surface falls back to a solid Cupertino system-grey background.
  ///
  /// Useful as a low-power fallback or as a design opt-out — wrappers like
  /// [CupertinoLiquidGlassBottomBar] forward their own `enableGlass` flag here.
  final bool enabled;

  /// Optional solid background color used when [enabled] is false. When null,
  /// `CupertinoColors.systemGrey6` is resolved against the current brightness.
  final Color? disabledColor;

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
    this.enabled = true,
    this.disabledColor,
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

    if (!enabled) {
      return _buildDisabled(context, resolved);
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: _OuterShadowPainter(
          borderRadius: resolved.borderRadius,
          shadows: resolved.shadows,
          glowColor: glowColor,
          glowRadius: glowRadius,
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: resolved.borderRadius,
            child: BackdropFilter.grouped(
              filter: _backdropFilter(resolved),
              child: _GlassSurface(
                theme: resolved,
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the backdrop filter: a Gaussian blur, optionally composed with a
  /// saturation boost that implements the vibrancy effect inside the same
  /// backdrop pass.
  ///
  /// Doing vibrancy in the filter chain (saturate-then-blur, like UIKit
  /// materials) avoids the advanced-blend offscreen pass a
  /// [BlendMode.overlay] draw would cost on every frame. The tile mode is
  /// left to the engine, which picks the artifact-free mode for backdrop
  /// blurs — an explicit [TileMode.decal] would mix transparent black into
  /// the edges and produce a dark fringe around the glass.
  static ui.ImageFilter _backdropFilter(LiquidGlassThemeData theme) {
    final blur = ui.ImageFilter.blur(
      sigmaX: theme.blurSigma,
      sigmaY: theme.blurSigma,
    );
    if (theme.vibrancyIntensity <= 0) {
      return blur;
    }
    return ui.ImageFilter.compose(
      outer: _saturationFilter(1.0 + theme.vibrancyIntensity * 1.5),
      inner: blur,
    );
  }

  /// A luminance-preserving saturation matrix color filter.
  static ColorFilter _saturationFilter(double saturation) {
    final inv = 1.0 - saturation;
    final r = 0.2126 * inv;
    final g = 0.7152 * inv;
    final b = 0.0722 * inv;
    return ColorFilter.matrix(<double>[
      r + saturation, g, b, 0, 0, //
      r, g + saturation, b, 0, 0, //
      r, g, b + saturation, 0, 0, //
      0, 0, 0, 1, 0,
    ]);
  }

  /// Solid Cupertino-style surface used when [enabled] is false. Keeps the
  /// shape, shadow and glow but drops every layer that depends on backdrop
  /// sampling, so it can be used as a cheap fallback on low-end devices.
  Widget _buildDisabled(BuildContext context, LiquidGlassThemeData resolved) {
    final brightness =
        CupertinoTheme.of(context).brightness ?? Brightness.light;
    // Mirror CupertinoColors.systemGrey6 light/dark values directly — avoids
    // depending on an ambient CupertinoTheme for color resolution.
    final solid =
        disabledColor ??
        (brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFF2F2F7));

    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: solid,
          borderRadius: resolved.borderRadius,
          border: resolved.borderWidth > 0
              ? Border.all(
                  color: resolved.edgeShadowColor,
                  width: resolved.borderWidth,
                )
              : null,
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
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}

/// Paints the drop shadow and optional glow *around* the glass surface.
///
/// The glass footprint is punched out of the shadow region before painting:
/// a [BoxDecoration.boxShadow] would also fill the area *under* the glass,
/// and the [BackdropFilter] would then sample its own shadow and bake a dark
/// haze into the surface. Clipping the shadow to the outside keeps the
/// backdrop clean, like native iOS materials.
class _OuterShadowPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final List<BoxShadow>? shadows;
  final Color? glowColor;
  final double glowRadius;

  const _OuterShadowPainter({
    required this.borderRadius,
    required this.shadows,
    required this.glowColor,
    required this.glowRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hasShadows = shadows != null && shadows!.isNotEmpty;
    if (!hasShadows && glowColor == null) return;

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect.inflate(_maxExtent())),
      Path()..addRRect(rrect),
    );

    canvas.save();
    canvas.clipPath(outside);
    if (hasShadows) {
      for (final shadow in shadows!) {
        canvas.drawRRect(
          rrect.shift(shadow.offset).inflate(shadow.spreadRadius),
          shadow.toPaint(),
        );
      }
    }
    if (glowColor != null) {
      canvas.drawRRect(
        rrect.inflate(2.0),
        Paint()
          ..color = glowColor!.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            Shadow.convertRadiusToSigma(glowRadius),
          ),
      );
    }
    canvas.restore();
  }

  /// Conservative bound on how far any shadow can reach beyond the surface.
  double _maxExtent() {
    var max = glowColor != null ? glowRadius + 2.0 : 0.0;
    for (final shadow in shadows ?? const <BoxShadow>[]) {
      final extent =
          shadow.blurRadius + shadow.spreadRadius + shadow.offset.distance;
      if (extent > max) max = extent;
    }
    return max + 8.0;
  }

  @override
  bool shouldRepaint(_OuterShadowPainter oldDelegate) =>
      borderRadius != oldDelegate.borderRadius ||
      !listEquals(shadows, oldDelegate.shadows) ||
      glowColor != oldDelegate.glowColor ||
      glowRadius != oldDelegate.glowRadius;
}

/// Internal widget that composites tint, inner shadow, specular highlight,
/// noise, and edge-lit border layers on top of the blurred backdrop.
class _GlassSurface extends StatelessWidget {
  final LiquidGlassThemeData theme;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  const _GlassSurface({required this.theme, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return CustomPaint(
      painter: _GlassBackgroundPainter(theme: theme),
      foregroundPainter: _GlassForegroundPainter(
        theme: theme,
        devicePixelRatio: dpr,
      ),
      isComplex: true,
      willChange: false,
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );
  }
}

/// Paints the tint, specular gradient, and inner shadow behind the child
/// content. (The vibrancy boost lives in the backdrop filter chain — see
/// [CupertinoLiquidGlass._backdropFilter].)
class _GlassBackgroundPainter extends CustomPainter {
  final LiquidGlassThemeData theme;

  const _GlassBackgroundPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = theme.borderRadius.toRRect(rect);

    // The ancestor ClipRRect already shapes the surface, so flat layers are
    // painted full-bleed: drawing them as an rrect matching the clip would
    // double-antialias the same edge and leave a ~1px halo along the corners.

    // 1. Tint layer — the primary coloured overlay.
    canvas.drawRect(
      rect,
      Paint()..color = theme.tintColor.withValues(alpha: theme.tintOpacity),
    );

    // 2. Specular gradient — the "liquid" sheen.
    if (theme.specularGradient case final LinearGradient src) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: src.begin,
            end: src.end,
            colors: src.colors
                .map((c) => c.withValues(alpha: c.a * theme.specularOpacity))
                .toList(),
            stops: src.stops,
          ).createShader(rect),
      );
    }

    // 3. Inner shadow — the "carved out of glass" depth.
    //    Draws a large rect with an evenOdd hole punched out, then blurs
    //    it so only the soft inner edge is visible inside the clip region.
    if (theme.innerShadowBlurRadius > 0) {
      canvas.save();
      canvas.clipRRect(rrect);

      // Inflate by 4x the blur radius so the outer rect's own blur tail
      // (~3 sigma) stays fully outside the clip and cannot bleed a faint
      // band back into the surface.
      final inflate = theme.innerShadowBlurRadius * 4;
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
      theme != oldDelegate.theme;
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

  /// Cached repeating noise tiles keyed by device pixel ratio.
  ///
  /// Each tile is baked once via [ui.Picture.toImageSync] with full-opacity
  /// grain pixels; the paint color's alpha modulates the tile at draw time,
  /// so changing [LiquidGlassThemeData.noiseOpacity] never requires a
  /// re-bake. This replaces regenerating and drawing up to 5000 random
  /// points on every repaint.
  static final Map<int, ui.Image> _noiseTileCache = <int, ui.Image>{};

  static ui.Image _noiseTile(double dpr) {
    final key = (dpr * 100).round();
    return _noiseTileCache[key] ??= _generateNoiseTile(dpr);
  }

  static ui.Image _generateNoiseTile(double dpr) {
    const logicalSide = 64.0;
    final side = (logicalSide * dpr).round().clamp(32, 512);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final random = math.Random(42);
    final light = Paint()..color = const Color(0xFFFFFFFF);
    final dark = Paint()..color = const Color(0xFF000000);

    // One grain per ~20 logical px², matching the previous point density.
    // Grains are 1 physical pixel, snapped to the physical grid, so they
    // render identically on every backend and DPR (fractional sub-pixel
    // round points rendered inconsistently between Impeller and Skia).
    final count = (logicalSide * logicalSide / 20).round();
    for (var i = 0; i < count; i++) {
      final x = random.nextInt(side).toDouble();
      final y = random.nextInt(side).toDouble();
      canvas.drawRect(
        Rect.fromLTWH(x, y, 1, 1),
        random.nextBool() ? light : dark,
      );
    }

    final picture = recorder.endRecording();
    final image = picture.toImageSync(side, side);
    picture.dispose();
    return image;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = theme.borderRadius.toRRect(rect);

    // 1. Noise grain overlay — microscopic texture that prevents banding
    //    and makes the glass surface look physical. Drawn as a repeating
    //    pre-baked tile: a single textured quad instead of thousands of
    //    point draws per repaint.
    if (theme.noiseOpacity > 0) {
      final tile = _noiseTile(devicePixelRatio);
      final transform = Matrix4.diagonal3Values(
        1.0 / devicePixelRatio,
        1.0 / devicePixelRatio,
        1.0,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.ImageShader(
            tile,
            TileMode.repeated,
            TileMode.repeated,
            transform.storage,
          )
          // The color's alpha modulates the shader output.
          ..color = Color.fromRGBO(255, 255, 255, theme.noiseOpacity),
      );
    }

    // 2. Edge-lit gradient border — a hairline stroke with a LinearGradient
    //    from bright (top-left) to dark (bottom-right), simulating
    //    directional light catching the glass edge. The stroke width is
    //    snapped to a whole number of physical pixels so the hairline
    //    renders evenly on every DPR (a 0.75pt stroke maps to e.g. 1.97
    //    physical px on DPR 2.625 and looks ropey around corners).
    if (theme.borderWidth > 0) {
      final strokeWidth =
          math.max(
            1.0,
            (theme.borderWidth * devicePixelRatio).roundToDouble(),
          ) /
          devicePixelRatio;
      final borderRRect = rrect.deflate(strokeWidth / 2);
      canvas.drawRRect(
        borderRRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.edgeLightColor,
              Color.lerp(theme.edgeLightColor, theme.edgeShadowColor, 0.5)!,
              theme.edgeShadowColor,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_GlassForegroundPainter oldDelegate) =>
      theme != oldDelegate.theme ||
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
class LiquidGlassDetachedButton extends StatefulWidget {
  /// The icon or widget displayed inside the button.
  final Widget child;

  /// Called when the button is tapped.
  final VoidCallback? onTap;

  /// Diameter of the circular button. Defaults to 52 pt (matches bottom bar).
  final double size;

  /// When true, a subtle sweep gradient simulating prismatic light refraction
  /// is composited over the glass surface — matching the iridescent quality
  /// of iOS 26 detached buttons when placed over colorful content.
  final bool iridescent;

  /// Optional explicit glass theme. When null, a more transparent variant of
  /// the brightness-derived preset is used to let backdrop colors bleed through.
  final LiquidGlassThemeData? theme;

  /// When false, the button falls back to a solid Cupertino system-grey surface
  /// instead of the live backdrop-blur glass effect (the iridescent sweep is
  /// also suppressed in that mode). Defaults to true.
  final bool enableGlass;

  /// An optional label announced by screen readers (VoiceOver/TalkBack).
  final String? semanticLabel;

  /// Creates a [LiquidGlassDetachedButton].
  const LiquidGlassDetachedButton({
    super.key,
    required this.child,
    this.onTap,
    this.size = 52.0,
    this.iridescent = true,
    this.theme,
    this.enableGlass = true,
    this.semanticLabel,
  });

  @override
  State<LiquidGlassDetachedButton> createState() =>
      _LiquidGlassDetachedButtonState();
}

class _LiquidGlassDetachedButtonState extends State<LiquidGlassDetachedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  /// Latched in [build]; honored by the release animation.
  bool _reduceMotion = false;

  /// More transparent variants of the presets, hoisted so the button never
  /// allocates a theme during build (keeps painter shouldRepaint cheap).
  static final LiquidGlassThemeData _lightDetachedTheme =
      LiquidGlassThemeData.light().copyWith(tintOpacity: 0.28, blurSigma: 20.0);
  static final LiquidGlassThemeData _darkDetachedTheme =
      LiquidGlassThemeData.dark().copyWith(tintOpacity: 0.28, blurSigma: 20.0);

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) =>
      _press.animateTo(1.0, curve: Curves.easeIn);

  void _onTapUp(TapUpDetails _) {
    _release();
    widget.onTap?.call();
  }

  void _onTapCancel() => _release();

  void _release() => _press.animateTo(
    0.0,
    duration: _reduceMotion
        ? const Duration(milliseconds: 80)
        : const Duration(milliseconds: 420),
    curve: _reduceMotion ? Curves.easeOut : Curves.elasticOut,
  );

  @override
  Widget build(BuildContext context) {
    final brightness =
        CupertinoTheme.of(context).brightness ?? Brightness.light;
    final isDark = brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(widget.size / 2);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);

    final resolvedTheme =
        widget.theme ?? (isDark ? _darkDetachedTheme : _lightDetachedTheme);

    final glassButton = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          CupertinoLiquidGlass(
            theme: resolvedTheme,
            enabled: widget.enableGlass,
            borderRadius: borderRadius,
            width: widget.size,
            height: widget.size,
            child: Center(child: widget.child),
          ),
          // Iridescent sweep depends on backdrop sampling, so only render it
          // when the glass effect is active.
          if (widget.iridescent && widget.enableGlass)
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

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _press,
          // The pressed state is a scale plus a scrim painted *inside* the
          // glass. An Opacity widget here would force a saveLayer of the
          // whole backdrop-filtered subtree on every animation frame.
          builder: (context, child) {
            final t = _press.value;
            if (t == 0.0) return child!;
            return Transform.scale(
              scale: ui.lerpDouble(1.0, 0.88, t)!,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  child!,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: borderRadius,
                        child: ColoredBox(
                          color: Color.fromRGBO(0, 0, 0, 0.10 * t),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          child: glassButton,
        ),
      ),
    );
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

    canvas.drawOval(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(_IridescentPainter oldDelegate) =>
      isDark != oldDelegate.isDark;
}
