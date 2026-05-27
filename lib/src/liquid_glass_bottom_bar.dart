import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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

/// Sliding window (ms) used to smooth the drag velocity for the stretch effect.
const int _kVelocityWindowMs = 90;

/// Pixel-distance below which a drag delta is treated as noise and skipped
/// for velocity sampling. Filters out trembling fingers and high-DPI jitter.
const double _kVelocityJitterPx = 0.4;

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

  /// Current fractional index (0.0 = first tab). Drives painter + tab styling.
  late final ValueNotifier<double> _position;

  /// Current velocity in fractional-index-per-second. Drives stretch only.
  late final ValueNotifier<double> _velocity;

  bool _isDragging = false;

  /// Sliding window of recent drag samples for velocity smoothing.
  final List<_VelocitySample> _velocitySamples = <_VelocitySample>[];

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
    final initial = widget.currentIndex.toDouble();
    _position = ValueNotifier<double>(initial);
    _velocity = ValueNotifier<double>(0.0);
    _controller = AnimationController.unbounded(vsync: this, value: initial)
      ..addListener(_onSpringTick);
    _elasticController =
        AnimationController.unbounded(vsync: this, value: 1.0);
  }

  @override
  void didUpdateWidget(CupertinoLiquidGlassBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      _animateTo(widget.currentIndex, initialVelocity: _velocity.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _elasticController.dispose();
    _position.dispose();
    _velocity.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Animation
  // ---------------------------------------------------------------------------

  /// Mirrors the spring controller's value into the [_position] /
  /// [_velocity] notifiers. No [setState] — listeners drive their own repaints.
  void _onSpringTick() {
    _position.value = _controller.value;
    _velocity.value = _controller.velocity;
  }

  void _animateTo(int index, {double initialVelocity = 0.0}) {
    _controller.animateWith(
      SpringSimulation(
        _spring,
        _position.value,
        index.toDouble(),
        initialVelocity,
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

    // CRITICAL: stop any in-flight spring so it doesn't fight the drag.
    // Without this, the controller's ticks keep overwriting `_position` on
    // every frame while the user drags, producing the "stuttering" feel.
    _controller.stop();

    _velocitySamples.clear();
    _velocity.value = 0.0;

    _elasticController.animateWith(
      SpringSimulation(
        _elasticSpring,
        _elasticController.value,
        _expandedScale,
        0.0,
      ),
    );
  }

  void _onDragUpdate(DragUpdateDetails details, double contentWidth) {
    final tabWidth = contentWidth / widget.items.length;
    final dx = details.delta.dx;
    final delta = dx / tabWidth;

    // Track samples for smoothed velocity. Skip sub-pixel jitter so the
    // stretch effect doesn't shimmer.
    final now = details.sourceTimeStamp?.inMicroseconds ??
        DateTime.now().microsecondsSinceEpoch;
    if (dx.abs() >= _kVelocityJitterPx) {
      _velocitySamples.add(_VelocitySample(now, delta));
      final cutoff = now - _kVelocityWindowMs * 1000;
      while (_velocitySamples.isNotEmpty &&
          _velocitySamples.first.timeUs < cutoff) {
        _velocitySamples.removeAt(0);
      }
    }

    _position.value =
        (_position.value + delta).clamp(0.0, _maxIndex.toDouble());

    // Smoothed velocity (fractional-index per second).
    if (_velocitySamples.length >= 2) {
      final spanUs =
          _velocitySamples.last.timeUs - _velocitySamples.first.timeUs;
      if (spanUs > 0) {
        final totalDelta = _velocitySamples.fold<double>(
          0.0,
          (sum, s) => sum + s.delta,
        );
        _velocity.value = totalDelta * 1e6 / spanUs;
      }
    } else {
      _velocity.value = 0.0;
    }
  }

  void _onDragEnd(DragEndDetails details, double contentWidth) {
    _isDragging = false;
    final tabWidth = contentWidth / widget.items.length;
    final flingVelocity = details.velocity.pixelsPerSecond.dx / tabWidth;

    int target = _position.value.round();
    if (flingVelocity.abs() > 3.0) {
      target = flingVelocity > 0 ? _position.value.ceil() : _position.value.floor();
    }
    target = target.clamp(0, _maxIndex);

    _velocitySamples.clear();
    widget.onTap?.call(target);

    // Hand the gesture's momentum to the spring so motion continues smoothly.
    _animateTo(target, initialVelocity: flingVelocity);

    _elasticController.animateWith(
      SpringSimulation(
        _elasticSpring,
        _elasticController.value,
        1.0,
        0.0,
      ),
    );
  }

  void _onDragCancel() {
    _isDragging = false;
    _velocitySamples.clear();
    // Snap back to the nearest tab if the gesture was interrupted.
    final target = _position.value.round().clamp(0, _maxIndex);
    _animateTo(target);
    _elasticController.animateWith(
      SpringSimulation(_elasticSpring, _elasticController.value, 1.0, 0.0),
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
              onHorizontalDragCancel: _onDragCancel,
              behavior: HitTestBehavior.opaque,
              // RepaintBoundary isolates the selector + tab item repaints
              // from the glass surface (noise, blur, edge light), which is
              // expensive to rasterize and only needs to repaint once.
              child: RepaintBoundary(
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
                      return Expanded(
                        child: _TabItem(
                          item: widget.items[i],
                          index: i,
                          position: _position,
                          activeColor: resolvedActive,
                          inactiveColor: resolvedInactive,
                          isDark: isDark,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Rubber banding (only the main strip, not the detached button).
    // AnimatedBuilder rebuilds only the Transform — `mainBar` stays cached.
    mainBar = AnimatedBuilder(
      animation: _elasticController,
      builder: (context, child) {
        final scale = _elasticController.value;
        if (scale == 1.0) return child!;
        return Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: mainBar,
    );

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

/// A single drag sample used for velocity smoothing.
class _VelocitySample {
  /// Monotonic timestamp in microseconds.
  final int timeUs;

  /// Fractional-index delta accumulated this frame.
  final double delta;

  const _VelocitySample(this.timeUs, this.delta);
}

/// Subscribes to the position notifier and rebuilds only its own subtree —
/// keeps the gesture detector, glass surface, and painter out of the rebuild.
class _TabItem extends StatelessWidget {
  final LiquidGlassBottomBarItem item;
  final int index;
  final ValueListenable<double> position;
  final Color activeColor;
  final Color inactiveColor;
  final bool isDark;

  const _TabItem({
    required this.item,
    required this.index,
    required this.position,
    required this.activeColor,
    required this.inactiveColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kMinHitTarget,
      child: ListenableBuilder(
        listenable: position,
        builder: (context, _) {
          final proximity =
              (1.0 - (position.value - index).abs()).clamp(0.0, 1.0);
          final color = Color.lerp(inactiveColor, activeColor, proximity)!;
          final iconData = proximity > 0.5
              ? (item.activeIcon ?? item.icon)
              : item.icon;
          final fontWeight = FontWeight.lerp(
            FontWeight.w400,
            FontWeight.w600,
            proximity,
          )!;
          // Dock-style magnification.
          final iconScale = 1.0 + proximity * 0.18;

          return Column(
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
                  activeColor: activeColor,
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
          );
        },
      ),
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
        ..color = const Color.fromRGBO(255, 255, 255, 1.0)
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
///
/// Subscribes directly to the position + velocity notifiers so it repaints
/// without rebuilding any widgets.
class _SelectorPainter extends CustomPainter {
  final ValueListenable<double> position;
  final ValueListenable<double> velocity;
  final int tabCount;
  final Color activeColor;
  final double selectorRadius;
  final bool isDark;

  _SelectorPainter({
    required this.position,
    required this.velocity,
    required this.tabCount,
    required this.activeColor,
    required this.selectorRadius,
    required this.isDark,
  }) : super(repaint: Listenable.merge([position, velocity]));

  @override
  void paint(Canvas canvas, Size size) {
    if (tabCount == 0) return;

    final pos = position.value;
    final vel = velocity.value;

    final tabWidth = size.width / tabCount;

    // Velocity-based stretch: faster movement -> wider pill.
    final absVel = vel.abs().clamp(0.0, 20.0);
    final stretch = 1.0 + absVel / 55.0; // max ~1.36x

    final baseWidth = tabWidth * 0.82;
    final selectorWidth = baseWidth * stretch;
    final x = pos * tabWidth + (tabWidth - selectorWidth) / 2;

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
      tabCount != old.tabCount ||
      activeColor != old.activeColor ||
      isDark != old.isDark;
}
