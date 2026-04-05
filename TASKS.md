# Tasks

## Completed (v0.1.0 — v0.4.0)

- [x] Core `CupertinoLiquidGlass` widget with BackdropFilter blur
- [x] `LiquidGlassThemeData` with light/dark presets
- [x] `CupertinoLiquidGlassNavBar` — floating glass navigation bar
- [x] `CupertinoLiquidGlassBottomBar` — floating glass tab bar
- [x] Multi-layer rendering pipeline (vibrancy, tint, specular, inner shadow, noise, border)
- [x] `LiquidGlassBloom` widget for glow effects
- [x] Theme interpolation with `lerp()` for animated transitions
- [x] Spring physics animation on bottom bar (SpringSimulation)
- [x] Velocity-based selector stretch effect
- [x] Interactive drag gesture support on bottom bar
- [x] Proximity-based icon/label color interpolation
- [x] Bloom glow on active tab selector
- [x] Safe area handling (status bar + home indicator)
- [x] RepaintBoundary performance optimization
- [x] shouldRepaint guards on all custom painters
- [x] Example demo app with scrollable background
- [x] README, CHANGELOG, LICENSE documentation
- [x] Barrel export file for clean public API
- [x] DartDoc comments on all public APIs
- [x] Bottom bar with 56pt height, 28pt icons, 48pt touch targets
- [x] Rubber banding (8% elasticity) on bottom bar horizontal drag
- [x] Glass refraction glow and dock-style magnification on icons
- [x] Theme values aligned with UIBlurEffect.systemChromeMaterial
- [x] Light/dark theme toggle in example app
- [x] pub.dev description length fix (160/160 points)

## Planned

### High Priority
- [ ] Widget tests for `CupertinoLiquidGlass` (golden tests for visual regression)
- [ ] Widget tests for `CupertinoLiquidGlassNavBar`
- [ ] Widget tests for `CupertinoLiquidGlassBottomBar` (tap, drag, animation)
- [ ] Theme tests for `LiquidGlassThemeData` (copyWith, lerp, factories)
- [ ] `CupertinoLiquidGlassAppBar` — SliverAppBar-style collapsible glass header
- [ ] `CupertinoLiquidGlassSheet` — modal bottom sheet with glass surface
- [ ] `CupertinoLiquidGlassCard` — dedicated card widget with glass styling

### Medium Priority
- [ ] Haptic feedback integration on bottom bar tab changes (iOS)
- [ ] Accessibility: semantic labels and contrast compliance
- [ ] Animation curve customization on nav bar transitions
- [ ] `CupertinoLiquidGlassButton` — glass-styled action button
- [ ] `CupertinoLiquidGlassSegmentedControl` — glass segmented picker
- [ ] InheritedWidget-based theme propagation (LiquidGlassTheme ancestor)
- [ ] Animated theme transitions (light/dark crossfade with lerp)

### Low Priority
- [ ] CI/CD pipeline (GitHub Actions: analyze, test, publish)
- [ ] Performance benchmarks and profiling documentation
- [ ] Screenshot automation for pub.dev listing
- [ ] Additional example scenes (settings page, chat UI, music player)
- [ ] Web-specific optimizations (CanvasKit vs HTML renderer)
