# Architecture

## Overview

`cupertino_liquid_glass` is a Flutter package that replicates Apple's iOS "Liquid Glass" blur and translucency design language. The architecture follows a **composable, modular** pattern: a core glass widget provides the visual effect, pre-built convenience widgets add opinionated layouts on top, and a centralized theme system controls all visual parameters.

## Directory Structure

```
lib/
├── cupertino_liquid_glass.dart              # Barrel export (public API surface)
└── src/
    ├── cupertino_liquid_glass_widget.dart    # Core glass widget + bloom effect
    ├── liquid_glass_theme.dart               # Theme data & light/dark presets
    ├── liquid_glass_nav_bar.dart             # Pre-built navigation bar
    └── liquid_glass_bottom_bar.dart          # Pre-built bottom tab bar

example/
└── lib/
    └── main.dart                            # Demo application

test/
└── cupertino_liquid_glass_test.dart         # Unit & widget tests
```

## Component Map

### 1. CupertinoLiquidGlass (Core Widget)

**File:** `lib/src/cupertino_liquid_glass_widget.dart` (~910 lines)

Wraps any child widget in an Apple-style liquid glass surface. Stateless; all rendering is handled by internal painters.

**Widget Tree:**
```
CupertinoLiquidGlass (StatelessWidget)
└── RepaintBoundary
    └── CustomPaint (_OuterShadowPainter: drop shadow + glow, glass footprint punched out)
        └── SizedBox (optional width/height)
            └── ClipRRect (clips to borderRadius)
                └── BackdropFilter.grouped (saturation ColorFilter ∘ ImageFilter.blur)
                    └── _GlassSurface
                        └── CustomPaint (isComplex: true)
                            ├── painter: _GlassBackgroundPainter
                            ├── foregroundPainter: _GlassForegroundPainter
                            └── Padding → child
```

The backdrop filter composes the vibrancy (a luminance-preserving saturation
matrix) with the Gaussian blur in a single backdrop pass — UIKit's
saturate-then-blur material recipe. The tile mode is left to the engine
(never `TileMode.decal`, which fringes the edges). The outer shadow is
painted with the glass footprint clipped out so the blur never samples the
widget's own shadow.

**Internal Classes:**
- `_OuterShadowPainter` — Drop shadow + glow around the surface, glass area punched out
- `_GlassSurface` — Compositing widget that stacks background & foreground painters around child content
- `_GlassBackgroundPainter` — Paints tint layer (full-bleed), specular gradient, inner shadow (vibrancy lives in the filter chain)
- `_GlassForegroundPainter` — Paints noise grain (pre-baked repeating `ui.Image` tile via `ImageShader`, cached per DPR) and the edge-lit gradient border (stroke width snapped to whole physical pixels)
- `LiquidGlassBloom` — Renders soft colored radial glow behind content via `_BloomPainter`
- `LiquidGlassDetachedButton` — Public stateful widget; circular floating glass action button. Stacks `CupertinoLiquidGlass` + an optional `_IridescentPainter` sweep gradient and drives a press animation via `AnimationController` (scale to 88% + darkening scrim painted inside the glass — no `Opacity` layer — with a ~260 ms single-overshoot release; honors Reduce Motion).
- `_IridescentPainter` — Sweep-gradient overlay simulating prismatic light refraction; scaled by `effectIntensity`.

### 2. LiquidGlassThemeData (Theme System)

**File:** `lib/src/liquid_glass_theme.dart` (~355 lines)

Immutable configuration object controlling every visual parameter of the glass effect.

**Factories:**
- `LiquidGlassThemeData.light()` — Bright, matte preset (sigma 25, white tint 65% opacity). Returns a canonical `const` instance.
- `LiquidGlassThemeData.dark()` — Deep, contrasty preset (sigma 28, dark tint 55% opacity). Returns a canonical `const` instance.

**Key Methods:**
- `copyWith(...)` — Returns modified copy (returns `this` when all arguments are null)
- `scaleEffects(factor)` — Copy with all decorative layers scaled (0.0–1.0); material untouched. Powers `effectIntensity`.
- `static lerp(a, b, t)` — Smooth animated transitions between themes (short-circuits at `t == 0.0` / `1.0`)
- `operator ==` / `hashCode` — Full value equality; painters compare themes by value in `shouldRepaint`

