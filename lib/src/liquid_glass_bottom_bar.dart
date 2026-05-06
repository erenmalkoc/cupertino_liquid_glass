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

/// Tab bar height (excluding safe area).
const double _kTabBarHeight = 56.0;

/// Minimum touch target size.
const double _kMinHitTarget = 48.0;

/// Icon size for tab bars.
const double _kIconSize = 28.0;

/// Label font size for tab bars.
const double _kLabelFontSize = 11.0;

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
/// * **Rubber banding** — the bar scales up elastically during horizontal
///   drag and springs back to rest when released.
/// * **Smooth color interpolation** — icon and label colors blend
///   continuously as the selector slides past them.
/// * **Bloom glow** — the selector casts a soft colored glow in the
///   [activeColor] onto the glass surface.
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

  /// An optional floating circular glass button rendered to the right of the
  /// main bar, visually detached from it.
  ///
  /// Rubber banding applies only to the main tab strip; the detached button
  /// stays fixed during drag gestures.
  ///
  /// Typically a [LiquidGlassDetachedButton].
  final Widget? detachedButton;

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
    this.detachedButton,
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

  /// Scale factor when bar is expanded during drag.
  static const _expandedScale = 1.08;

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
  }

  @override
  void didUpdateWidget(CupertinoLiquidGlassBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      _animateTo(widget.currentIndex);
    }
  }

  @override
  void dispose() {
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
  // Gestures
  // ---------------------------------------------------------------------------

  void _onTapUp(TapUpDetails details, double contentWidth) {
    final tabWidth = contentWidth / widget.items.length;
    final index =
        (details.localPosition.dx / tabWidth).floor().clamp(0, _maxIndex);

    widget.onTap?.call(index);
    _animateTo(index);
  }

  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
    // Rubber band: expand bar on drag start.
    _elasticController.animateWith(
      SpringSimulation(_elasticSpring, _elasticScale, _expandedScale, 0.0),
    );
  }

  void _onDragUpdate(DragUpdateDetails details, double contentWidth) {
    final tabWidth = contentWidth / widget.items.length;
    final delta = details.delta.dx / tabWidth;
    setState(() {
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

    // Rubber band: spring back to rest on release.
    _elasticController.animateWith(
      SpringSimulation(_elasticSpring, _elasticScale, 1.0, 0.0),
    );
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

    // Main glass bar (without outer padding so rubber banding only affects it).
    Widget mainBar = CupertinoLiquidGlass(
      theme: widget.theme,
      borderRadius:
          widget.borderRadius ?? const BorderRadius.all(Radius.circular(26.0)),
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: _kTabBarHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth;

            return GestureDetector(
              onTapUp: (d) => _onTapUp(d, contentWidth),
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: (d) => _onDragUpdate(d, contentWidth),
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

                    // Dock-style magnification: icons scale up as
                    // the selector approaches.
                    final iconScale = 1.0 + proximity * 0.18;

                    return Expanded(
                      child: SizedBox(
                        height: _kMinHitTarget,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.scale(
                              scale: iconScale,
                              child: _GlassIcon(
                                icon: iconData,
                                color: color,
                                size: _kIconSize,
                                glassIntensity: proximity,
                                activeColor: resolvedActive,
                                isDark: isDark,
                              ),
                            ),
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

    // Rubber banding applies only to the main tab strip.
    if (_elasticScale != 1.0) {
      mainBar = Transform.scale(
        scale: _elasticScale,
        alignment: Alignment.bottomCenter,
        child: mainBar,
      );
    }

    final content = widget.detachedButton != null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: mainBar),
              const SizedBox(width: 8.0),
              widget.detachedButton!,
            ],
          )
        : mainBar;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding,
        left: widget.horizontalMargin,
        right: widget.horizontalMargin,
      ),
      child: content,
    );
  }
}

/// An icon with a glass refraction glow that intensifies based on
/// [glassIntensity] (0.0 = no effect, 1.0 = full glass).
class _GlassIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double glassIntensity;
  final Color activeColor;
  final bool isDark;

  const _GlassIcon({
    required this.icon,
    required this.color,
    required this.size,
    required this.glassIntensity,
    required this.activeColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlassIconPainter(
        intensity: glassIntensity,
        activeColor: activeColor,
        isDark: isDark,
        size: size,
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}

/// Paints a soft glass refraction halo behind the icon.
class _GlassIconPainter extends CustomPainter {
  final double intensity;
  final Color activeColor;
  final bool isDark;
  final double size;

  const _GlassIconPainter({
    required this.intensity,
    required this.activeColor,
    required this.isDark,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (intensity < 0.05) return;

    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = size * 0.55;

    // Outer colored glow.
    canvas.drawCircle(
      center,
      radius * (1.0 + intensity * 0.3),
      Paint()
        ..color = activeColor.withValues(alpha: intensity * 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 + intensity * 4.0),
    );

    // Inner glass highlight — bright specular dot.
    canvas.drawCircle(
      center.translate(0, -radius * 0.15),
      radius * 0.5 * intensity,
      Paint()
        ..color = (isDark
                ? const Color.fromRGBO(255, 255, 255, 1.0)
                : const Color.fromRGBO(255, 255, 255, 1.0))
            .withValues(alpha: intensity * 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 + intensity * 2.0),
    );
  }

  @override
  bool shouldRepaint(_GlassIconPainter old) =>
      intensity != old.intensity ||
      activeColor != old.activeColor ||
      isDark != old.isDark;
}

/// Paints the sliding glass selector pill behind the active tab icon.
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
