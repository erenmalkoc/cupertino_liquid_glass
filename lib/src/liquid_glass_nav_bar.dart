import 'package:flutter/cupertino.dart';

import 'cupertino_liquid_glass_widget.dart';
import 'liquid_glass_theme.dart';

/// Standard height for the glass pill content area, matching
/// the iOS navigation bar content height and [LiquidGlassDetachedButton]
/// default size so both elements stay vertically aligned.
const double _kNavBarContentHeight = 44.0;

/// A pre-built navigation bar wrapped in a [CupertinoLiquidGlass] surface.
///
/// This widget is designed to sit at the top of a [CustomScrollView] or
/// [CupertinoPageScaffold] and provide a frosted-glass header that blurs
/// the content scrolling beneath it — just like the native iOS navigation bar
/// in apps such as Safari and Messages.
///
/// An optional [detachedButton] can be supplied to render a floating circular
/// glass button separated from the main bar — matching the detached sidebar
/// button pattern seen in iOS 26 apps such as Apple News.
///
/// ## Example
///
/// ```dart
/// CupertinoLiquidGlassNavBar(
///   title: Text('Inbox'),
///   leading: CupertinoButton(
///     padding: EdgeInsets.zero,
///     onPressed: () => Navigator.pop(context),
///     child: Icon(CupertinoIcons.back),
///   ),
///   detachedButton: LiquidGlassDetachedButton(
///     onTap: () {},
///     child: Icon(CupertinoIcons.sidebar_left),
///   ),
/// )
/// ```
class CupertinoLiquidGlassNavBar extends StatelessWidget {
  /// The primary title displayed in the center of the bar.
  final Widget? title;

  /// A widget placed at the leading (left) edge, typically a back button.
  final Widget? leading;

  /// A widget placed at the trailing (right) edge, typically an action button.
  final Widget? trailing;

  /// Optional explicit theme override for the glass surface.
  final LiquidGlassThemeData? theme;

  /// The border radius of the glass surface.
  ///
  /// Defaults to a pill shape with 22 px radius.
  final BorderRadius? borderRadius;

  /// Horizontal margin around the glass bar.
  final double horizontalMargin;

  /// Whether to include the top safe-area padding (status bar inset).
  final bool useSafeArea;

  /// When false, the bar falls back to a solid Cupertino system-grey surface
  /// instead of the live backdrop-blur glass effect. Useful as a low-power
  /// fallback or design opt-out. Defaults to true.
  final bool enableGlass;

  /// How strongly the decorative glass layers are rendered (0.0–1.0).
  /// `0.0` gives a clean frosted surface (blur + tint only), `1.0` the full
  /// liquid-glass treatment. Forwarded to [CupertinoLiquidGlass.effectIntensity].
  final double effectIntensity;

  /// An optional floating circular glass button rendered to the right of the
  /// main bar, visually detached from it.
  ///
  /// Typically a [LiquidGlassDetachedButton].
  final Widget? detachedButton;

  /// Creates a [CupertinoLiquidGlassNavBar].
  const CupertinoLiquidGlassNavBar({
    super.key,
    this.title,
    this.leading,
    this.trailing,
    this.theme,
    this.borderRadius,
    this.horizontalMargin = 8.0,
    this.useSafeArea = true,
    this.enableGlass = true,
    this.effectIntensity = 1.0,
    this.detachedButton,
  });

  @override
  Widget build(BuildContext context) {
    // viewPaddingOf: aspect-scoped (a full MediaQuery.of dependency would
    // rebuild the glass bar on every keyboard-inset frame) and immune to
    // parent SafeArea/Scaffold consumers, matching the bottom bar.
    final topPadding = useSafeArea
        ? MediaQuery.viewPaddingOf(context).top
        : 0.0;

    final mainBar = CupertinoLiquidGlass(
      theme: theme,
      enabled: enableGlass,
      effectIntensity: effectIntensity,
      borderRadius:
          borderRadius ?? const BorderRadius.all(Radius.circular(22.0)),
      height: _kNavBarContentHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          ?leading,
          if (leading != null) const SizedBox(width: 8.0),
          Expanded(
            child: DefaultTextStyle.merge(
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
              textAlign: TextAlign.center,
              child: title != null
                  ? Semantics(header: true, child: title)
                  : const SizedBox.shrink(),
            ),
          ),
          if (trailing != null) const SizedBox(width: 8.0),
          ?trailing,
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding + 4.0,
        left: horizontalMargin,
        right: horizontalMargin,
      ),
      child: detachedButton != null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: mainBar),
                const SizedBox(width: 8.0),
                detachedButton!,
              ],
            )
          : mainBar,
    );
  }
}
