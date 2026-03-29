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
