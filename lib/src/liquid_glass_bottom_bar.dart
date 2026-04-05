import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';

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

/// Apple HIG standard tab bar height (excluding safe area).
const double _kTabBarHeight = 49.0;

/// Apple HIG minimum touch target size.
const double _kMinHitTarget = 44.0;

/// Apple HIG standard icon size for tab bars.
const double _kIconSize = 25.0;

/// Apple HIG standard label font size for tab bars.
const double _kLabelFontSize = 10.0;

/// A pre-built bottom tab bar wrapped in a [CupertinoLiquidGlass] surface,
/// featuring a sliding fluid indicator with spring physics.
///
/// Follows Apple HIG specifications:
/// * Bar height: 49 pt (+ 34 pt safe area on Face ID devices)
/// * Icon size: 25 pt
/// * Touch target: minimum 44x44 pt
/// * Horizontal distribution: equal width per tab
///
/// The selected tab is highlighted by a glass pill that slides between tabs
/// using [SpringSimulation] for a premium, bouncy feel. The indicator
/// stretches based on velocity during transitions and supports interactive
/// drag tracking — the user can swipe across the bar and the selector
/// follows the finger, magnetically snapping to the nearest tab on release.
///
/// ## Features
///
/// * **Spring animation** — [SpringSimulation] with configurable
///   [springDescription] for natural, bouncy transitions.
/// * **Velocity-based stretch** — the selector pill widens during fast
///   movement and contracts back when settling.
/// * **Interactive drag** — horizontal drag gesture moves the selector
///   in real-time; fling velocity influences the target tab.
/// * **Smooth color interpolation** — icon and label colors blend
///   continuously as the selector slides past them.
/// * **Bloom glow** — the selector casts a soft colored glow in the
///   [activeColor] onto the glass surface.
/// * **Scroll-aware resizing** — optional scroll-driven scale animation
///   with spring physics, shrinking to 85% when scrolling.
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
class CupertinoLiquidGlassBottomBar extends StatefulWidget {
  /// The tab items to display.
  final List<LiquidGlassBottomBarItem> items;

  /// The index of the currently selected tab.
  final int currentIndex;

  /// Called when the user taps a tab item or completes a drag gesture.
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

  /// The spring physics used for the sliding selector animation.
  ///
  /// Defaults to an Apple-like spring with ~0.35s response and 0.75
  /// damping fraction for a subtle overshoot.
  final SpringDescription? springDescription;

  /// An optional [ScrollController] to enable scroll-aware resizing.
  ///
  /// When provided, the bar scales down to 85% during active scrolling
  /// and springs back to full size when scrolling stops.
  final ScrollController? scrollController;

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
    this.springDescription,
    this.scrollController,
  });

  @override
  State<CupertinoLiquidGlassBottomBar> createState() =>
      _CupertinoLiquidGlassBottomBarState();
}

