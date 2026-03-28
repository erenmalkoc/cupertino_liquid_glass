import 'package:flutter/cupertino.dart';

import 'cupertino_liquid_glass_widget.dart';
import 'liquid_glass_theme.dart';

/// A single item displayed inside a [CupertinoLiquidGlassBottomBar].
class LiquidGlassBottomBarItem {
  /// The icon shown when this item is **not** selected.
  final IconData icon;

  /// The icon shown when this item **is** selected.
  /// Falls back to [icon] when null.
  final IconData? activeIcon;

  /// The label displayed below the icon.
  final String label;

  /// Creates a [LiquidGlassBottomBarItem].
  const LiquidGlassBottomBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// A pre-built bottom tab bar wrapped in a [CupertinoLiquidGlass] surface.
///
/// Mirrors the look and feel of the iOS 26 tab bar with frosted-glass backdrop,
/// edge lighting, inner shadow depth, and a [LiquidGlassBloom] glow on the
/// active tab that spills soft colored light onto the glass surface.
///
/// ## Example
///
/// ```dart
/// CupertinoLiquidGlassBottomBar(
///   currentIndex: _selectedTab,
///   onTap: (i) => setState(() => _selectedTab = i),
///   items: const [
///     LiquidGlassBottomBarItem(icon: CupertinoIcons.house_fill, label: 'Home'),
///     LiquidGlassBottomBarItem(icon: CupertinoIcons.search, label: 'Search'),
///     LiquidGlassBottomBarItem(icon: CupertinoIcons.settings, label: 'Settings'),
///   ],
/// )
/// ```
class CupertinoLiquidGlassBottomBar extends StatelessWidget {
  /// The tab items to display.
  final List<LiquidGlassBottomBarItem> items;

  /// The index of the currently selected tab.
  final int currentIndex;

  /// Called when the user taps a tab item.
  final ValueChanged<int>? onTap;

  /// Optional explicit theme override for the glass surface.
  final LiquidGlassThemeData? theme;

  /// The border radius of the glass surface.
  final BorderRadius? borderRadius;

  /// Horizontal margin around the glass bar.
  final double horizontalMargin;

  /// Whether to include the bottom safe-area padding (home indicator inset).
  final bool useSafeArea;

  /// The color used for the active (selected) tab icon and label.
  final Color? activeColor;

  /// The color used for inactive tab icons and labels.
  final Color? inactiveColor;

  /// Creates a [CupertinoLiquidGlassBottomBar].
  const CupertinoLiquidGlassBottomBar({
    super.key,
    required this.items,
    this.currentIndex = 0,
    this.onTap,
    this.theme,
    this.borderRadius,
    this.horizontalMargin = 8.0,
    this.useSafeArea = true,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        useSafeArea ? MediaQuery.of(context).padding.bottom : 0.0;
    final brightness =
        CupertinoTheme.of(context).brightness ?? Brightness.light;

    final resolvedActive =
        activeColor ?? CupertinoTheme.of(context).primaryColor;
    final resolvedInactive =
        inactiveColor ??
        (brightness == Brightness.dark
            ? CupertinoColors.systemGrey
            : CupertinoColors.systemGrey2);

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding + 4.0,
        left: horizontalMargin,
        right: horizontalMargin,
      ),
      child: CupertinoLiquidGlass(
        theme: theme,
        borderRadius:
            borderRadius ?? const BorderRadius.all(Radius.circular(26.0)),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isActive = index == currentIndex;
            final color = isActive ? resolvedActive : resolvedInactive;
            final iconData =
                isActive ? (item.activeIcon ?? item.icon) : item.icon;

            final icon = Icon(iconData, color: color, size: 24.0);

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap?.call(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive)
                      LiquidGlassBloom(
                        color: resolvedActive,
                        radius: 16.0,
                        spread: 6.0,
                        intensity: 0.45,
                        child: icon,
                      )
                    else
                      icon,
                    const SizedBox(height: 2.0),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10.0,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
