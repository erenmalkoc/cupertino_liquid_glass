import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'liquid_glass_theme.dart';

/// A widget that wraps its [child] in an Apple-style "Liquid Glass" surface.
///
/// [CupertinoLiquidGlass] applies a real-time backdrop blur that bends and
/// frosts the content behind it — closely matching the native iOS
/// `UIBlurEffect.systemMaterial` look and feel.
///
/// The widget automatically adapts to the ambient [CupertinoTheme] brightness,
/// switching between [LiquidGlassThemeData.light] and
/// [LiquidGlassThemeData.dark] presets when no explicit [theme] is provided.
///
/// ## Performance
///
/// A [RepaintBoundary] is inserted around the composited blur + tint layers
/// so that only this subtree is re-rasterized when the backdrop changes.
/// For best results on ProMotion (120 Hz) displays, avoid nesting multiple
/// [CupertinoLiquidGlass] widgets inside each other.
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

  /// Override the border color regardless of the resolved theme.
  final Color? borderColor;

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

  /// Creates a [CupertinoLiquidGlass] widget.
  const CupertinoLiquidGlass({
    super.key,
    required this.child,
    this.theme,
    this.blurSigma,
    this.tintOpacity,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.specularGradient,
    this.padding,
    this.width,
    this.height,
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
      borderColor: borderColor,
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
          boxShadow: resolved.shadows,
        ),
        child: ClipRRect(
          borderRadius: resolved.borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: resolved.blurSigma,
              sigmaY: resolved.blurSigma,
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

/// Internal widget that composites the tint, specular highlight, and border
/// layers on top of the already-blurred backdrop.
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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        // Tint layer — the primary coloured overlay.
        color: theme.tintColor.withValues(alpha: theme.tintOpacity),
        borderRadius: theme.borderRadius,
        // Border — subtle edge highlight.
        border: Border.all(
          color: theme.borderColor,
          width: theme.borderWidth,
        ),
        // Specular gradient — the "liquid" sheen.
        gradient: theme.specularGradient != null
            ? LinearGradient(
                begin: (theme.specularGradient as LinearGradient).begin,
                end: (theme.specularGradient as LinearGradient).end,
                colors: (theme.specularGradient as LinearGradient)
                    .colors
                    .map(
                      (c) => c.withValues(
                        alpha: c.a * theme.specularOpacity,
                      ),
                    )
                    .toList(),
                stops: (theme.specularGradient as LinearGradient).stops,
              )
            : null,
      ),
      child: child,
    );
  }
}
