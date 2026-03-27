import 'dart:ui';

import 'package:flutter/cupertino.dart';

/// Theme configuration for the [CupertinoLiquidGlass] widget.
///
/// Defines all visual properties that control the appearance of the glass
/// effect, including blur intensity, tint color, border styling, and the
/// optional specular highlight gradient.
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

  /// The border color drawn around the glass surface.
  ///
  /// A subtle border helps the glass element "lift" from its background,
  /// especially against complex imagery.
  final Color borderColor;

  /// The width of the border drawn around the glass surface.
  final double borderWidth;

  /// An optional gradient that simulates a specular highlight (the "liquid"
  /// sheen that makes the glass feel alive).
  ///
  /// When null, no specular gradient is rendered.
  final Gradient? specularGradient;

  /// The opacity of the specular gradient overlay.
  final double specularOpacity;

  /// An optional shadow cast beneath the glass surface for depth.
  final List<BoxShadow>? shadows;

  /// Creates a [LiquidGlassThemeData] with fully custom values.
  const LiquidGlassThemeData({
    this.blurSigma = 28.0,
    this.tintColor = CupertinoColors.white,
    this.tintOpacity = 0.55,
    this.borderRadius = const BorderRadius.all(Radius.circular(20.0)),
    this.borderColor = const Color(0x40FFFFFF),
    this.borderWidth = 0.5,
    this.specularGradient,
    this.specularOpacity = 0.25,
    this.shadows,
  });

  /// A light-mode preset that matches iOS `UIBlurEffect.systemMaterial`.
  ///
  /// Produces a bright, matte glass surface with a subtle white tint and
  /// a soft specular highlight across the top edge.
  factory LiquidGlassThemeData.light() {
    return LiquidGlassThemeData(
      blurSigma: 28.0,
      tintColor: CupertinoColors.white,
      tintOpacity: 0.55,
      borderRadius: const BorderRadius.all(Radius.circular(20.0)),
      borderColor: const Color(0x40FFFFFF),
      borderWidth: 0.5,
      specularGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x40FFFFFF),
          Color(0x10FFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: [0.0, 0.4, 1.0],
      ),
      specularOpacity: 0.30,
      shadows: const [
        BoxShadow(
          color: Color(0x18000000),
          blurRadius: 24.0,
          spreadRadius: 0.0,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  /// A dark-mode preset that matches iOS `UIBlurEffect.systemMaterialDark`.
  ///
  /// Produces a deep, contrasty glass surface with a dark tint and a more
  /// pronounced specular highlight for legibility against dark backgrounds.
  factory LiquidGlassThemeData.dark() {
    return LiquidGlassThemeData(
      blurSigma: 32.0,
      tintColor: const Color(0xFF1C1C1E),
      tintOpacity: 0.62,
      borderRadius: const BorderRadius.all(Radius.circular(20.0)),
      borderColor: const Color(0x30FFFFFF),
      borderWidth: 0.5,
      specularGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x30FFFFFF),
          Color(0x0AFFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: [0.0, 0.35, 1.0],
      ),
      specularOpacity: 0.20,
      shadows: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 32.0,
          spreadRadius: 0.0,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  /// Returns a copy of this theme with the given fields replaced.
  LiquidGlassThemeData copyWith({
    double? blurSigma,
    Color? tintColor,
    double? tintOpacity,
    BorderRadius? borderRadius,
    Color? borderColor,
    double? borderWidth,
    Gradient? specularGradient,
    double? specularOpacity,
    List<BoxShadow>? shadows,
  }) {
    return LiquidGlassThemeData(
      blurSigma: blurSigma ?? this.blurSigma,
      tintColor: tintColor ?? this.tintColor,
      tintOpacity: tintOpacity ?? this.tintOpacity,
      borderRadius: borderRadius ?? this.borderRadius,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      specularGradient: specularGradient ?? this.specularGradient,
      specularOpacity: specularOpacity ?? this.specularOpacity,
      shadows: shadows ?? this.shadows,
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
    return LiquidGlassThemeData(
      blurSigma: lerpDouble(a.blurSigma, b.blurSigma, t) ?? a.blurSigma,
      tintColor: Color.lerp(a.tintColor, b.tintColor, t) ?? a.tintColor,
      tintOpacity:
          lerpDouble(a.tintOpacity, b.tintOpacity, t) ?? a.tintOpacity,
      borderRadius:
          BorderRadius.lerp(a.borderRadius, b.borderRadius, t) ??
          a.borderRadius,
      borderColor:
          Color.lerp(a.borderColor, b.borderColor, t) ?? a.borderColor,
      borderWidth:
          lerpDouble(a.borderWidth, b.borderWidth, t) ?? a.borderWidth,
      specularGradient:
          Gradient.lerp(a.specularGradient, b.specularGradient, t),
      specularOpacity:
          lerpDouble(a.specularOpacity, b.specularOpacity, t) ??
          a.specularOpacity,
      shadows: BoxShadow.lerpList(a.shadows ?? [], b.shadows ?? [], t),
    );
  }
}
