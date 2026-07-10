# Tech Stack

## Runtime

| Technology | Version | Purpose |
|-----------|---------|---------|
| **Dart** | >= 3.11.3 | Programming language |
| **Flutter** | >= 3.32.0 | UI framework (`BackdropFilter.grouped` / `BackdropGroup`) |

## Dependencies

### Production
**None.** The package uses only Flutter SDK built-in capabilities — zero external dependencies.

### Development
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_test` | SDK | Widget and unit testing |
| `flutter_lints` | ^6.0.0 | Static analysis rules |

## Flutter APIs Used

### Rendering & Compositing
| API | Usage |
|-----|-------|
| `BackdropFilter.grouped` / `BackdropGroup` | Real-time Gaussian blur; sibling surfaces share one backdrop readback |
| `ImageFilter.blur` + `ImageFilter.compose` | Blur kernel composed with the vibrancy color filter in one pass |
| `ColorFilter.matrix` | Saturation-boost vibrancy (UIKit saturate-then-blur recipe) |
| `CustomPainter` | Multi-layer glass surface rendering (background + foreground) |
| `ClipRRect` | Rounded corner clipping for all composited layers |
| `RepaintBoundary` | Performance isolation — prevents ancestor repaints |
| `ImageShader` + `Picture.toImageSync` | Pre-baked repeating noise-grain tile (cached per DPR) |
| `MaskFilter.blur` | Static content only: outer glow and inner shadow |
| `RadialGradient` / `ui.Gradient.radial` | Bloom glow and icon halos (no per-frame Gaussian passes) |
| `LinearGradient` | Specular shine and edge-lit border |

### Animation & Physics
| API | Usage |
|-----|-------|
| `AnimationController` | Drives spring-based tab transitions and rubber banding |
| `SpringSimulation` | Bouncy, natural-feeling animations |
| `SpringDescription` | Configurable mass/stiffness/damping |
| `Transform.scale` | Elastic rubber banding effect during drag |

### Gestures & Interaction
| API | Usage |
|-----|-------|
| `Listener` | Touch-down pill pre-move + orphaned-gesture watchdog |
| `GestureDetector` | Tap and horizontal drag detection on bottom bar |
| `Velocity` | Fling detection for snap-to-tab behavior |
| `HapticFeedback.selectionClick` | Selection haptic on tab change + per crossed boundary while dragging |
| `Semantics` | Screen-reader support (tab buttons, selected state, header titles) |
| `MediaQuery.disableAnimationsOf` | Reduce Motion: springs and rubber banding degrade gracefully |
| `MediaQuery.withClampedTextScaling` | Native-style fixed tab-label size at accessibility text scales |

### Theming & Platform
| API | Usage |
|-----|-------|
| `CupertinoTheme` | Ambient brightness detection (light/dark) |
| `CupertinoColors` | iOS-native color palette |
| `MediaQuery` | Safe area insets for status bar and home indicator |

### Layout
| API | Usage |
|-----|-------|
| `LayoutBuilder` | Dynamic tab width calculation based on available space |
| `SafeArea` | Platform-aware padding for notch/home indicator |

## Target Platforms

| Platform | Status |
|----------|--------|
| iOS | Primary target |
| Android | Supported |
| macOS | Supported |
| Web | Supported |
| Windows | Supported |
| Linux | Supported |

> Note: Best visual fidelity on iOS due to native Cupertino design language alignment.

## Development Tools

| Tool | Purpose |
|------|---------|
| `dart analyze` | Static analysis with flutter_lints |
| `dart format` | Code formatting (Effective Dart) |
| `flutter test` | Run widget and unit tests |
| `flutter pub publish` | Publish to pub.dev |

## Code Quality Standards

- **Linting:** `package:flutter_lints/flutter.yaml` (analysis_options.yaml)
- **Style:** Effective Dart conventions
- **Documentation:** DartDoc on all public APIs (English only)
- **Colors:** Cupertino palette only — no Material colors
- **Constructors:** `const` wherever possible
