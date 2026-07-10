<p align="center">
  <img src="https://raw.githubusercontent.com/erenmalkoc/cupertino_liquid_glass/main/doc/assets/mobile-gif.gif" width="320" alt="Liquid Glass Demo" />
</p>

<p align="center">
  <a href="https://pub.dev/packages/cupertino_liquid_glass"><img src="https://img.shields.io/pub/v/cupertino_liquid_glass.svg" alt="pub package"></a>
  <a href="https://pub.dev/packages/cupertino_liquid_glass/score"><img src="https://img.shields.io/pub/points/cupertino_liquid_glass" alt="pub points"></a>
  <a href="https://pub.dev/packages/cupertino_liquid_glass/score"><img src="https://img.shields.io/pub/popularity/cupertino_liquid_glass" alt="popularity"></a>
  <a href="https://pub.dev/packages/cupertino_liquid_glass/score"><img src="https://img.shields.io/pub/likes/cupertino_liquid_glass" alt="likes"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license: MIT"></a>
</p>

<p align="center">
  <b>Apple's iOS Liquid Glass aesthetic — implemented entirely in Flutter.</b>
</p>

---

A Flutter package that approximates the visual appearance of Apple's iOS Liquid Glass design using `BackdropFilter`, multi-layer `CustomPainter`, and spring physics. No UIKit bridge, no platform channel, no native code.

The effect covers backdrop blur, specular highlights, directional edge lighting, inner shadows, vibrancy boost, and noise grain — all resolving automatically from `CupertinoTheme` brightness. The included tab bar uses `SpringSimulation` for elastic, physics-driven transitions.

**This package replicates appearance, not native rendering.** If your project requires exact parity with iOS 26's native `glassEffect` modifier or `UIBlurEffect`, a native-bridge approach is necessary. For Flutter apps that want the Liquid Glass aesthetic through a straightforward Dart API, this package is production-ready.

## Features

| Feature | Description |
|---|---|
| **Native iOS blur** | Real `BackdropFilter` + `ImageFilter.blur` — not a fake overlay. Content behind the glass is genuinely refracted. |
| **Light & Dark mode** | Automatically adapts to `CupertinoTheme` brightness. Light mode is matte & bright; dark mode is deep & contrasty. |
| **Specular highlight** | A configurable gradient "sheen" that gives the surface its liquid, alive feel. |
| **ProMotion optimized** | `RepaintBoundary` isolation ensures the blur compositing layer is re-rasterized independently — no scroll jank at 120 Hz. |
| **Fully customizable** | Override `blurSigma`, `tintOpacity`, `borderRadius`, `edgeLightColor`, `edgeShadowColor`, `borderWidth`, and `specularGradient` per-widget. |
| **Effect intensity dial** | One `effectIntensity` knob (0.0–1.0) scales all decorative layers — `0.0` is a clean iOS-style frosted surface (blur + tint only), `1.0` the full liquid-glass treatment. |
| **Theme interpolation** | `LiquidGlassThemeData.lerp()` enables smooth animated transitions between any two theme configurations. |
| **Native-feel gestures** | The tab bar reacts on touch **down** (like `UITabBar`), fires selection haptics on tab change and per crossed boundary while dragging, and honors Reduce Motion. |
| **Accessible** | Tab items expose full semantics (button, selected state, "Tab X of N"), labels clamp text scaling like native tab bars, and `LiquidGlassDetachedButton` takes a `semanticLabel`. |
| **Shared backdrop readback** | Uses `BackdropFilter.grouped` — wrap a list of glass cards in a `BackdropGroup` and they share one backdrop snapshot per frame. |
| **Pre-built bars** | `CupertinoLiquidGlassNavBar` and `CupertinoLiquidGlassBottomBar` — drop-in replacements with safe-area handling. |
| **Apple HIG compliant** | Bottom bar with 52 pt height, 25 pt icons, 44 pt touch targets for comfortable interaction. |
| **Rubber banding** | Elastic scale animation (8%) on horizontal drag — the bar expands during swipe and springs back on release. A `Listener` watchdog guarantees the bar resets even when the gesture arena swallows the drag-end callback. |
| **Glass icon effect** | Dock-style magnification and glass refraction glow on icons as the selector passes over them. |
| **Detached button** | `LiquidGlassDetachedButton` — circular floating glass action button with iridescent sweep and press animation, slottable into both bars. |
| **Glass toggle** | `enableGlass: false` falls back to a solid Cupertino `systemGrey6` surface — useful as a low-power fallback or pure-flat design opt-out. |
| **Android safe-area** | Uses `viewPadding` so the bar is not crowded by the gesture handle even when a parent has already consumed `MediaQuery.padding`. |

## Getting started

### Requirements

| Requirement | Minimum |
|---|---|
| Flutter | 3.32.0 |
| Dart SDK | 3.11.3 |

### Installation

