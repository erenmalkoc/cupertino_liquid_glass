import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

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

  /// Optional replacement for the icon glyph — e.g. a live user avatar.
  /// Called with the tab's current tint [Color] (already interpolated
  /// between inactive/active) and the Apple HIG icon size, so custom
  /// content can echo the bar's selection styling. Falls back to
  /// [icon]/[activeIcon] when null.
  final Widget Function(BuildContext context, Color color, double size)?
  iconBuilder;

  /// Creates a [LiquidGlassBottomBarItem].
  const LiquidGlassBottomBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.iconBuilder,
  });
}

/// Tab bar height (excluding safe area).
const double _kTabBarHeight = 52.0;

/// Minimum touch target size (Apple HIG minimum).
const double _kMinHitTarget = 44.0;

/// Icon size for tab bars (Apple HIG standard).
const double _kIconSize = 25.0;

/// Label font size for tab bars.
const double _kLabelFontSize = 10.0;

/// How far the label may shrink to fit the selector pill before it is left to
/// ellipsize instead — below this it stops reading as a label.
const double _kMinLabelFontSize = 7.5;

/// Breathing room between the label and the selector pill's edge.
const double _kLabelPadding = 3.0;

/// The selector pill's width as a fraction of a tab.
const double _kSelectorWidthFactor = 0.88;

/// Fraction of the corner radius used as the tab strip's horizontal inset,
/// and the ceiling it is clamped to. Roughly the horizontal distance the
/// corner arc travels across the label row.
const double _kItemInsetRatio = 0.45;
const double _kMaxItemInset = 14.0;

/// Sliding window (ms) used to smooth the drag velocity for the stretch effect.
const int _kVelocityWindowMs = 90;

/// Pixel-distance below which a drag delta is treated as noise and skipped
/// for velocity sampling. Filters out trembling fingers and high-DPI jitter.
const double _kVelocityJitterPx = 0.4;

