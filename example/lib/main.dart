import 'package:flutter/cupertino.dart';
import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';

void main() => runApp(const LiquidGlassExampleApp());

// ─────────────────────────────────────────────────────────────────────────────
// App root
// ─────────────────────────────────────────────────────────────────────────────

class LiquidGlassExampleApp extends StatefulWidget {
  const LiquidGlassExampleApp({super.key});

  @override
  State<LiquidGlassExampleApp> createState() => _LiquidGlassExampleAppState();
}

class _LiquidGlassExampleAppState extends State<LiquidGlassExampleApp> {
  bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Liquid Glass Demo',
      theme: CupertinoThemeData(
        brightness: _isDark ? Brightness.dark : Brightness.light,
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: _HomePage(
        isDark: _isDark,
        onToggle: () => setState(() => _isDark = !_isDark),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation shell
// ─────────────────────────────────────────────────────────────────────────────

class _HomePage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const _HomePage({required this.isDark, required this.onToggle});

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _tab = 0;

  static const _titles = ['Gallery', 'Effects', 'Theme'];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _GalleryPage(),
      const _EffectsPage(),
      _ThemePage(isDark: widget.isDark, onToggle: widget.onToggle),
    ];

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          pages[_tab],

          // Floating nav bar with detachedButton
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CupertinoLiquidGlassNavBar(
              title: Text(_titles[_tab]),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: widget.onToggle,
                child: Icon(
                  widget.isDark
                      ? CupertinoIcons.sun_max_fill
                      : CupertinoIcons.moon_fill,
                  size: 22,
                ),
              ),
              detachedButton: LiquidGlassDetachedButton(
                size: 44,
                onTap: () {},
                child: const Icon(CupertinoIcons.plus, size: 20),
              ),
            ),
          ),

          // Floating bottom bar with detachedButton
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CupertinoLiquidGlassBottomBar(
              currentIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
              items: const [
                LiquidGlassBottomBarItem(
                  icon: CupertinoIcons.house,
                  activeIcon: CupertinoIcons.house_fill,
                  label: 'Gallery',
                ),
                LiquidGlassBottomBarItem(
                  icon: CupertinoIcons.star,
                  activeIcon: CupertinoIcons.star_fill,
                  label: 'Effects',
                ),
                LiquidGlassBottomBarItem(
                  icon: CupertinoIcons.gear_alt,
                  activeIcon: CupertinoIcons.gear_alt_fill,
                  label: 'Theme',
                ),
              ],
              detachedButton: LiquidGlassDetachedButton(
                onTap: () {},
                child: const Icon(
                  CupertinoIcons.search,
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Gallery: CupertinoLiquidGlass variants
// ─────────────────────────────────────────────────────────────────────────────

class _GalleryPage extends StatelessWidget {
  const _GalleryPage();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        const Positioned.fill(child: _ColorfulBackground()),
        ListView(
          padding: EdgeInsets.only(
            top: top + 72,
            bottom: 130,
            left: 16,
            right: 16,
          ),
          children: [
            // Default
            const _SectionLabel('Default'),
            const SizedBox(height: 8),
            const CupertinoLiquidGlass(
              padding: EdgeInsets.all(20),
              child: _CardBody(
                title: 'CupertinoLiquidGlass',
                subtitle:
                    'Auto light / dark • specular highlight • edge lighting',
              ),
            ),

            // Blur intensity
            const SizedBox(height: 20),
            const _SectionLabel('Blur Intensity'),
            const SizedBox(height: 8),
            const CupertinoLiquidGlass(
              blurSigma: 45,
              padding: EdgeInsets.all(20),
              child: _CardBody(
                title: 'Thick Frost  —  blurSigma: 45',
                subtitle: 'Strong backdrop diffusion',
              ),
            ),
            const SizedBox(height: 10),
            const CupertinoLiquidGlass(
              blurSigma: 6,
              tintOpacity: 0.15,
              padding: EdgeInsets.all(20),
              child: _CardBody(
                title: 'Thin Glass  —  blurSigma: 6',
                subtitle: 'Background clearly visible through',
              ),
            ),

            // Custom theme
            const SizedBox(height: 20),
            const _SectionLabel('Custom LiquidGlassThemeData'),
            const SizedBox(height: 8),
            CupertinoLiquidGlass(
              theme: const LiquidGlassThemeData(
                tintColor: Color(0xFF007AFF),
                tintOpacity: 0.20,
                blurSigma: 22,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: const _CardBody(
                title: 'Blue Tint',
                subtitle: 'tintColor • custom blurSigma • custom radius',
              ),
            ),

            // Glow
            const SizedBox(height: 20),
            const _SectionLabel('Glow Effect'),
            const SizedBox(height: 8),
            CupertinoLiquidGlass(
              glowColor: CupertinoColors.systemPurple,
              glowRadius: 30,
              padding: const EdgeInsets.all(20),
              child: const _CardBody(
                title: 'Purple Glow',
                subtitle: 'glowColor + glowRadius — bloom around the surface',
              ),
            ),

            // LiquidGlassBloom
            const SizedBox(height: 20),
            const _SectionLabel('LiquidGlassBloom'),
            const SizedBox(height: 8),
            CupertinoLiquidGlass(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _BloomIcon(Color(0xFFFF3B30), CupertinoIcons.heart_fill, 'Heart'),
                  _BloomIcon(Color(0xFF34C759), CupertinoIcons.checkmark_circle_fill, 'Check'),
                  _BloomIcon(Color(0xFF007AFF), CupertinoIcons.bolt_fill, 'Bolt'),
                  _BloomIcon(Color(0xFFAF52DE), CupertinoIcons.star_fill, 'Star'),
                ],
              ),
            ),

            // Detached button
            const SizedBox(height: 20),
            const _SectionLabel('LiquidGlassDetachedButton'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _DetachedDemo(
                  iridescent: true,
                  icon: CupertinoIcons.camera_fill,
                  color: Color(0xFF007AFF),
                  label: 'iridescent',
                ),
                _DetachedDemo(
                  iridescent: false,
                  icon: CupertinoIcons.mic_fill,
                  color: Color(0xFF34C759),
                  label: 'plain',
                ),
                _DetachedDemo(
                  iridescent: true,
                  icon: CupertinoIcons.music_note,
                  color: Color(0xFFFF2D55),
                  label: 'iridescent',
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Effects: Bloom intensities & theme lerp
// ─────────────────────────────────────────────────────────────────────────────

class _EffectsPage extends StatefulWidget {
  const _EffectsPage();

  @override
  State<_EffectsPage> createState() => _EffectsPageState();
}

class _EffectsPageState extends State<_EffectsPage> {
  double _lerpT = 0.0;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final lerped = LiquidGlassThemeData.lerp(
      LiquidGlassThemeData.light(),
      LiquidGlassThemeData.dark(),
      _lerpT,
    );

    return Stack(
      children: [
        const Positioned.fill(child: _ColorfulBackground()),
        ListView(
          padding: EdgeInsets.only(
            top: top + 72,
            bottom: 130,
            left: 16,
            right: 16,
          ),
          children: [
            // Theme lerp
            const _SectionLabel('LiquidGlassThemeData.lerp()'),
            const SizedBox(height: 8),
            CupertinoLiquidGlass(
              theme: lerped,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Light',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Expanded(
                        child: CupertinoSlider(
                          value: _lerpT,
                          onChanged: (v) => setState(() => _lerpT = v),
                        ),
                      ),
                      const Text(
                        'Dark',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'blurSigma: ${lerped.blurSigma.toStringAsFixed(1)}   '
                    'tintOpacity: ${lerped.tintOpacity.toStringAsFixed(2)}   '
                    't = ${_lerpT.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'Menlo',
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),

            // Bloom intensity comparison
            const SizedBox(height: 20),
            const _SectionLabel('LiquidGlassBloom — intensity'),
            const SizedBox(height: 8),
            CupertinoLiquidGlass(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _IntensityBloom(
                    color: Color(0xFFFF3B30),
                    icon: CupertinoIcons.heart_fill,
                    intensity: 0.25,
                    label: '25 %',
                  ),
                  _IntensityBloom(
                    color: Color(0xFFFF9500),
                    icon: CupertinoIcons.star,
                    intensity: 0.50,
                    label: '50 %',
                  ),
                  _IntensityBloom(
                    color: Color(0xFF007AFF),
                    icon: CupertinoIcons.bolt_fill,
                    intensity: 0.75,
                    label: '75 %',
                  ),
                  _IntensityBloom(
                    color: Color(0xFFAF52DE),
                    icon: CupertinoIcons.star_fill,
                    intensity: 1.00,
                    label: '100 %',
                  ),
                ],
              ),
            ),

            // Detached button iridescent comparison
            const SizedBox(height: 20),
            const _SectionLabel('Detached Button — iridescent vs plain'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LiquidGlassDetachedButton(
                      onTap: () {},
                      iridescent: true,
                      child: const Icon(
                        CupertinoIcons.camera_fill,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('iridescent: true',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LiquidGlassDetachedButton(
                      onTap: () {},
                      iridescent: false,
                      child: const Icon(
                        CupertinoIcons.camera_fill,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('iridescent: false',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Theme: Presets & dark-mode toggle
// ─────────────────────────────────────────────────────────────────────────────

class _ThemePage extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const _ThemePage({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        const Positioned.fill(child: _ColorfulBackground()),
        ListView(
          padding: EdgeInsets.only(
            top: top + 72,
            bottom: 130,
            left: 16,
            right: 16,
          ),
          children: [
            // Dark mode toggle
            CupertinoLiquidGlass(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dark Mode',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 17),
                  ),
                  CupertinoSwitch(
                    value: isDark,
                    onChanged: (_) => onToggle(),
                  ),
                ],
              ),
            ),

            // Light preset
            const SizedBox(height: 20),
            const _SectionLabel('Light Preset'),
            const SizedBox(height: 8),
            _ThemeCard(theme: LiquidGlassThemeData.light()),

            // Dark preset
            const SizedBox(height: 20),
            const _SectionLabel('Dark Preset'),
            const SizedBox(height: 8),
            _ThemeCard(theme: LiquidGlassThemeData.dark()),

            // Custom
            const SizedBox(height: 20),
            const _SectionLabel('Custom Theme Example'),
            const SizedBox(height: 8),
            CupertinoLiquidGlass(
              theme: const LiquidGlassThemeData(
                tintColor: Color(0xFF00C7BE),
                tintOpacity: 0.18,
                blurSigma: 35,
                borderRadius: BorderRadius.all(Radius.circular(28)),
                borderWidth: 1.5,
                edgeLightColor: Color(0x80FFFFFF),
                innerShadowBlurRadius: 6,
              ),
              padding: const EdgeInsets.all(20),
              child: const _CardBody(
                title: 'Teal Custom Theme',
                subtitle:
                    'tintColor teal • blurSigma 35 • borderWidth 1.5',
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Soft radial-gradient blobs on a neutral base — provides vivid, organic
/// content for the glass effect to blur and refract, without looking like
/// a flag or a rainbow.
class _ColorfulBackground extends StatelessWidget {
  const _ColorfulBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _BlobPainter(isDark: isDark),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final bool isDark;
  const _BlobPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Neutral base
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color =
            isDark ? const Color(0xFF0C0C14) : const Color(0xFFF0F0F5),
    );

    final blobs = isDark ? _dark : _light;
    for (final b in blobs) {
      final center = Offset(size.width * b.x, size.height * b.y);
      final radius = size.shortestSide * b.r;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [b.color, b.color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  // Light: warm amber top-left, sky-blue top-right,
  //        seafoam center, soft violet bottom-left, blush bottom-right.
  static const _light = [
    _Blob(0.10, 0.18, 1.05, Color(0x88FF9F0A)),
    _Blob(0.88, 0.22, 0.95, Color(0x7030B0FF)),
    _Blob(0.50, 0.52, 0.90, Color(0x6030D158)),
    _Blob(0.12, 0.82, 0.95, Color(0x78BF5AF2)),
    _Blob(0.85, 0.80, 0.90, Color(0x88FF375F)),
  ];

  // Dark: same hues, deeper and more muted.
  static const _dark = [
    _Blob(0.10, 0.18, 1.05, Color(0x60B86800)),
    _Blob(0.88, 0.22, 0.95, Color(0x500060CC)),
    _Blob(0.50, 0.52, 0.90, Color(0x44008830)),
    _Blob(0.12, 0.82, 0.95, Color(0x507A20CC)),
    _Blob(0.85, 0.80, 0.90, Color(0x60CC1040)),
  ];

  @override
  bool shouldRepaint(_BlobPainter old) => isDark != old.isDark;
}

class _Blob {
  final double x, y, r;
  final Color color;
  const _Blob(this.x, this.y, this.r, this.color);
}

/// Small ALLCAPS section header.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}

/// Title + subtitle row used inside glass cards.
class _CardBody extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CardBody({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
        Icon(
          CupertinoIcons.chevron_right,
          size: 16,
          color: CupertinoColors.tertiaryLabel.resolveFrom(context),
        ),
      ],
    );
  }
}

/// Icon wrapped in [LiquidGlassBloom] with a label below.
class _BloomIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _BloomIcon(this.color, this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiquidGlassBloom(
          color: color,
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

/// [LiquidGlassBloom] at a specific [intensity] with a percentage label.
class _IntensityBloom extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double intensity;
  final String label;

  const _IntensityBloom({
    required this.color,
    required this.icon,
    required this.intensity,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiquidGlassBloom(
          color: color,
          intensity: intensity,
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

/// [LiquidGlassDetachedButton] with a caption below.
class _DetachedDemo extends StatelessWidget {
  final bool iridescent;
  final IconData icon;
  final Color color;
  final String label;

  const _DetachedDemo({
    required this.iridescent,
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiquidGlassDetachedButton(
          onTap: () {},
          iridescent: iridescent,
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

/// [CupertinoLiquidGlass] card showing theme property values.
class _ThemeCard extends StatelessWidget {
  final LiquidGlassThemeData theme;

  const _ThemeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return CupertinoLiquidGlass(
      theme: theme,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ThemeRow('blurSigma', theme.blurSigma.toStringAsFixed(1)),
          _ThemeRow('tintOpacity', theme.tintOpacity.toStringAsFixed(2)),
          _ThemeRow('borderWidth', theme.borderWidth.toStringAsFixed(2)),
          _ThemeRow('noiseOpacity', theme.noiseOpacity.toStringAsFixed(3)),
          _ThemeRow('vibrancyIntensity',
              theme.vibrancyIntensity.toStringAsFixed(2)),
          _ThemeRow('innerShadowBlurRadius',
              theme.innerShadowBlurRadius.toStringAsFixed(1)),
        ],
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final String name;
  final String value;

  const _ThemeRow(this.name, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Menlo',
              color: CupertinoColors.systemGrey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Menlo',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