```yaml
dependencies:
  cupertino_liquid_glass: ^0.7.0
```

```bash
flutter pub get
```

## Usage

### Basic — wrap any widget

```dart
import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';

CupertinoLiquidGlass(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text('Hello, Glass!'),
  ),
)
```

### Custom blur & radius

```dart
CupertinoLiquidGlass(
  blurSigma: 40,
  tintOpacity: 0.3,
  borderRadius: BorderRadius.circular(32),
  edgeLightColor: Color(0x60FFFFFF),
  child: MyContent(),
)
```

### Explicit dark theme

```dart
CupertinoLiquidGlass(
  theme: LiquidGlassThemeData.dark(),
  child: MyContent(),
)
```

### Floating navigation bar

```dart
CupertinoLiquidGlassNavBar(
  leading: CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: () => Navigator.pop(context),
    child: Icon(CupertinoIcons.back),
  ),
  title: Text('Inbox'),
  trailing: CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: () {},
    child: Icon(CupertinoIcons.ellipsis_circle),
  ),
)
```

### Bottom tab bar

```dart
CupertinoLiquidGlassBottomBar(
  currentIndex: _selectedTab,
  onTap: (i) => setState(() => _selectedTab = i),
  items: const [
    LiquidGlassBottomBarItem(
      icon: CupertinoIcons.house,
      activeIcon: CupertinoIcons.house_fill,
      label: 'Home',
    ),
    LiquidGlassBottomBarItem(
      icon: CupertinoIcons.search,
      label: 'Search',
    ),
    LiquidGlassBottomBarItem(
      icon: CupertinoIcons.gear_alt,
      activeIcon: CupertinoIcons.gear_alt_fill,
      label: 'Settings',
    ),
  ],
)
```

### Detached action button

A floating circular glass button — slot it into either bar:

```dart
CupertinoLiquidGlassBottomBar(
  currentIndex: _selectedTab,
  onTap: (i) => setState(() => _selectedTab = i),
  items: const [/* ... */],
  detachedButton: LiquidGlassDetachedButton(
    onTap: () {},
    child: const Icon(
      CupertinoIcons.search,
      color: CupertinoColors.activeBlue,
    ),
  ),
)
```

Or stand-alone:

```dart
LiquidGlassDetachedButton(
  size: 44,
  onTap: () {},
  child: const Icon(CupertinoIcons.plus, size: 20),
)
```

### Animated theme transition

```dart
final theme = LiquidGlassThemeData.lerp(
  LiquidGlassThemeData.light(),
  LiquidGlassThemeData.dark(),
  animationController.value, // 0.0 → 1.0
);

CupertinoLiquidGlass(
  theme: theme,
  child: MyContent(),
)
```

## API Reference

### `CupertinoLiquidGlass`

The core widget. Wraps any child in a frosted-glass surface with backdrop blur.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `child` | `Widget` | **required** | Content inside the glass surface |
| `theme` | `LiquidGlassThemeData?` | auto | Explicit theme (auto-resolves from brightness if null) |
| `blurSigma` | `double?` | theme | Override blur intensity |
| `tintOpacity` | `double?` | theme | Override tint layer opacity |
| `borderRadius` | `BorderRadius?` | theme | Override corner radius |
| `edgeLightColor` | `Color?` | theme | Override edge highlight color |
| `edgeShadowColor` | `Color?` | theme | Override edge shadow color |
| `borderWidth` | `double?` | theme | Override border width |
| `specularGradient` | `Gradient?` | theme | Override specular highlight |
| `padding` | `EdgeInsetsGeometry?` | null | Inner padding |
| `width` | `double?` | null | Fixed width |
| `height` | `double?` | null | Fixed height |
| `glowColor` | `Color?` | null | Soft bloom glow around surface |
| `glowRadius` | `double` | 24.0 | Blur radius of glow |
| `enabled` | `bool` | true | When false, skips backdrop blur + decorative layers and renders a solid surface |
| `disabledColor` | `Color?` | systemGrey6 | Solid background used when `enabled` is false |
| `effectIntensity` | `double` | 1.0 | Scales all decorative layers (0.0 = blur + tint only, 1.0 = full glass) |

### `LiquidGlassThemeData`

| Factory / Method | Description |
|---|---|
| `LiquidGlassThemeData.light()` | Bright, matte preset matching `UIBlurEffect.systemMaterial` (canonical const instance) |
| `LiquidGlassThemeData.dark()` | Deep, contrasty preset matching `UIBlurEffect.systemMaterialDark` (canonical const instance) |
| `.copyWith(...)` | Returns a copy with specified fields replaced |
| `.scaleEffects(factor)` | Returns a copy with all decorative layers scaled (0.0–1.0); the material itself is untouched |
| `LiquidGlassThemeData.lerp(a, b, t)` | Linearly interpolates between two themes |