class _CupertinoLiquidGlassBottomBarState
    extends State<CupertinoLiquidGlassBottomBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _elasticController;

  /// Current fractional index of the selector (0.0 = first tab, etc.).
  double _position = 0.0;

  /// Current velocity in fractional-index-per-second units.
  double _velocity = 0.0;

  /// Whether the user is actively dragging.
  bool _isDragging = false;

  /// Current elastic scale factor (1.0 = rest, >1.0 = expanded).
  double _elasticScale = 1.0;

  /// Apple-like spring: ~0.35s response, 0.75 damping fraction.
  /// Reverse-engineered from SwiftUI spring(.bouncy) defaults.
  static const _defaultSpring = SpringDescription(
    mass: 1.0,
    stiffness: 320.0,
    damping: 22.0,
  );

  /// Spring for rubber banding (slight overshoot for elastic feel).
  static const _elasticSpring = SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 20.0,
  );

  /// Scale factor when bar is expanded during scroll.
  static const _expandedScale = 1.04;

  SpringDescription get _spring => widget.springDescription ?? _defaultSpring;

  int get _maxIndex => widget.items.length - 1;

  @override
  void initState() {
    super.initState();
    _position = widget.currentIndex.toDouble();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(_onTick);
    _elasticController = AnimationController.unbounded(vsync: this, value: 1.0)
      ..addListener(_onElasticTick);
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(CupertinoLiquidGlassBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      _animateTo(widget.currentIndex);
    }
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _controller.dispose();
    _elasticController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Animation
  // ---------------------------------------------------------------------------

  void _onTick() {
    setState(() {
      _position = _controller.value;
      _velocity = _controller.velocity;
    });
  }

  void _onElasticTick() {
    setState(() {
      _elasticScale = _elasticController.value;
    });
  }

  void _animateTo(int index) {
    _controller.animateWith(
      SpringSimulation(
        _spring,
        _position,
        index.toDouble(),
        _velocity,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Scroll-aware rubber banding (elasticity)
  // ---------------------------------------------------------------------------

  bool _isScrolling = false;

  void _onScroll() {
    final sc = widget.scrollController;
    if (sc == null || !sc.hasClients) return;

    if (!_isScrolling) {
      _isScrolling = true;
      // Expand bar with elastic spring.
      _elasticController.animateWith(
        SpringSimulation(
            _elasticSpring, _elasticScale, _expandedScale, 0.0),
      );
    }

    // Check to restore size when scrolling stops.
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      final currentSc = widget.scrollController;
      if (currentSc == null || !currentSc.hasClients) return;
      if (!currentSc.position.isScrollingNotifier.value) {
        _isScrolling = false;
        _elasticController.animateWith(
          SpringSimulation(_elasticSpring, _elasticScale, 1.0, 0.0),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Gestures
  // ---------------------------------------------------------------------------

  void _onTapUp(TapUpDetails details, double contentWidth) {
    final tabWidth = contentWidth / widget.items.length;
    final index =
        (details.localPosition.dx / tabWidth).floor().clamp(0, _maxIndex);

    widget.onTap?.call(index);
    _animateTo(index);
  }

  void _onDragUpdate(DragUpdateDetails details, double contentWidth) {
    final tabWidth = contentWidth / widget.items.length;
    final delta = details.delta.dx / tabWidth;
    setState(() {
      _isDragging = true;
      _position = (_position + delta).clamp(0.0, _maxIndex.toDouble());
      _velocity = delta * 60;
    });
  }

  void _onDragEnd(DragEndDetails details, double contentWidth) {
    _isDragging = false;
    final tabWidth = contentWidth / widget.items.length;
    final flingVelocity = details.velocity.pixelsPerSecond.dx / tabWidth;

    int target = _position.round();
    if (flingVelocity.abs() > 3.0) {
      target = flingVelocity > 0 ? _position.ceil() : _position.floor();
    }
    target = target.clamp(0, _maxIndex);

    _velocity = flingVelocity;
    widget.onTap?.call(target);
    _animateTo(target);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        widget.useSafeArea ? MediaQuery.of(context).padding.bottom : 0.0;
    final brightness =
        CupertinoTheme.of(context).brightness ?? Brightness.light;
    final isDark = brightness == Brightness.dark;

    final resolvedActive =
        widget.activeColor ?? CupertinoTheme.of(context).primaryColor;
    final resolvedInactive = widget.inactiveColor ??
        (isDark
            ? CupertinoColors.systemGrey
            : CupertinoColors.systemGrey2);

    Widget bar = Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding,
        left: widget.horizontalMargin,
        right: widget.horizontalMargin,
      ),
      child: CupertinoLiquidGlass(
        theme: widget.theme,
        borderRadius:
            widget.borderRadius ?? const BorderRadius.all(Radius.circular(26.0)),
        height: _kTabBarHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth;

            return GestureDetector(
              onTapUp: (d) => _onTapUp(d, contentWidth),
              onHorizontalDragUpdate: (d) =>
                  _onDragUpdate(d, contentWidth),
              onHorizontalDragEnd: (d) => _onDragEnd(d, contentWidth),
              behavior: HitTestBehavior.opaque,
              child: CustomPaint(
                painter: _SelectorPainter(
                  position: _position,
                  velocity: _velocity,
                  tabCount: widget.items.length,
                  activeColor: resolvedActive,
                  selectorRadius: 16.0,
                  isDark: isDark,
                ),
                child: Row(
                  children: List.generate(widget.items.length, (i) {
                    final item = widget.items[i];

                    final proximity =
                        (1.0 - (_position - i).abs()).clamp(0.0, 1.0);
                    final color = Color.lerp(
                      resolvedInactive,
                      resolvedActive,
                      proximity,
                    )!;
                    final iconData = proximity > 0.5
                        ? (item.activeIcon ?? item.icon)
                        : item.icon;
                    final fontWeight = FontWeight.lerp(
                      FontWeight.w400,
                      FontWeight.w600,
                      proximity,
                    )!;

                    return Expanded(
                      child: SizedBox(
                        height: _kMinHitTarget,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(iconData, color: color, size: _kIconSize),
                            const SizedBox(height: 1.0),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: _kLabelFontSize,
                                fontWeight: fontWeight,
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
          },
        ),
      ),
    );

    // Apply scroll-aware rubber banding (elastic scale).
    if (widget.scrollController != null && _elasticScale != 1.0) {
      bar = Transform.scale(
        scale: _elasticScale,
        alignment: Alignment.bottomCenter,
        child: bar,
      );
    }

    return bar;
  }
}

/// Paints the sliding glass selector pill behind the active tab icon.
///
/// The selector stretches horizontally based on [velocity] and casts a soft
/// bloom glow in [activeColor] onto the glass surface.
class _SelectorPainter extends CustomPainter {
  final double position;
  final double velocity;
  final int tabCount;
  final Color activeColor;
  final double selectorRadius;
  final bool isDark;

  const _SelectorPainter({
    required this.position,
    required this.velocity,
    required this.tabCount,
    required this.activeColor,
    required this.selectorRadius,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (tabCount == 0) return;

    final tabWidth = size.width / tabCount;

    // Velocity-based stretch: faster movement -> wider pill.
    final absVel = velocity.abs().clamp(0.0, 20.0);
    final stretch = 1.0 + absVel / 55.0; // max ~1.36x

    final baseWidth = tabWidth * 0.82;
    final selectorWidth = baseWidth * stretch;
    final x = position * tabWidth + (tabWidth - selectorWidth) / 2;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, 2.0, selectorWidth, size.height - 4.0),
      Radius.circular(selectorRadius),
    );

    // 1. Bloom glow — soft colored halo behind the selector.
    canvas.drawRRect(
      rrect.inflate(3.0),
      Paint()
        ..color = activeColor.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0),
    );

    // 2. Fill — subtle translucent pill.
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = isDark
            ? const Color.fromRGBO(255, 255, 255, 0.09)
            : const Color.fromRGBO(0, 0, 0, 0.05),
    );

    // 3. Inner highlight — a faint top edge for depth.
    canvas.drawRRect(
      rrect.deflate(0.25),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark
                ? const Color.fromRGBO(255, 255, 255, 0.18)
                : const Color.fromRGBO(255, 255, 255, 0.40),
            isDark
                ? const Color.fromRGBO(255, 255, 255, 0.04)
                : const Color.fromRGBO(0, 0, 0, 0.03),
          ],
        ).createShader(rrect.outerRect),
    );
  }

  @override
  bool shouldRepaint(_SelectorPainter old) =>
      position != old.position ||
      velocity != old.velocity ||
      tabCount != old.tabCount ||
      activeColor != old.activeColor ||
      isDark != old.isDark;
}
