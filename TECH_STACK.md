# Tech Stack

## Runtime

| Technology | Version | Purpose |
|-----------|---------|---------|
| **Dart** | >= 3.11.3 | Programming language |
| **Flutter** | >= 3.27.0 | UI framework |

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
| `BackdropFilter` | Real-time Gaussian blur on backdrop content |
| `ImageFilter.blur` | Configurable sigma blur kernel |
| `CustomPainter` | Multi-layer glass surface rendering (background + foreground) |
| `ClipRRect` | Rounded corner clipping for all composited layers |
| `RepaintBoundary` | Performance isolation — prevents ancestor repaints |
| `BlendMode.overlay` | Vibrancy effect to boost perceived saturation |
| `MaskFilter.blur` | Soft bloom glow on selector pill |
| `RadialGradient` | Bloom glow effect rendering |
| `LinearGradient` | Specular shine and edge-lit border |

### Animation & Physics
| API | Usage |
|-----|-------|
| `AnimationController` | Drives spring-based tab transitions |
| `SpringSimulation` | Bouncy, natural-feeling animations |
| `SpringDescription` | Configurable mass/stiffness/damping |

### Gestures & Interaction
| API | Usage |
|-----|-------|
| `GestureDetector` | Tap and horizontal drag detection on bottom bar |
| `Velocity` | Fling detection for snap-to-tab behavior |

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