`LiquidGlassThemeData` implements value equality (`==`/`hashCode`), so themes are safe to compare, cache, and use as keys.

### `CupertinoLiquidGlassNavBar`

A floating glass navigation bar with safe-area handling.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `title` | `Widget?` | null | Center title widget |
| `leading` | `Widget?` | null | Left-side widget (back button, etc.) |
| `trailing` | `Widget?` | null | Right-side widget (action button, etc.) |
| `theme` | `LiquidGlassThemeData?` | auto | Glass theme override |
| `borderRadius` | `BorderRadius?` | 22 px | Corner radius |
| `horizontalMargin` | `double` | 8.0 | Horizontal margin from screen edges |
| `useSafeArea` | `bool` | true | Include status bar padding |
| `enableGlass` | `bool` | true | When false, the bar falls back to a solid Cupertino surface |
| `effectIntensity` | `double` | 1.0 | Scales all decorative glass layers (0.0 = blur + tint only) |
| `detachedButton` | `Widget?` | null | Optional detached circular button rendered to the right of the bar |

### `CupertinoLiquidGlassBottomBar`

A floating glass tab bar with safe-area handling.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `items` | `List<LiquidGlassBottomBarItem>` | **required** | Tab items |
| `currentIndex` | `int` | 0 | Selected tab index |
| `onTap` | `ValueChanged<int>?` | null | Tab tap callback |
| `activeColor` | `Color?` | primaryColor | Selected tab color |
| `inactiveColor` | `Color?` | systemGrey | Unselected tab color |
| `theme` | `LiquidGlassThemeData?` | auto | Glass theme override |
| `borderRadius` | `BorderRadius?` | 26 px | Corner radius |
| `horizontalMargin` | `double` | 8.0 | Horizontal margin from screen edges |
| `useSafeArea` | `bool` | true | Include home indicator padding |
| `enableGlass` | `bool` | true | When false, the bar falls back to a solid Cupertino surface |
| `bottomSpacing` | `double?` | auto | Extra clearance below the bar. `null` adds 6 dp on Android (gesture handle area), 0 elsewhere |
| `springDescription` | `SpringDescription?` | Apple-like | Custom spring physics for selector animation |
| `enableHaptics` | `bool` | true | Selection haptic on tab change + a tick per crossed boundary while dragging |
| `effectIntensity` | `double` | 1.0 | Scales all decorative glass layers (0.0 = blur + tint only) |
| `detachedButton` | `Widget?` | null | Optional detached circular button rendered to the right of the bar (rubber banding does not apply to it) |

The bar reacts on touch **down** (the selector starts moving immediately, like `UITabBar`); the selection is committed via `onTap` on release. When the system Reduce Motion setting is on, springs and rubber banding are skipped.

### `LiquidGlassDetachedButton`

A circular floating glass button matching the iOS 26 detached-action pattern (Apple News-style sidebar button).

| Parameter | Type | Default | Description |
|---|---|---|---|
| `child` | `Widget` | **required** | Icon or content rendered inside the button |
| `onTap` | `VoidCallback?` | null | Tap callback |
| `size` | `double` | 52.0 | Diameter of the circular button (matches bottom-bar height) |
| `iridescent` | `bool` | true | When true, overlays a sweep gradient simulating prismatic light refraction |
| `theme` | `LiquidGlassThemeData?` | auto | Optional explicit theme (defaults to a more transparent variant of the brightness preset) |
| `enableGlass` | `bool` | true | When false, falls back to a solid Cupertino surface; the iridescent sweep is also suppressed |
| `semanticLabel` | `String?` | null | Label announced by screen readers |
| `effectIntensity` | `double` | 1.0 | Scales the decorative layers and the iridescent sweep (0.0 = blur + tint only) |

The button has a built-in press animation: it scales down to 88% with a subtle darkening scrim on tap-down, then springs back with a single overshoot (~260 ms) on release. With Reduce Motion enabled the release is a short plain ease-out.

## Performance tips

- **Avoid nesting** multiple `CupertinoLiquidGlass` widgets inside each other — each one adds a compositing layer.
- **Many glass surfaces in one list?** Wrap the list in a [`BackdropGroup`](https://api.flutter.dev/flutter/widgets/BackdropGroup-class.html): all glass cards inside share a single backdrop readback per frame instead of one per card.
- The widget already uses `RepaintBoundary` internally; you don't need to add your own.
- On older devices, consider reducing `blurSigma` (e.g. 15–20) for smoother scrolling, or set `enableGlass: false` as a low-power fallback.
- Use `CupertinoLiquidGlass` on floating overlays (nav bars, cards, sheets) rather than full-screen backgrounds.

## Example app

A complete demo app is included in the [`example/`](example/) directory. Run it with:

```bash
cd example
flutter run
```

## Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Built with Flutter &bull; Inspired by Apple's Human Interface Guidelines
</p>
