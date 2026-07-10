import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// Theme configuration for [CupertinoLiquidGlass] and related widgets.
///
/// Defines all visual properties that control the glass effect appearance,
/// including blur intensity, tint, edge lighting, inner shadow, noise grain,
/// vibrancy boost, and the optional specular highlight gradient.
///
/// Use [LiquidGlassThemeData.light] and [LiquidGlassThemeData.dark] factory
/// constructors for Apple HIG-compliant presets that match iOS system materials.
class LiquidGlassThemeData {
  /// The sigma value for the Gaussian blur applied to the backdrop.
  ///
  /// Higher values produce a more diffused, frosted appearance.
  /// iOS system material typically uses values between 20 and 40.
  final double blurSigma;

  /// The background tint color overlaid on the blurred backdrop.
  ///
  /// This color is combined with [tintOpacity] to produce the translucent
  /// surface. In light mode, a bright white tint is typical; in dark mode,
  /// a near-black tint provides depth.
  final Color tintColor;

  /// The opacity of the [tintColor] overlay.
  ///
  /// Values range from 0.0 (fully transparent) to 1.0 (fully opaque).
  /// Typical iOS glass surfaces use 0.4–0.7 depending on the theme.
  final double tintOpacity;

  /// The corner radius applied to the glass container.
  final BorderRadius borderRadius;

  /// The highlight color on the top-left edge of the gradient border.
  ///
  /// Simulates specular light catching the top edge of the glass surface,
  /// producing the characteristic 3D edge-lit appearance.
  final Color edgeLightColor;

  /// The shadow color on the bottom-right edge of the gradient border.
  ///
  /// Provides the darker counterpart to [edgeLightColor], completing the
  /// directional lighting illusion on the border.
  final Color edgeShadowColor;

  /// The stroke width of the edge-lit gradient border.
  final double borderWidth;

  /// An optional gradient that simulates a specular highlight (the "liquid"
  /// sheen that makes the glass feel alive).
  ///
  /// When null, no specular gradient is rendered.
  final Gradient? specularGradient;

  /// The opacity of the specular gradient overlay.
  final double specularOpacity;

  /// The color of the inner shadow cast along the inside edges of the glass.
  ///
  /// This creates the subtle "carved out of glass" depth effect, making the
  /// surface feel recessed rather than flat.
  final Color innerShadowColor;

  /// The blur radius of the inner shadow.
  ///
  /// Controls how soft or hard the inner shadow edge appears. Values between
  /// 3.0 and 8.0 produce the most realistic glass depth.
  final double innerShadowBlurRadius;

  /// The opacity of the microscopic noise grain overlay (0.0–1.0).
  ///
  /// Premium Apple glass effects use a barely-visible noise texture to
  /// prevent color banding and make the surface look physical. Typical
  /// values are 0.02–0.04.
  final double noiseOpacity;

  /// The intensity of the vibrancy / saturation boost applied to the
  /// blurred backdrop (0.0–1.0).
  ///
  /// Simulates Apple's vibrancy effect where the blurred background colors
  /// are perceptually boosted before the tint is applied. Implemented as a
  /// saturation [ColorFilter] composed into the backdrop blur pass —
  /// matching UIKit's saturate-then-blur material recipe with no extra
  /// blend layer cost.
  final double vibrancyIntensity;

  /// An optional shadow cast beneath the glass surface for depth.
  final List<BoxShadow>? shadows;

  /// Creates a [LiquidGlassThemeData] with fully custom values.
  const LiquidGlassThemeData({
    this.blurSigma = 25.0,
    this.tintColor = CupertinoColors.white,
    this.tintOpacity = 0.65,
    this.borderRadius = const BorderRadius.all(Radius.circular(20.0)),
    this.edgeLightColor = const Color(0x38FFFFFF),
    this.edgeShadowColor = const Color(0x10000000),
    this.borderWidth = 0.75,
    this.specularGradient,
    this.specularOpacity = 0.15,
    this.innerShadowColor = const Color(0x14000000),
    this.innerShadowBlurRadius = 4.0,
    this.noiseOpacity = 0.015,
    this.vibrancyIntensity = 0.09,
    this.shadows,
  });

  /// A light-mode preset that matches iOS `UIBlurEffect.systemMaterial`.
  ///
  /// Produces a bright, matte glass surface with edge lighting, subtle inner
  /// shadow, noise grain, and a soft specular highlight across the top edge.
  ///
  /// Returns a canonical const instance, so repeated calls are `identical`
  /// and painter `shouldRepaint` checks short-circuit across rebuilds.
  factory LiquidGlassThemeData.light() => _lightPreset;