**Theme Resolution Flow:**
1. Read ambient brightness from `CupertinoTheme.brightnessOf(context)`
2. If explicit `theme` provided, use it; otherwise auto-select light/dark factory
3. Merge any explicit parameter overrides on top
4. Apply `effectIntensity` via `scaleEffects`
5. Return fully resolved theme

### 3. CupertinoLiquidGlassNavBar

**File:** `lib/src/liquid_glass_nav_bar.dart` (~145 lines)

Pre-built floating navigation bar. Stateless wrapper around `CupertinoLiquidGlass`. Content height is fixed at 44 pt to align with the default `LiquidGlassDetachedButton` baseline.

```
CupertinoLiquidGlassNavBar
└── Padding (SafeArea top + horizontal margins)
    └── (detachedButton == null)
        ? CupertinoLiquidGlass
        │   └── Row: [leading] [Expanded title] [trailing]
        : Row
            ├── Expanded(CupertinoLiquidGlass: leading | title | trailing)
            └── detachedButton  (typically LiquidGlassDetachedButton)
```

### 4. CupertinoLiquidGlassBottomBar

**File:** `lib/src/liquid_glass_bottom_bar.dart` (~990 lines)

Pre-built floating tab bar with spring physics, velocity-based stretch, and drag interaction.

```
CupertinoLiquidGlassBottomBar (StatefulWidget)
└── Padding (SafeArea bottom + horizontal margins)
    └── (detachedButton == null)
        ? mainBar
        : Row(crossAxis: end)
            ├── Expanded(mainBar)
            └── detachedButton  (rubber banding does NOT apply)

where mainBar = AnimatedBuilder (Transform.scale(_elasticController), snaps to identity near 1.0)
                  └── CupertinoLiquidGlass
                      └── LayoutBuilder
                          └── Listener (touch-down pre-move + orphaned-gesture watchdog)
                              └── GestureDetector (tap + horizontal drag)
                                  └── RepaintBoundary
                                      └── MediaQuery.withClampedTextScaling(max 1.0)
                                          └── CustomPaint (_SelectorPainter, willChange: true)
                                              └── Row: [Expanded Semantics(_TabItem)] x N
```

**State Management:**
- `_controller` (`AnimationController.unbounded`) drives spring-based selector animations
- `_elasticController` (`AnimationController.unbounded`) drives rubber banding scale
- `SpringSimulation` provides bouncy transitions (default: mass 1.0, stiffness 320.0, damping 22.0)
- `_position` / `_velocity` (`ValueNotifier<double>`) — fractional index + velocity; the selector painter subscribes via `repaint:` (no widget rebuilds per frame)
- `_proximities` — one quantized (1/128) proximity `ValueNotifier` per tab; each `_TabItem` listens only to its own, so tabs far from the selector never rebuild during transitions
- Velocity smoothing: 90 ms sliding window in a `Queue` (O(1) pruning), single clock domain latched per gesture

**Gestures (native-feel):**
- Touch **down**: selector starts moving toward the pressed tab immediately (`Listener.onPointerDown`); commit still happens on tap-up/drag-end, with a microtask watchdog reverting an uncommitted pre-move
- Drag: pill follows the finger; a selection haptic ticks once per crossed tab boundary
- Fling: gesture momentum is handed to the spring as `initialVelocity`
- Reduce Motion (`MediaQuery.disableAnimationsOf`): selector jumps, rubber banding skipped

**Rubber Banding (Elasticity):**
- On drag start: bar scales up to 108% via spring; on release springs back to 100%
- Anchor point: `Alignment.bottomCenter` (expands upward)
- Spring: mass 1.0, stiffness 420.0, damping 24.0 with tight explicit tolerance — while it runs, the Transform above the BackdropFilter forces a backdrop re-blur per frame, so the settle is kept short (~0.3 s)
- On completion the controller is pinned to exactly 1.0 and the builder snaps near-1.0 values to identity, so the bar is never left permanently resampled (blurry)

