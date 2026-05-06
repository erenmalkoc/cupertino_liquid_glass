import 'package:flutter/cupertino.dart';

import 'cupertino_liquid_glass_widget.dart';
import 'liquid_glass_theme.dart';

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
    this.detachedButton,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding =
        useSafeArea ? MediaQuery.of(context).padding.top : 0.0;

    final mainBar = CupertinoLiquidGlass(
      theme: theme,
      borderRadius:
          borderRadius ?? const BorderRadius.all(Radius.circular(22.0)),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          ?leading,
          if (leading != null) const SizedBox(width: 8.0),
          Expanded(
            child: DefaultTextStyle.merge(
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
              textAlign: TextAlign.center,
              child: title ?? const SizedBox.shrink(),
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