/// A pre-built bottom tab bar wrapped in a [CupertinoLiquidGlass] surface,
/// featuring a sliding fluid indicator with spring physics.
///
/// Follows Apple HIG specifications:
/// * Bar height: 52 pt (+ 34 pt safe area on Face ID devices)
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

  /// Horizontal inset between the glass edge and the tab strip.
  ///
  /// The bar's rounded ends curve inwards exactly where the first and last
  /// tab's label sits, so a wide label (or a stretched selector pill) crosses
  /// the border and reads as overflow. Insetting the strip keeps every tab
  /// clear of the corner arc.
  ///
  /// When null (the default) the inset is derived from the corner radius, so
  /// a square-cornered bar keeps its full width.
  final double? itemInset;

  /// Whether to include the bottom safe-area padding (home indicator inset).
  final bool useSafeArea;

  /// When false, the bar falls back to a solid Cupertino system-grey surface
  /// instead of the live backdrop-blur glass effect. Useful as a low-power
  /// fallback or design opt-out. Defaults to true.
  final bool enableGlass;

  /// Extra vertical space inserted between the bar and the system inset.
  ///
  /// When null (the default), the bar adds a small platform-aware clearance:
  /// 6 dp on Android (where the gesture handle area is much thinner than
  /// iOS's home indicator zone, causing the bar to feel cramped against the
  /// system gesture line) and 0 elsewhere. Set this explicitly to override.
  final double? bottomSpacing;

  /// The color used for the active (selected) tab icon and label.
  final Color? activeColor;

  /// The color used for inactive tab icons and labels.
  final Color? inactiveColor;

  /// The spring physics used for the sliding selector animation.
  ///
  /// Defaults to an Apple-like spring with ~0.35s response and 0.75
  /// damping fraction for a subtle overshoot.
  final SpringDescription? springDescription;

  /// Whether to fire a selection haptic ([HapticFeedback.selectionClick])
  /// when the selected tab changes — matching the native iOS tab bar's
  /// `UISelectionFeedbackGenerator` behavior. Defaults to true.
  final bool enableHaptics;

  /// How strongly the decorative glass layers are rendered (0.0–1.0).
  /// `0.0` gives a clean frosted surface (blur + tint only), `1.0` the full
  /// liquid-glass treatment. Forwarded to [CupertinoLiquidGlass.effectIntensity].
  final double effectIntensity;

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
    this.itemInset,
    this.useSafeArea = true,
    this.enableGlass = true,
    this.bottomSpacing,
    this.activeColor,
    this.inactiveColor,
    this.springDescription,
    this.enableHaptics = true,
    this.effectIntensity = 1.0,
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

  /// One quantized proximity notifier per tab, derived from [_position].
  ///
  /// Each tab item listens only to its own notifier, so tabs whose proximity
  /// did not change this frame (anything more than one index away from the
  /// selector) never rebuild during drags or spring settles.
  List<ValueNotifier<double>> _proximities = <ValueNotifier<double>>[];

  bool _isDragging = false;

  /// Latched in [build]; when true, springs and rubber banding are skipped.
  bool _reduceMotion = false;

  /// Sliding window of recent drag samples for velocity smoothing.
  /// A [Queue] so pruning old samples from the front is O(1).
  final Queue<_VelocitySample> _velocitySamples = Queue<_VelocitySample>();

  /// True while the selector has been pre-moved by a touch-down that has not
  /// yet been committed (tap-up) or taken over by a drag. Used to revert the
  /// pill if the gesture is lost to a parent recognizer.
  bool _pendingPreMove = false;

  /// Last index a selection haptic was fired for during the current drag,
  /// so crossing a tab boundary ticks once — like UISegmentedControl.
  int _lastHapticIndex = 0;

  /// Monotonic fallback clock for velocity samples. Never mixed with
  /// [DragUpdateDetails.sourceTimeStamp] within a single gesture — the two
  /// are unrelated clock domains and mixing them corrupts the smoothed
  /// velocity (the pill stretch then flickers on affected devices).
  final Stopwatch _dragClock = Stopwatch()..start();

  /// Whether the current gesture uses sourceTimeStamp or the fallback clock.
  bool _useSourceTimeStamp = true;

  /// Apple-like spring: ~0.35s response, 0.75 damping fraction.
  static const _defaultSpring = SpringDescription(
    mass: 1.0,
    stiffness: 320.0,
    damping: 22.0,
  );

  /// Spring for rubber banding (slight overshoot for elastic feel).
  ///
  /// Deliberately stiff: while this spring runs, a [Transform] above the
  /// bar's [BackdropFilter] forces a full backdrop re-blur every frame, so
  /// a shorter settle (~0.3s vs ~0.45s) directly cuts the most expensive
  /// per-frame window in the widget without losing the bounce.
  static const _elasticSpring = SpringDescription(
    mass: 1.0,
    stiffness: 420.0,
    damping: 24.0,
  );

  /// Scale factor when bar is expanded during drag.
  static const _expandedScale = 1.08;

  SpringDescription get _spring => widget.springDescription ?? _defaultSpring;

  int get _maxIndex => widget.items.length - 1;

  @override
  void initState() {
    super.initState();
    final initial = widget.currentIndex.toDouble();
    _position = ValueNotifier<double>(initial)..addListener(_syncProximities);
    _velocity = ValueNotifier<double>(0.0);
    _rebuildProximities();
    _controller = AnimationController.unbounded(vsync: this, value: initial)
      ..addListener(_onSpringTick);
    _elasticController = AnimationController.unbounded(vsync: this, value: 1.0);
  }

  @override
  void didUpdateWidget(CupertinoLiquidGlassBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _rebuildProximities();
    }
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
    for (final p in _proximities) {
      p.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Animation
  // ---------------------------------------------------------------------------

  /// Proximity of tab [index] to the selector, quantized to 1/128 so
  /// imperceptible sub-steps near settle don't trigger rebuilds.
  double _proximityFor(int index, double pos) =>
      (((1.0 - (pos - index).abs()).clamp(0.0, 1.0)) * 128).round() / 128;

  void _rebuildProximities() {
    final old = _proximities;
    final pos = _position.value;
    _proximities = List<ValueNotifier<double>>.generate(
      widget.items.length,
      (i) => i < old.length
          ? (old[i]..value = _proximityFor(i, pos))
          : ValueNotifier<double>(_proximityFor(i, pos)),
    );
    for (var i = _proximities.length; i < old.length; i++) {
      old[i].dispose();
    }
  }

  /// Pushes the current position into the per-tab proximity notifiers.
  /// ValueNotifier skips notification when the value is unchanged, so only
  /// tabs whose proximity actually moved rebuild.
  void _syncProximities() {
    final pos = _position.value;
    for (var i = 0; i < _proximities.length; i++) {
      _proximities[i].value = _proximityFor(i, pos);
    }
  }

  /// Mirrors the spring controller's value into the [_position] /
  /// [_velocity] notifiers. No [setState] — listeners drive their own repaints.
  void _onSpringTick() {
    _position.value = _controller.value;
    _velocity.value = _controller.velocity;
  }

  void _animateTo(int index, {double initialVelocity = 0.0}) {
    if (_reduceMotion) {
      // Reduce Motion: jump directly, no spring or overshoot.
      _controller.stop();
      _controller.value = index.toDouble();
      _velocity.value = 0.0;
      return;
    }
    _controller.animateWith(
      SpringSimulation(
        _spring,
        _position.value,
        index.toDouble(),
        initialVelocity,
      ),
    );
  }

  /// Commits a selection: fires the haptic (when it actually changes),
  /// notifies the callback, and animates the selector.
  ///
  /// [withHaptic] overrides the default "changed vs currentIndex" check —
  /// drag gestures already tick per crossed boundary, so the commit must
  /// not tick a second time for the same index.
  void _selectTab(int index, {double initialVelocity = 0.0, bool? withHaptic}) {
    final fireHaptic = withHaptic ?? (index != widget.currentIndex);
    if (widget.enableHaptics && fireHaptic) {
      HapticFeedback.selectionClick();
    }
    widget.onTap?.call(index);
    _animateTo(index, initialVelocity: initialVelocity);
  }

  /// Springs the rubber-band scale toward [target] and pins the controller
  /// to exactly 1.0 on natural completion. The spring settles within the
  /// simulation tolerance (±0.001), never at exactly 1.0 — without the snap,
  /// a permanent ~0.999 [Transform] would keep resampling the whole bar and
  /// leave text and hairlines slightly blurry after the first drag.
  void _animateElasticTo(double target) {
    _elasticController
        .animateWith(
          SpringSimulation(
            _elasticSpring,
            _elasticController.value,
            target,
            0.0,
            tolerance: const Tolerance(distance: 0.0005, velocity: 0.005),
          ),
        )
        .whenComplete(() {
          if (mounted && !_isDragging && target == 1.0) {
            _elasticController.value = 1.0;
          }
        });
  }

  // ---------------------------------------------------------------------------
  // Gestures
  // ---------------------------------------------------------------------------

  /// Touch-down response: start moving the pill toward the pressed tab
  /// immediately, like the native tab bar (UITabBar reacts on touch down,
  /// not on release). The selection itself is still committed on tap-up /
  /// drag-end; if neither happens (gesture stolen by a parent recognizer),
  /// [_onPointerRelease] reverts the pill to [widget.currentIndex].
  void _onPointerDown(
    PointerDownEvent event,
    double contentWidth,
    double inset,
  ) {
    if (_isDragging) return;
    final tabWidth = contentWidth / widget.items.length;
    final index = ((event.localPosition.dx - inset) / tabWidth).floor().clamp(
      0,
      _maxIndex,
    );
    if (index != _position.value.round()) {
      _pendingPreMove = true;
      _animateTo(index);
    }
  }

  void _onTapUp(TapUpDetails details, double contentWidth, double inset) {
    _pendingPreMove = false;
    final tabWidth = contentWidth / widget.items.length;
    final index = ((details.localPosition.dx - inset) / tabWidth).floor().clamp(
      0,
      _maxIndex,
    );

    _selectTab(index);
  }

  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
    _pendingPreMove = false;
    _lastHapticIndex = _position.value.round().clamp(0, _maxIndex);

    // CRITICAL: stop any in-flight spring so it doesn't fight the drag.
    // Without this, the controller's ticks keep overwriting `_position` on
    // every frame while the user drags, producing the "stuttering" feel.
    _controller.stop();

    _velocitySamples.clear();
    _velocity.value = 0.0;
    // Latch the clock domain for this gesture on the first sample.
    _useSourceTimeStamp = details.sourceTimeStamp != null;

    if (!_reduceMotion) {
      _animateElasticTo(_expandedScale);
    }
  }

  void _onDragUpdate(DragUpdateDetails details, double contentWidth) {
    final tabWidth = contentWidth / widget.items.length;
    final dx = details.delta.dx;
    final delta = dx / tabWidth;

    // Track samples for smoothed velocity. Skip sub-pixel jitter so the
    // stretch effect doesn't shimmer. The clock domain latched at drag
    // start is used for the whole gesture; events missing a timestamp in a
    // sourceTimeStamp gesture are skipped rather than sampled off-clock.
    final now = _useSourceTimeStamp
        ? details.sourceTimeStamp?.inMicroseconds
        : _dragClock.elapsedMicroseconds;
    if (now != null && dx.abs() >= _kVelocityJitterPx) {
      _velocitySamples.add(_VelocitySample(now, delta));
      final cutoff = now - _kVelocityWindowMs * 1000;
      while (_velocitySamples.isNotEmpty &&
          _velocitySamples.first.timeUs < cutoff) {
        _velocitySamples.removeFirst();
      }
    }

    _position.value = (_position.value + delta).clamp(
      0.0,
      _maxIndex.toDouble(),
    );

    // Tick once per crossed tab boundary while dragging, matching
    // UISegmentedControl's selection feedback.
    final nearest = _position.value.round().clamp(0, _maxIndex);
    if (nearest != _lastHapticIndex) {
      _lastHapticIndex = nearest;
      if (widget.enableHaptics) {
        HapticFeedback.selectionClick();
      }
    }

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
      target = flingVelocity > 0
          ? _position.value.ceil()
          : _position.value.floor();
    }
    target = target.clamp(0, _maxIndex);

    _velocitySamples.clear();

    // Hand the gesture's momentum to the spring so motion continues smoothly.
    // Crossing haptics already ticked for `_lastHapticIndex`; only tick here
    // if a fling carried the target one tab further.
    _selectTab(
      target,
      initialVelocity: flingVelocity,
      withHaptic: target != _lastHapticIndex,
    );

    _animateElasticTo(1.0);
  }

  void _onDragCancel() {
    _isDragging = false;
    _velocitySamples.clear();
    // Snap back to the nearest tab if the gesture was interrupted.
    final target = _position.value.round().clamp(0, _maxIndex);
    _animateTo(target);
    _animateElasticTo(1.0);
  }

  /// Safety net for cases where [onHorizontalDragEnd] or [onTapUp] is
  /// swallowed — a parent recognizer reclaiming the gesture arena mid-drag,
  /// the OS interrupting the pointer (system gesture, app backgrounding),
  /// etc. [Listener] still fires raw pointer up/cancel in those cases, so
  /// use that as a backup: defer one microtask so the normal end path can
  /// run first, then (a) force-cleanup an orphaned drag so the bar doesn't
  /// stay stuck in the expanded rubber-band scale, and (b) revert an
  /// uncommitted touch-down pre-move so the pill can't rest on a tab the
  /// consumer never selected.
  void _onPointerRelease(PointerEvent _) {
    if (!_isDragging && !_pendingPreMove) return;
    scheduleMicrotask(() {
      if (!mounted) return;
      if (_isDragging) {
        _onDragCancel();
      } else if (_pendingPreMove) {
        _pendingPreMove = false;
        _animateTo(widget.currentIndex);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Label fitting
  // ---------------------------------------------------------------------------

  /// Memo inputs for [_resolveLabelFontSize] — measuring is only worth
  /// redoing when the labels, the tab width, or the inherited style change.
  List<String>? _fitLabels;
  double _fitMaxWidth = -1.0;
  TextStyle? _fitStyle;
  TextScaler? _fitScaler;
  double _labelFontSize = _kLabelFontSize;

  /// Labels are laid out inside the selector pill, so one wider than the pill
  /// spills over its edge while its tab is selected. Shrink every label by the
  /// same factor — just enough for the widest to fit — so the bar keeps a
  /// single consistent label size instead of one size per tab.
  double _resolveLabelFontSize(
    double tabWidth,
    TextStyle baseStyle,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final maxWidth = tabWidth * _kSelectorWidthFactor - _kLabelPadding * 2;
    final labels = <String>[for (final item in widget.items) item.label];
    if (_fitLabels != null &&
        listEquals(labels, _fitLabels) &&
        maxWidth == _fitMaxWidth &&
        baseStyle == _fitStyle &&
        scaler == _fitScaler) {
      return _labelFontSize;
    }

    // Selected labels are the wide case (w600), so measure those: the size
    // then stays put as the selection moves between tabs.
    final style = baseStyle.merge(
      const TextStyle(fontSize: _kLabelFontSize, fontWeight: FontWeight.w600),
    );
    var widest = 0.0;
    for (final label in labels) {
      if (label.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }

    _fitLabels = labels;
    _fitMaxWidth = maxWidth;
    _fitStyle = baseStyle;
    _fitScaler = scaler;
    _labelFontSize = widest <= maxWidth
        ? _kLabelFontSize
        : math.max(_kLabelFontSize * maxWidth / widest, _kMinLabelFontSize);
    return _labelFontSize;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Use viewPadding (not padding): viewPadding still reports the device's
    // raw bottom inset even when a parent SafeArea or Scaffold has already
    // consumed MediaQuery.padding, which is common when the bar is dropped
    // into a Stack(Positioned(bottom: 0, ...)) overlay.
    final systemInset = MediaQuery.viewPaddingOf(context).bottom;

    // Android's gesture-handle area (~16 dp) is much thinner than iOS's
    // home-indicator zone (~34 pt), so the bar visually sits flush against
    // the system gesture line on Android. Add a tiny clearance there by
    // default. Users can override via [bottomSpacing].
    final extra =
        widget.bottomSpacing ??
        (defaultTargetPlatform == TargetPlatform.android ? 6.0 : 0.0);

    final bottomPadding = widget.useSafeArea ? systemInset + extra : extra;

    final brightness =
        CupertinoTheme.of(context).brightness ?? Brightness.light;
    final isDark = brightness == Brightness.dark;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);

    final resolvedActive =
        widget.activeColor ?? CupertinoTheme.of(context).primaryColor;
    final resolvedInactive =
        widget.inactiveColor ??
        (isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2);

    final borderRadius =
        widget.borderRadius ?? const BorderRadius.all(Radius.circular(26.0));

    // The corner arc eats into the outer tabs' label row, so scale the strip's
    // inset with the radius: enough clearance on a pill-shaped bar, none at all
    // on a square one.
    final itemInset =
        widget.itemInset ??
        (borderRadius.topLeft.x * _kItemInsetRatio).clamp(0.0, _kMaxItemInset);

    // Main glass bar (without outer padding so rubber banding only affects it).
    Widget mainBar = CupertinoLiquidGlass(
      theme: widget.theme,
      enabled: widget.enableGlass,
      effectIntensity: widget.effectIntensity,
      borderRadius: borderRadius,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: _kTabBarHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Gestures stay on the full-width box (no dead strip at the ends),
            // so tap positions are measured against the inset strip instead.
            final inset = itemInset.clamp(0.0, constraints.maxWidth / 2);
            final contentWidth = constraints.maxWidth - inset * 2;

            final labelFontSize = _resolveLabelFontSize(
              contentWidth / widget.items.length,
              DefaultTextStyle.of(context).style,
              MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.0),
              Directionality.of(context),
            );

            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) => _onPointerDown(e, contentWidth, inset),
              onPointerUp: _onPointerRelease,
              onPointerCancel: _onPointerRelease,
              child: GestureDetector(
                onTapUp: (d) => _onTapUp(d, contentWidth, inset),
                onHorizontalDragStart: _onDragStart,
                onHorizontalDragUpdate: (d) => _onDragUpdate(d, contentWidth),
                onHorizontalDragEnd: (d) => _onDragEnd(d, contentWidth),
                onHorizontalDragCancel: _onDragCancel,
                behavior: HitTestBehavior.opaque,
                // RepaintBoundary isolates the selector + tab item repaints
                // from the glass surface (noise, blur, edge light), which is
                // expensive to rasterize and only needs to repaint once.
                child: RepaintBoundary(
                  // Native iOS tab bars don't scale their labels with Dynamic
                  // Type; clamping also prevents the fixed-height Column from
                  // overflowing (clipped pixels) at accessibility text sizes.
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: inset),
                      child: CustomPaint(
                        painter: _SelectorPainter(
                          position: _position,
                          velocity: _velocity,
                          tabCount: widget.items.length,
                          activeColor: resolvedActive,
                          selectorRadius: 16.0,
                          isDark: isDark,
                        ),
                        willChange: true,
                        child: Row(
                          children: List.generate(widget.items.length, (i) {
                            return Expanded(
                              child: Semantics(
                                container: true,
                                button: true,
                                selected: i == widget.currentIndex,
                                label: widget.items[i].label,
                                hint: 'Tab ${i + 1} of ${widget.items.length}',
                                onTap: () => _selectTab(i),
                                child: _TabItem(
                                  item: widget.items[i],
                                  proximity: _proximities[i],
                                  activeColor: resolvedActive,
                                  inactiveColor: resolvedInactive,
                                  isDark: isDark,
                                  labelFontSize: labelFontSize,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
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
    // The near-1.0 snap matters: a spring settles within tolerance, not at
    // exactly 1.0, and a lingering ~0.999 Transform would permanently
    // resample the bar (soft text, shimmering hairlines).
    mainBar = AnimatedBuilder(
      animation: _elasticController,
      builder: (context, child) {
        final value = _elasticController.value;
        final scale = (value - 1.0).abs() < 0.0015 ? 1.0 : value;
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

/// Subscribes to its own quantized proximity notifier and rebuilds only its
/// own subtree — tabs far from the selector never rebuild during transitions,
/// and the gesture detector, glass surface, and painter stay out of it.
class _TabItem extends StatelessWidget {
  final LiquidGlassBottomBarItem item;
  final ValueListenable<double> proximity;
  final Color activeColor;
  final Color inactiveColor;
  final bool isDark;
  final double labelFontSize;

  const _TabItem({
    required this.item,
    required this.proximity,
    required this.activeColor,
    required this.inactiveColor,
    required this.isDark,
    required this.labelFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kMinHitTarget,
      child: ValueListenableBuilder<double>(
        valueListenable: proximity,
        builder: (context, proximity, _) {
          final color = Color.lerp(inactiveColor, activeColor, proximity)!;
          final iconData = proximity > 0.5
              ? (item.activeIcon ?? item.icon)
              : item.icon;
          // A single discrete weight switch at the icon-swap threshold.
          // Interpolating FontWeight per frame snaps through discrete
          // weights (w400 -> w500 -> w600), forcing a full text relayout
          // every frame and making labels visibly jitter in width.
          final fontWeight = proximity > 0.5
              ? FontWeight.w600
              : FontWeight.w400;
          // Dock-style magnification.
          final iconScale = 1.0 + proximity * 0.18;

          final iconBuilder = item.iconBuilder;
          final iconWidget = iconBuilder != null
              ? iconBuilder(context, color, _kIconSize)
              : _GlassIcon(
                  icon: iconData,
                  color: color,
                  size: _kIconSize,
                  glassIntensity: proximity,
                  activeColor: activeColor,
                  isDark: isDark,
                );

          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(scale: iconScale, child: iconWidget),
              const SizedBox(height: 1.0),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: labelFontSize,
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

    // Radial-gradient glows instead of MaskFilter.blur: a mask blur is a
    // full offscreen Gaussian pass per draw, and with intensity animating
    // every frame during the selector slide those passes stack up across
    // tabs. A gradient reads visually identical for a soft halo and renders
    // in a single pass.

    // Outer colored glow.
    final glowRadius = radius * (1.0 + intensity * 0.3) + 7.0 + intensity * 3.0;
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          glowRadius,
          <Color>[
            activeColor.withValues(alpha: intensity * 0.16),
            activeColor.withValues(alpha: intensity * 0.10),
            activeColor.withValues(alpha: 0.0),
          ],
          <double>[0.0, 0.55, 1.0],
        ),
    );

    // Inner glass highlight — bright specular dot.
    final dotCenter = center.translate(0, -radius * 0.15);
    final dotRadius = radius * 0.5 * intensity + 4.0 + intensity * 2.0;
    canvas.drawCircle(
      dotCenter,
      dotRadius,
      Paint()
        ..shader = ui.Gradient.radial(dotCenter, dotRadius, <Color>[
          const Color(0xFFFFFFFF).withValues(alpha: intensity * 0.12),
          const Color(0xFFFFFFFF).withValues(alpha: 0.0),
        ]),
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

  /// Cached fill paint (constant per painter instance).
  late final Paint _fillPaint = Paint()
    ..color = isDark
        ? const Color.fromRGBO(255, 255, 255, 0.09)
        : const Color.fromRGBO(0, 0, 0, 0.05);

  /// Cached highlight stroke paint; its vertical gradient shader depends
  /// only on the pill height, so it is (re)built lazily per height instead
  /// of allocating a gradient + engine shader on every frame.
  final Paint _highlightPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  double _highlightShaderHeight = -1.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (tabCount == 0) return;

    final pos = position.value;
    final vel = velocity.value;

    final tabWidth = size.width / tabCount;

    // Velocity-based stretch: faster movement -> wider pill.
    final absVel = vel.abs().clamp(0.0, 20.0);
    final stretch = 1.0 + absVel / 55.0; // max ~1.36x

    final baseWidth = tabWidth * _kSelectorWidthFactor;
    final selectorWidth = (baseWidth * stretch).clamp(0.0, size.width - 4.0);
    // Keep the stretched pill inside the bar: at the edge tabs a fast fling
    // would otherwise push it under the rounded clip and slice it off flat.
    final unclampedX = pos * tabWidth + (tabWidth - selectorWidth) / 2;
    final maxX = size.width - selectorWidth - 2.0;
    final x = unclampedX.clamp(2.0, maxX < 2.0 ? 2.0 : maxX);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, 2.0, selectorWidth, size.height - 4.0),
      Radius.circular(selectorRadius),
    );

    // 1. Bloom glow — soft colored halo behind the selector, painted as
    //    concentric translucent fills. A MaskFilter Gaussian here would be
    //    an offscreen blur pass on every animation frame.
    canvas.drawRRect(
      rrect.inflate(7.0),
      Paint()..color = activeColor.withValues(alpha: 0.025),
    );
    canvas.drawRRect(
      rrect.inflate(4.5),
      Paint()..color = activeColor.withValues(alpha: 0.045),
    );
    canvas.drawRRect(
      rrect.inflate(2.0),
      Paint()..color = activeColor.withValues(alpha: 0.06),
    );

    // 2. Fill — subtle translucent pill.
    canvas.drawRRect(rrect, _fillPaint);

    // 3. Inner highlight — a faint top edge for depth. The gradient is
    //    vertical, so the shader only depends on the pill height: build it
    //    once and translate the canvas horizontally instead.
    if (_highlightShaderHeight != size.height) {
      _highlightShaderHeight = size.height;
      _highlightPaint.shader = LinearGradient(
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
      ).createShader(Rect.fromLTWH(0.0, 2.0, 1.0, size.height - 4.0));
    }
    canvas.drawRRect(rrect.deflate(0.25), _highlightPaint);
  }

  @override
  bool shouldRepaint(_SelectorPainter old) =>
      tabCount != old.tabCount ||
      activeColor != old.activeColor ||
      isDark != old.isDark;
}