**Glass Icon Effect:**
- Dock-style magnification: icons scale up to 118% based on selector proximity
- `_GlassIcon` widget wraps each icon with `_GlassIconPainter`
- Outer colored glow + inner specular dot as radial-gradient shader draws (no per-frame `MaskFilter` Gaussian passes)
- All effects interpolate smoothly with proximity (0.0 → 1.0); label weight switches once at the 0.5 threshold (no per-frame text relayout)

**Bar Dimensions (Apple HIG):**
- Bar height: 52 pt (`_kTabBarHeight`)
- Icon size: 25 pt (`_kIconSize`)
- Touch target: 44 pt minimum (`_kMinHitTarget`)
- Label font: 10 pt (`_kLabelFontSize`)

**Supporting Classes:**
- `LiquidGlassBottomBarItem` — Data class holding `icon`, `activeIcon`, and `label`
- `_TabItem` — Per-tab widget listening to its own proximity notifier
- `_GlassIcon` — Widget rendering icon with glass refraction glow
- `_GlassIconPainter` — CustomPainter for proximity-based glass halo
- `_SelectorPainter` — Sliding pill: concentric bloom fills, cached paints/shader, edge-clamped stretch

## Multi-Layer Rendering Pipeline

The glass effect is achieved through composited visual layers:

```
Layer 6 (top):  Edge-lit gradient border (foreground painter, physical-pixel snapped)
Layer 5:        Noise grain tile via ImageShader (foreground painter)
Layer 4:        Child content
Layer 3:        Inner shadow (background painter)
Layer 2:        Specular gradient (background painter, full-bleed)
Layer 1:        Tint layer (background painter, full-bleed)
Layer 0 (base): BackdropFilter.grouped — saturation ColorFilter (vibrancy) ∘ Gaussian blur
```

All decorative layers (1–3, 5–6 plus vibrancy) scale with `effectIntensity`
via `LiquidGlassThemeData.scaleEffects`; at `0.0` only the blur + tint
material remains.

## Data Flow

```
User Input (tap/drag)
    │
    ├─► GestureDetector → State Update (_position, _velocity)
    │       │
    │       ▼
    │   _controller (SpringSimulation) → Selector Animation
    │       │
    │       ▼
    │   CustomPainter (_SelectorPainter) → Visual Update
    │       │
    │       ▼
    │   Icon/Label Color Interpolation (proximity-based)
    │       │
    │       ▼
    │   onTap Callback → Parent Widget
    │
    └─► _elasticController (SpringSimulation) → Rubber Band Scale
            │
            ▼
        Transform.scale → Bar Expansion/Contraction
```

## Performance Architecture

- **RepaintBoundary** isolates the glass surface from the ancestor tree; a second boundary isolates the selector + tab items from the glass
- **Value-equal themes**: `LiquidGlassThemeData` implements `==`/`hashCode`, presets are canonical const instances, and painters compare by value in `shouldRepaint` — unchanged glass never repaints across rebuilds
- **Pre-baked noise**: the grain is rendered once per DPR into a repeating `ui.Image` tile (`Picture.toImageSync`) and drawn with an `ImageShader`; the paint color's alpha modulates opacity, so no re-bake on theme changes
- **Single backdrop pass**: vibrancy is a saturation `ColorFilter` composed with the blur — no `BlendMode.overlay` advanced-blend layer
- **No per-frame Gaussians**: selector bloom and icon halos are gradient/concentric fills, not `MaskFilter.blur`
- **Shared readbacks**: `BackdropFilter.grouped` lets sibling glass surfaces under a `BackdropGroup` share one backdrop snapshot per frame
- **saveLayer** avoided (press feedback is a scrim, not an `Opacity` layer)
- **const constructors** used wherever possible

## Public API Surface

Exported via `lib/cupertino_liquid_glass.dart`:

| Export | Type | Purpose |
|--------|------|---------|
| `CupertinoLiquidGlass` | Widget | Core glass effect |
| `LiquidGlassThemeData` | Data | Theme configuration |
| `CupertinoLiquidGlassNavBar` | Widget | Navigation bar preset |
| `CupertinoLiquidGlassBottomBar` | Widget | Bottom tab bar preset |
| `LiquidGlassBottomBarItem` | Data | Tab item definition |
| `LiquidGlassBloom` | Widget | Glow effect |
| `LiquidGlassDetachedButton` | Widget | Detached circular glass action button (slottable into either bar) |
