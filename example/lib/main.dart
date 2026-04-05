import 'package:flutter/cupertino.dart';
import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';

void main() => runApp(const LiquidGlassExampleApp());

/// Root application widget that demonstrates the cupertino_liquid_glass package.
class LiquidGlassExampleApp extends StatelessWidget {
  const LiquidGlassExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Liquid Glass Demo',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: LiquidGlassHomePage(),
    );
  }
}

/// Main demo page showing a scrollable list with a floating glass nav bar
/// at the top and a glass bottom tab bar.
class LiquidGlassHomePage extends StatefulWidget {
  const LiquidGlassHomePage({super.key});

  @override
  State<LiquidGlassHomePage> createState() => _LiquidGlassHomePageState();
}

class _LiquidGlassHomePageState extends State<LiquidGlassHomePage> {
  int _selectedTab = 0;
  final ScrollController _scrollController = ScrollController();

  static const _tabs = ['Home', 'Search', 'Settings'];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // ── Background content that scrolls behind the glass bars ──
          _buildScrollableContent(context),

          // ── Floating glass navigation bar at the top ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CupertinoLiquidGlassNavBar(
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {},
                child: const Icon(CupertinoIcons.back, size: 22),
              ),
              title: Text(_tabs[_selectedTab]),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {},
                child: const Icon(CupertinoIcons.ellipsis_circle, size: 22),
              ),
            ),
          ),

          // ── Floating glass bottom tab bar ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CupertinoLiquidGlassBottomBar(
              currentIndex: _selectedTab,
              onTap: (index) => setState(() => _selectedTab = index),
              scrollController: _scrollController,
              items: const [
                LiquidGlassBottomBarItem(
                  icon: CupertinoIcons.house,
                  activeIcon: CupertinoIcons.house_fill,
                  label: 'Home',
                ),
                LiquidGlassBottomBarItem(
                  icon: CupertinoIcons.search,
                  label: 'Search',
                ),
                LiquidGlassBottomBarItem(
                  icon: CupertinoIcons.gear_alt,
                  activeIcon: CupertinoIcons.gear_alt_fill,
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a long scrollable list with colourful cards to demonstrate the
  /// blur effect as content passes behind the glass bars.
  Widget _buildScrollableContent(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(top: topPadding + 70, bottom: 120),
      itemCount: 30,
      itemBuilder: (context, index) {
        // Cycle through Cupertino system colours for visual variety.
        final colors = [
          CupertinoColors.systemRed,
          CupertinoColors.systemOrange,
          CupertinoColors.systemYellow,
          CupertinoColors.systemGreen,
          CupertinoColors.systemTeal,
          CupertinoColors.systemBlue,
          CupertinoColors.systemIndigo,
          CupertinoColors.systemPurple,
          CupertinoColors.systemPink,
        ];
        final color = colors[index % colors.length];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: _GlassCard(index: index, accentColor: color),
        );
      },
    );
  }
}

/// A single demo card that wraps its content in [CupertinoLiquidGlass].
class _GlassCard extends StatelessWidget {
  final int index;
  final Color accentColor;

  const _GlassCard({required this.index, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return CupertinoLiquidGlass(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liquid Glass Card ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Frosted blur effect with specular highlight',
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
      ),
    );
  }
}
