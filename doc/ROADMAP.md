# Roadmap

Planned work, roughly by priority. Completed work is tracked in the
[CHANGELOG](../CHANGELOG.md).

## High Priority

- [ ] Golden tests for visual regression (`CupertinoLiquidGlass`, bars)
- [x] Widget tests for `CupertinoLiquidGlassBottomBar` drag gestures (drag commit, boundary haptics, RTL)
- [ ] Widget test for a bottom-bar fling carrying the selection past the finger
- [ ] Align dimensions with the measured iOS 26 floating tab bar (bar 62 pt, 21 pt margins, capsule selection pill, constant-weight labels, no icon magnification — see the FabBar reference)
- [ ] `CupertinoLiquidGlassAppBar` — SliverAppBar-style collapsible glass header
- [ ] `CupertinoLiquidGlassSheet` — modal bottom sheet with glass surface
- [ ] `CupertinoLiquidGlassCard` — dedicated card widget with glass styling

## Medium Priority

- [ ] `MediaQuery.highContrast` / Reduce Transparency handling (auto-raise tint opacity or fall back to solid)
- [ ] Animation curve customization on nav bar transitions
- [ ] `CupertinoLiquidGlassButton` — glass-styled action button
- [ ] `CupertinoLiquidGlassSegmentedControl` — glass segmented picker
- [ ] InheritedWidget-based theme propagation (LiquidGlassTheme ancestor)
- [ ] Animated theme transitions (light/dark crossfade with lerp)

## Low Priority

- [x] CI pipeline (GitHub Actions: format, analyze, test, example test, publish dry-run, minimum-SDK job)
- [ ] Automated pub.dev publishing from tags
- [ ] Performance benchmarks and profiling documentation
- [ ] Screenshot automation for pub.dev listing
- [ ] Additional example scenes (settings page, chat UI, music player)
- [ ] Web-specific optimizations (CanvasKit vs HTML renderer)
