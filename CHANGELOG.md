## 0.4.0

* **Bottom Bar Overhaul**: Increased bar height to 56 pt, icon size to 28 pt, touch targets to 48 pt for better usability.
* **Rubber Banding**: Bottom bar scales up 8% elastically during horizontal drag and springs back on release.
* **Glass Icon Effect**: Dock-style magnification (18% scale) and glass refraction glow on icons during selector proximity.
* **Theme Tuning**: Light mode tint opacity adjusted to 65%, dark mode to 55%, blur sigma values aligned with `UIBlurEffect.systemChromeMaterial`.
* **Dark Mode Toggle**: Example app now includes a light/dark theme switcher in the nav bar.
* **pub.dev Fix**: Shortened package description to comply with 180-character limit (150/160 points → 160/160).
* **Bug Fix**: Added missing `cupertino_icons` dependency to example app.

## 0.3.0

* **Sliding Fluid Interaction**: Added spring physics and velocity-based stretching to the bottom bar.
* **Visual Overhaul**: Implemented edge lighting, inner shadows, and microscopic noise grain.
* **LiquidGlassBloom**: New widget for soft colored glows (bloom effects).
* **Performance**: Optimized rendering with CustomPainter and RepaintBoundary.


## 0.2.0

* **Edge Lighting**: Gradient border with `edgeLightColor` / `edgeShadowColor` replacing flat `borderColor` — simulates directional light catching the glass edge.
* **Inner Shadow**: Carved-glass depth effect via `innerShadowColor` and `innerShadowBlurRadius`.
* **Noise Grain Overlay**: Microscopic texture controlled by `noiseOpacity` to prevent banding.
* **Vibrancy / Saturation Boost**: `vibrancyIntensity` overlay that perceptually enhances blurred backdrop colors.
* **LiquidGlassBloom**: New widget for soft colored glow behind child elements (active tab bloom).
* **CupertinoLiquidGlassBottomBar**: Active tab now renders bloom glow automatically.
* **CupertinoLiquidGlass**: Added `glowColor` / `glowRadius` for whole-surface bloom.
* Multi-layer rendering via `CustomPainter` with efficient `shouldRepaint` guards.

## 0.1.0

* Initial release.
* `CupertinoLiquidGlass` — core widget with real-time backdrop blur, specular highlight, and dynamic theme support.
* `LiquidGlassThemeData` — light and dark presets matching iOS system materials, with `copyWith` and `lerp` support.
* `CupertinoLiquidGlassNavBar` — floating frosted-glass navigation bar with safe-area handling.
* `CupertinoLiquidGlassBottomBar` — floating frosted-glass tab bar with safe-area handling.
* `RepaintBoundary` optimization for smooth 120 Hz ProMotion performance.
