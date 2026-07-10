## 0.7.0

Performance & pixel-fidelity release: eliminates the transition stutter and per-device pixel artifacts reported on mid/low-end hardware, bringing the rendering pipeline much closer to native iOS materials.

### Jank fixes
* **Value-equal themes, correct `shouldRepaint`**: `LiquidGlassThemeData` now implements `==`/`hashCode`, `light()`/`dark()` return canonical const instances, and `copyWith()`/`lerp()` short-circuit no-op calls. The glass painters compare themes by value instead of `identical()`, so the full glass stack (tint, specular, inner shadow, noise, border) no longer re-rasterizes on every ancestor rebuild — previously the single biggest jank source during any transition.
* **Pre-baked noise grain**: the grain is rendered once into a small repeating `ui.Image` tile (per DPR, via `toImageSync`) and drawn with an `ImageShader` — one textured quad instead of regenerating and drawing up to 5000 random round points per repaint. Grains are snapped to whole physical pixels, so the texture renders identically on Impeller and Skia at every DPR.
* **Vibrancy moved into the backdrop pass**: the `BlendMode.overlay` vibrancy layer is replaced by a saturation `ColorFilter` composed with the blur (`ImageFilter.compose`) — UIKit's actual saturate-then-blur recipe — removing an advanced-blend offscreen pass per frame.
* **No more per-frame Gaussians in the tab bar**: the selector bloom and the icon glow/specular halos now use concentric fills and radial gradients instead of `MaskFilter.blur`, eliminating 3–5 offscreen blur passes per animation frame; the selector's highlight shader and paints are cached instead of allocated per frame.
* **Scoped tab rebuilds**: each tab subscribes to its own quantized proximity notifier — tabs more than one index from the selector no longer rebuild at all during drags and spring settles.
* **No per-frame text relayout**: tab-label weight switches once at the selection threshold instead of `FontWeight.lerp` per frame, which snapped through discrete weights (visible label jitter) and forced a full paragraph relayout every frame.
* **Detached button press**: the `Opacity` wrapper (a per-frame saveLayer over the backdrop filter) is replaced by a scrim painted inside the glass; the press animation early-outs at rest.
* **Shared backdrop readbacks**: `CupertinoLiquidGlass` uses `BackdropFilter.grouped`, so multiple glass surfaces under a `BackdropGroup` (see the example's gallery list) share a single backdrop snapshot per frame. Requires Flutter 3.32+.

### Pixel-artifact fixes
* **Edge fringe eliminated**: the backdrop blur no longer forces `TileMode.decal`, which mixed transparent black into the blur kernel near every edge and produced a dark/washed vignette (up to ~3·sigma wide) that rendered differently on Impeller vs Skia. The engine now picks the artifact-free backdrop tile mode.
* **Permanently-blurry bar after first drag fixed**: the rubber-band spring settles within tolerance, never at exactly 1.0, so a lingering ~0.999 `Transform` kept resampling the whole bar (soft labels, shimmering hairlines). The scale now snaps to identity near rest and the controller is pinned to 1.0 on completion; the settle simulation also uses a tighter explicit tolerance so it stops as soon as motion is imperceptible.
* **Double-antialiasing halo removed**: flat glass layers (tint, specular) are painted full-bleed and shaped by the ancestor clip alone, removing the ~1px halo along rounded corners caused by two independently antialiased edges.
* **Physical-pixel hairline border**: the edge-light stroke width is snapped to a whole number of physical pixels per DPR (0.75pt mapped to e.g. 1.97px on DPR 2.625 and looked ropey around corners).
* **Clean glass, no baked-in shadow**: drop shadows and glow are now painted with the glass footprint punched out, so the backdrop blur no longer samples the widget's own shadow (which darkened/muddied the surface, worst in dark mode).
* **Inner shadow accuracy**: the punch-out rect is inflated by 4× the blur radius so the outer edge's blur tail can't bleed a faint band back into the surface.
* **Selector overflow clamp**: a velocity-stretched pill can no longer slide under the bar's rounded clip at edge tabs during fast flings (it was visibly sliced flat).

### Native-feel & accessibility
* **Selection haptics**: the bottom bar fires `HapticFeedback.selectionClick()` when the selection changes (like `UISelectionFeedbackGenerator`); opt out with `enableHaptics: false`.
* **Reduce Motion**: when `MediaQuery.disableAnimationsOf` is true, the selector jumps without springs/overshoot, rubber banding is skipped, and the detached button uses a short non-elastic release.
* **Screen readers**: tab items expose proper semantics (button, selected state, label, "Tab X of N" hint, tap action); `LiquidGlassDetachedButton` gains `semanticLabel`; nav-bar titles are announced as headers.
* **Dynamic Type safety**: tab-bar labels clamp text scaling (native iOS tab bars don't scale labels), preventing clipped/overflowing pixels at accessibility text sizes.
* **Monotonic velocity clock**: drag velocity sampling latches a single clock domain per gesture (no more mixing `sourceTimeStamp` with wall-clock time, which corrupted the stretch effect on some devices).
* **Scoped MediaQuery**: the nav bar uses `MediaQuery.viewPaddingOf` instead of `MediaQuery.of`, so keyboard-inset animations no longer rebuild the glass bar every frame.
* **Example app**: tabs live in an `IndexedStack` (state preserved, no full-page re-raster mid transition), one shared background, `BackdropGroup` around the page content, aspect-scoped MediaQuery accessors.

## 0.6.0

* **Smooth drag (perf)**: Bottom-bar drag is no longer fighting a running spring simulation. The controller now stops at drag start, position and velocity moved into `ValueNotifier`s and the selector painter subscribes via `repaint:` — no `setState` per frame. Glass surface + selector painter are isolated by a `RepaintBoundary` so backdrop blur and noise grain are not re-rasterized while dragging.
* **Velocity smoothing**: 90 ms sliding-window with a sub-pixel jitter filter feeds the selector's stretch effect, replacing the per-frame `delta * 60` estimate. The fling velocity at drag end is forwarded into the spring as `initialVelocity`, so the snap preserves gesture momentum.
* **Stuck rubber-band fix**: `GestureDetector` is wrapped in a `Listener` watchdog. If a parent recognizer reclaims the gesture arena mid-drag, an OS gesture interrupts the pointer or the app backgrounds, `onHorizontalDragEnd` can be swallowed and the bar previously stayed at 1.08× scale. The watchdog detects orphaned drags via raw `pointerUp` / `pointerCancel` and forces a cancel so the elastic spring returns to 1.0.
* **Glass effect toggle**: New `enableGlass` parameter on `CupertinoLiquidGlassBottomBar`, `CupertinoLiquidGlassNavBar` and `LiquidGlassDetachedButton` (forwarded to a new `enabled` flag on `CupertinoLiquidGlass`). When false, the `BackdropFilter` and decorative layers (vibrancy, specular, inner shadow, noise grain, edge light, iridescent sweep) are skipped and the surface falls back to a solid Cupertino `systemGrey6` background — useful as a low-power fallback or design opt-out. Optional `disabledColor` overrides the solid color.
* **Android safe-area fix**: Bottom bar now uses `MediaQuery.viewPadding.bottom` (immune to parent SafeArea/Scaffold consumers) and adds a 6 dp default clearance on Android, where the gesture-handle area (~16 dp) is much thinner than iOS's home-indicator zone. New `bottomSpacing` parameter exposes the override.
* **Tighter dimensions (HIG)**: Bar height 56 → 52, icon 28 → 25, label 11 → 10, min hit target 48 → 44 (Apple HIG minimum). Default `LiquidGlassDetachedButton.size` 56 → 52 so it stays symmetrical when slotted into the bottom bar.
* **Toned-down selected-tab glow**: Icon outer halo alpha 0.22 → 0.16 with a tighter blur radius; inner specular highlight alpha 0.18 → 0.12 (the main source of glare); selector pill bloom alpha 0.18 → 0.13 and blur 10 → 8.
* **Example app**: New _Glass Effect_ toggle in the Theme tab that flips `enableGlass` on the nav bar, bottom bar and detached buttons in unison. Refactored toggle row into a reusable `_ToggleRow`.

## 0.5.0

* **`LiquidGlassDetachedButton`**: New circular floating glass button widget for the iOS 26 detached-action pattern (Apple News-style). Includes prismatic iridescent sweep, custom theme override, and a tap press animation (scale + opacity with elastic release).
* **Detached button slot on bars**: `CupertinoLiquidGlassNavBar` and `CupertinoLiquidGlassBottomBar` now accept a `detachedButton` widget rendered to the right of the main bar. Rubber banding on the bottom bar applies only to the main strip — the detached button stays fixed during drag.
* **Nav bar height alignment**: Standardised on a 44 pt content height (`_kNavBarContentHeight`) so the nav bar and detached button sit on the same baseline.
* **Example app**: Restructured into a multi-page demo (Gallery, Effects, Theme) with a colorful animated background that better showcases backdrop blur. Both bars now demonstrate the detached button slot.
* **Docs**: Added `LiquidGlassDetachedButton` API reference and `detachedButton` parameter docs to README.

## 0.4.1

* **Docs**: Updated README showcase with animated GIF, removed unused image assets.

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
