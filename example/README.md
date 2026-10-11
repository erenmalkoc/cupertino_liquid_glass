# cupertino_liquid_glass_example

A demo app for the [cupertino_liquid_glass](https://pub.dev/packages/cupertino_liquid_glass)
package. It shows every widget over a colorful background, with a
`CupertinoLiquidGlassNavBar` at the top and a `CupertinoLiquidGlassBottomBar`
at the bottom (each with a `LiquidGlassDetachedButton` slotted in) switching
between three tabs:

- **Gallery**: `CupertinoLiquidGlass` surfaces with different blur, tint and
  glow settings, `LiquidGlassBloom` and detached buttons.
- **Effects**: live sliders for `effectIntensity` and for
  `LiquidGlassThemeData.lerp` between the light and dark presets, bloom
  intensities and iridescent vs. plain detached buttons.
- **Theme**: dark mode and glass on/off toggles (the solid fallback), the
  light and dark presets and a custom theme.

## Running

The example depends on the package through a path dependency, so it always
uses the code in this repository.

```sh
cd example
flutter pub get
flutter run
```

Run its smoke test with `flutter test`.
