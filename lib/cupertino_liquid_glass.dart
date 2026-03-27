/// A premium Flutter package that replicates Apple's iOS Liquid Glass blur
/// and translucency design language.
///
/// The core widget, [CupertinoLiquidGlass], wraps any child in a frosted-glass
/// surface that dynamically adapts to light and dark themes while maintaining
/// smooth 120 Hz performance on ProMotion displays.
///
/// Pre-built convenience widgets are also provided:
///
/// * [CupertinoLiquidGlassNavBar] — a glass navigation bar for the top of the
///   screen.
/// * [CupertinoLiquidGlassBottomBar] — a glass tab bar for the bottom of the
///   screen.
///
/// ## Quick start
///
/// ```dart
/// import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';
///
/// CupertinoLiquidGlass(
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Hello, Glass!'),
///   ),
/// )
/// ```
library;

export 'src/cupertino_liquid_glass_widget.dart';
export 'src/liquid_glass_bottom_bar.dart';
export 'src/liquid_glass_nav_bar.dart';
export 'src/liquid_glass_theme.dart';
