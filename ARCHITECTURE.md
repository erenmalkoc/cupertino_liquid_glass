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

**File:** `lib/src/cupertino_liquid_glass_widget.dart` (~465 lines)

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

### 2. LiquidGlassThemeData (Theme System)

**File:** `lib/src/liquid_glass_theme.dart` (~268 lines)

Immutable configuration object controlling every visual parameter of the glass effect.

**Factories:**
- `LiquidGlassThemeData.light()` — Bright, matte preset (lower sigma, brighter tint)
- `LiquidGlassThemeData.dark()` — Deep, contrasty preset (higher sigma, darker tint)

**Key Methods:**
- `copyWith(...)` — Returns modified copy
- `static lerp(a, b, t)` — Smooth animated transitions between themes

**Theme Resolution Flow:**
1. Read ambient brightness from `CupertinoTheme.brightnessOf(context)`
2. If explicit `theme` provided, use it; otherwise auto-select light/dark factory
3. Merge any explicit parameter overrides on top
4. Return fully resolved theme

### 3. CupertinoLiquidGlassNavBar

**File:** `lib/src/liquid_glass_nav_bar.dart` (~95 lines)

Pre-built floating navigation bar. Stateless wrapper around `CupertinoLiquidGlass`.

```
CupertinoLiquidGlassNavBar
└── Padding (SafeArea top + horizontal margins)
    └── CupertinoLiquidGlass
        └── Row: [leading] [Expanded title] [trailing]
```

### 4. CupertinoLiquidGlassBottomBar

**File:** `lib/src/liquid_glass_bottom_bar.dart` (~420 lines)

Pre-built floating tab bar with spring physics, velocity-based stretch, and drag interaction.

```
CupertinoLiquidGlassBottomBar (StatefulWidget)
└── Padding (SafeArea bottom + horizontal margins)
    └── CupertinoLiquidGlass
        └── LayoutBuilder
            └── GestureDetector (tap + horizontal drag)
                └── CustomPaint (_SelectorPainter)
                    └── Row: [Expanded Column(Icon, Label)] x N
```

**State Management:**
- `AnimationController` drives spring animations
- `SpringSimulation` provides bouncy transitions (mass: 1.0, stiffness: 380.0, damping: 26.0)
- `_position` (fractional index) tracks selector location
- `_velocity` drives stretch effect during fast movement

**Supporting Class:**
- `LiquidGlassBottomBarItem` — Data class holding `icon`, `activeIcon`, and `label`

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
    ▼
GestureDetector → State Update (_position, _velocity)
    │
    ▼
AnimationController (SpringSimulation)
    │
    ▼
CustomPainter (_SelectorPainter) → Visual Update
    │
    ▼
Icon/Label Color Interpolation (proximity-based)
    │
    ▼
onTap Callback → Parent Widget
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