  /// A dark-mode preset that matches iOS `UIBlurEffect.systemMaterialDark`.
  ///
  /// Produces a deep, contrasty glass surface with stronger edge lighting,
  /// pronounced inner shadow, and enhanced vibrancy for legibility against
  /// dark backgrounds.
  ///
  /// Returns a canonical const instance, so repeated calls are `identical`
  /// and painter `shouldRepaint` checks short-circuit across rebuilds.
  factory LiquidGlassThemeData.dark() => _darkPreset;

  // Preset decoration levels are deliberately restrained: real iOS system
  // materials have no diagonal sheen, only a barely-there edge treatment.
  // Anything stronger reads as "fake glass" over rich content.
  static const LiquidGlassThemeData _lightPreset = LiquidGlassThemeData(
    blurSigma: 25.0,
    tintColor: CupertinoColors.white,
    tintOpacity: 0.65,
    borderRadius: BorderRadius.all(Radius.circular(20.0)),
    edgeLightColor: Color(0x40FFFFFF),
    edgeShadowColor: Color(0x08000000),
    borderWidth: 0.75,
    specularGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x40FFFFFF), Color(0x10FFFFFF), Color(0x00FFFFFF)],
      stops: [0.0, 0.4, 1.0],
    ),
    specularOpacity: 0.14,
    innerShadowColor: Color(0x0F000000),
    innerShadowBlurRadius: 3.0,
    noiseOpacity: 0.012,
    vibrancyIntensity: 0.08,
    shadows: [
      BoxShadow(
        color: Color(0x1A000000),
        blurRadius: 24.0,
        spreadRadius: 0.0,
        offset: Offset(0, 8),
      ),
    ],
  );

  static const LiquidGlassThemeData _darkPreset = LiquidGlassThemeData(
    blurSigma: 28.0,
    tintColor: Color(0xFF1C1C1E),
    tintOpacity: 0.55,
    borderRadius: BorderRadius.all(Radius.circular(20.0)),
    edgeLightColor: Color(0x2AFFFFFF),
    edgeShadowColor: Color(0x20000000),
    borderWidth: 0.75,
    specularGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x35FFFFFF), Color(0x0CFFFFFF), Color(0x00FFFFFF)],
      stops: [0.0, 0.35, 1.0],
    ),
    specularOpacity: 0.10,
    innerShadowColor: Color(0x1C000000),
    innerShadowBlurRadius: 5.0,
    noiseOpacity: 0.018,
    vibrancyIntensity: 0.10,
    shadows: [
      BoxShadow(
        color: Color(0x50000000),
        blurRadius: 32.0,
        spreadRadius: 0.0,
        offset: Offset(0, 10),
      ),
    ],
  );

  /// Returns a copy of this theme with the given fields replaced.
  LiquidGlassThemeData copyWith({
    double? blurSigma,
    Color? tintColor,
    double? tintOpacity,
    BorderRadius? borderRadius,
    Color? edgeLightColor,
    Color? edgeShadowColor,
    double? borderWidth,
    Gradient? specularGradient,
    double? specularOpacity,
    Color? innerShadowColor,
    double? innerShadowBlurRadius,
    double? noiseOpacity,
    double? vibrancyIntensity,
    List<BoxShadow>? shadows,
  }) {
    if (blurSigma == null &&
        tintColor == null &&
        tintOpacity == null &&
        borderRadius == null &&
        edgeLightColor == null &&
        edgeShadowColor == null &&
        borderWidth == null &&
        specularGradient == null &&
        specularOpacity == null &&
        innerShadowColor == null &&
        innerShadowBlurRadius == null &&
        noiseOpacity == null &&
        vibrancyIntensity == null &&
        shadows == null) {
      return this;
    }
    return LiquidGlassThemeData(
      blurSigma: blurSigma ?? this.blurSigma,
      tintColor: tintColor ?? this.tintColor,
      tintOpacity: tintOpacity ?? this.tintOpacity,
      borderRadius: borderRadius ?? this.borderRadius,
      edgeLightColor: edgeLightColor ?? this.edgeLightColor,
      edgeShadowColor: edgeShadowColor ?? this.edgeShadowColor,
      borderWidth: borderWidth ?? this.borderWidth,
      specularGradient: specularGradient ?? this.specularGradient,
      specularOpacity: specularOpacity ?? this.specularOpacity,
      innerShadowColor: innerShadowColor ?? this.innerShadowColor,
      innerShadowBlurRadius:
          innerShadowBlurRadius ?? this.innerShadowBlurRadius,
      noiseOpacity: noiseOpacity ?? this.noiseOpacity,
      vibrancyIntensity: vibrancyIntensity ?? this.vibrancyIntensity,
      shadows: shadows ?? this.shadows,
    );
  }

  /// Returns a copy with all *decorative* layers scaled by [factor]
  /// (clamped to 0.0–1.0): specular sheen, edge lighting, inner shadow,
  /// noise grain, and vibrancy.
  ///
  /// The material itself — [blurSigma], [tintColor]/[tintOpacity], shape and
  /// drop [shadows] — is left untouched, so `scaleEffects(0.0)` yields a
  /// clean iOS-style frosted surface (blur + tint only) and `1.0` returns
  /// `this` unchanged. This powers the `effectIntensity` parameter on the
  /// glass widgets.
  LiquidGlassThemeData scaleEffects(double factor) {
    final f = factor.clamp(0.0, 1.0);
    if (f >= 1.0) return this;
    return copyWith(
      specularOpacity: specularOpacity * f,
      edgeLightColor: edgeLightColor.withValues(alpha: edgeLightColor.a * f),
      edgeShadowColor: edgeShadowColor.withValues(alpha: edgeShadowColor.a * f),
      innerShadowColor: innerShadowColor.withValues(
        alpha: innerShadowColor.a * f,
      ),
      noiseOpacity: noiseOpacity * f,
      vibrancyIntensity: vibrancyIntensity * f,
    );
  }

  /// Linearly interpolates between two [LiquidGlassThemeData] instances.
  ///
  /// Useful for animated theme transitions (e.g. light-to-dark crossfade).
  static LiquidGlassThemeData lerp(
    LiquidGlassThemeData a,
    LiquidGlassThemeData b,
    double t,
  ) {
    if (identical(a, b)) return a;
    if (t == 0.0) return a;
    if (t == 1.0) return b;
    return LiquidGlassThemeData(
      blurSigma: lerpDouble(a.blurSigma, b.blurSigma, t) ?? a.blurSigma,
      tintColor: Color.lerp(a.tintColor, b.tintColor, t) ?? a.tintColor,
      tintOpacity: lerpDouble(a.tintOpacity, b.tintOpacity, t) ?? a.tintOpacity,
      borderRadius:
          BorderRadius.lerp(a.borderRadius, b.borderRadius, t) ??
          a.borderRadius,
      edgeLightColor:
          Color.lerp(a.edgeLightColor, b.edgeLightColor, t) ?? a.edgeLightColor,
      edgeShadowColor:
          Color.lerp(a.edgeShadowColor, b.edgeShadowColor, t) ??
          a.edgeShadowColor,
      borderWidth: lerpDouble(a.borderWidth, b.borderWidth, t) ?? a.borderWidth,
      specularGradient: Gradient.lerp(
        a.specularGradient,
        b.specularGradient,
        t,
      ),
      specularOpacity:
          lerpDouble(a.specularOpacity, b.specularOpacity, t) ??
          a.specularOpacity,
      innerShadowColor:
          Color.lerp(a.innerShadowColor, b.innerShadowColor, t) ??
          a.innerShadowColor,
      innerShadowBlurRadius:
          lerpDouble(a.innerShadowBlurRadius, b.innerShadowBlurRadius, t) ??
          a.innerShadowBlurRadius,
      noiseOpacity:
          lerpDouble(a.noiseOpacity, b.noiseOpacity, t) ?? a.noiseOpacity,
      vibrancyIntensity:
          lerpDouble(a.vibrancyIntensity, b.vibrancyIntensity, t) ??
          a.vibrancyIntensity,
      shadows: (a.shadows == null && b.shadows == null)
          ? null
          : BoxShadow.lerpList(a.shadows ?? const [], b.shadows ?? const [], t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiquidGlassThemeData &&
        other.blurSigma == blurSigma &&
        other.tintColor == tintColor &&
        other.tintOpacity == tintOpacity &&
        other.borderRadius == borderRadius &&
        other.edgeLightColor == edgeLightColor &&
        other.edgeShadowColor == edgeShadowColor &&
        other.borderWidth == borderWidth &&
        other.specularGradient == specularGradient &&
        other.specularOpacity == specularOpacity &&
        other.innerShadowColor == innerShadowColor &&
        other.innerShadowBlurRadius == innerShadowBlurRadius &&
        other.noiseOpacity == noiseOpacity &&
        other.vibrancyIntensity == vibrancyIntensity &&
        listEquals(other.shadows, shadows);
  }

  @override
  int get hashCode => Object.hash(
    blurSigma,
    tintColor,
    tintOpacity,
    borderRadius,
    edgeLightColor,
    edgeShadowColor,
    borderWidth,
    specularGradient,
    specularOpacity,
    innerShadowColor,
    innerShadowBlurRadius,
    noiseOpacity,
    vibrancyIntensity,
    shadows == null ? null : Object.hashAll(shadows!),
  );
}
