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

**File:** `lib/src/cupertino_liquid_glass_widget.dart` (~660 lines)

Wraps any child widget in an Apple-style liquid glass surface. Stateless; all rendering is handled by internal painters.

**Widget Tree:**
```
CupertinoLiquidGlass (StatelessWidget)
└── RepaintBoundary
    └── Container (BoxDecoration + optional glow shadow)
        └── ClipRRect (clips to borderRadius)
            └── BackdropFilter (ImageFilter.blur)
                └── _GlassSurface
                    └── CustomPaint
                        ├── painter: _GlassBackgroundPainter
                        ├── foregroundPainter: _GlassForegroundPainter
                        └── Padding → child
```

**Internal Classes:**
- `_GlassSurface` — Compositing widget that stacks background & foreground painters around child content
- `_GlassBackgroundPainter` — Paints vibrancy overlay, tint layer, specular gradient, inner shadow
- `_GlassForegroundPainter` — Paints noise grain texture and edge-lit gradient border
- `LiquidGlassBloom` — Renders soft colored radial glow behind content via `_BloomPainter`
- `LiquidGlassDetachedButton` — Public stateful widget; circular floating glass action button. Stacks `CupertinoLiquidGlass` + an optional `_IridescentPainter` sweep gradient and drives a press animation via `AnimationController` (scale to 88%, opacity to 78%, elastic release).
- `_IridescentPainter` — Sweep-gradient overlay simulating prismatic light refraction.

### 2. LiquidGlassThemeData (Theme System)

**File:** `lib/src/liquid_glass_theme.dart` (~268 lines)

Immutable configuration object controlling every visual parameter of the glass effect.

**Factories:**
- `LiquidGlassThemeData.light()` — Bright, matte preset (sigma 25, white tint 65% opacity)
- `LiquidGlassThemeData.dark()` — Deep, contrasty preset (sigma 28, dark tint 55% opacity)

**Key Methods:**
- `copyWith(...)` — Returns modified copy
- `static lerp(a, b, t)` — Smooth animated transitions between themes

**Theme Resolution Flow:**
1. Read ambient brightness from `CupertinoTheme.brightnessOf(context)`
2. If explicit `theme` provided, use it; otherwise auto-select light/dark factory
3. Merge any explicit parameter overrides on top
4. Return fully resolved theme

### 3. CupertinoLiquidGlassNavBar

**File:** `lib/src/liquid_glass_nav_bar.dart` (~128 lines)

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

**File:** `lib/src/liquid_glass_bottom_bar.dart` (~420 lines)

Pre-built floating tab bar with spring physics, velocity-based stretch, and drag interaction.

```
CupertinoLiquidGlassBottomBar (StatefulWidget)
└── Padding (SafeArea bottom + horizontal margins)
    └── (detachedButton == null)
        ? mainBar
        : Row(crossAxis: end)
            ├── Expanded(mainBar)
            └── detachedButton  (rubber banding does NOT apply)

where mainBar = (optional) Transform.scale(_elasticScale)
                  └── CupertinoLiquidGlass
                      └── LayoutBuilder
                          └── GestureDetector (tap + horizontal drag)
                              └── CustomPaint (_SelectorPainter)
                                  └── Row: [Expanded Column(_GlassIcon, Label)] x N
```

**State Management:**
- `_controller` (`AnimationController`) drives spring-based selector animations
- `_elasticController` (`AnimationController`) drives rubber banding scale
- `SpringSimulation` provides bouncy transitions (mass: 1.0, stiffness: 320.0, damping: 22.0)
- `_position` (fractional index) tracks selector location
- `_velocity` drives stretch effect during fast movement
- `_elasticScale` tracks rubber banding scale (1.0 rest, 1.08 expanded)

**Rubber Banding (Elasticity):**
- On `onHorizontalDragStart`: bar scales up to 108% via spring animation
- On `onHorizontalDragEnd`: bar springs back to 100%
- Anchor point: `Alignment.bottomCenter` (expands upward)
- Spring: mass 1.0, stiffness 300.0, damping 20.0 (slight overshoot)

**Glass Icon Effect:**
- Dock-style magnification: icons scale up to 118% based on selector proximity
- `_GlassIcon` widget wraps each icon with `_GlassIconPainter`
- Outer colored glow: radial bloom in `activeColor` behind icon
- Inner specular highlight: bright dot at top of icon for glass refraction
- All effects interpolate smoothly with proximity (0.0 → 1.0)

**Bar Dimensions:**
- Bar height: 56 pt (`_kTabBarHeight`)
- Icon size: 28 pt (`_kIconSize`)
- Touch target: 48 pt minimum (`_kMinHitTarget`)
- Label font: 11 pt (`_kLabelFontSize`)

**Supporting Classes:**
- `LiquidGlassBottomBarItem` — Data class holding `icon`, `activeIcon`, and `label`
- `_GlassIcon` — Widget rendering icon with glass refraction glow
- `_GlassIconPainter` — CustomPainter for proximity-based glass halo

## Multi-Layer Rendering Pipeline

The glass effect is achieved through 7 composited visual layers:

```
Layer 7 (top):  Edge-lit gradient border (foreground painter)
Layer 6:        Noise grain texture (foreground painter)
Layer 5:        Child content
Layer 4:        Inner shadow (background painter)
Layer 3:        Specular gradient (background painter)
Layer 2:        Tint layer (background painter)
Layer 1:        Vibrancy overlay with BlendMode.overlay (background painter)
Layer 0 (base): BackdropFilter Gaussian blur
```

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

- **RepaintBoundary** isolates glass surface from ancestor tree
- **shouldRepaint** guards on painters check `identical(theme, oldDelegate.theme)`
- **Seeded Random(42)** ensures consistent noise grain without recalculation
- **Density-based grain** scales point count with surface area: `(w*h/20).clamp(100,5000)`
- **saveLayer** avoided in favor of BackdropFilter compositing
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
