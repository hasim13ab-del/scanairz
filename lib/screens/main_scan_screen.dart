import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanairz/screens/batch_scan_screen.dart';
import 'package:scanairz/screens/help_guide_screen.dart';
import 'package:scanairz/screens/settings_screen.dart';
import 'package:scanairz/screens/single_scan_screen.dart';
import 'package:scanairz/services/pc_connector.dart';

class MainScanScreen extends StatelessWidget {
  const MainScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1A2744),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00ACC1).withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Color(0xFF00ACC1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ScanAiRZ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A0E1A), Color(0xFF1A2744), Color(0xFF243455)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                  child: Consumer<PcConnector>(
                    builder: (context, pc, _) {
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: pc.isConnected
                                  ? const Color(0xFF00ACC1).withAlpha(30)
                                  : Colors.white.withAlpha(15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: pc.isConnected
                                    ? const Color(0xFF00ACC1).withAlpha(100)
                                    : Colors.white.withAlpha(40),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: pc.isConnected ? const Color(0xFF00ACC1) : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  pc.isConnected
                                      ? 'PC Connected'
                                      : 'PC Not Connected',
                                  style: TextStyle(
                                    color: pc.isConnected
                                        ? const Color(0xFF26C6DA)
                                        : Colors.white60,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                tooltip: 'Settings',
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Scan Mode',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white54 : const Color(0xFF546E7A),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildListDelegate([
                _ScanCard(
                  icon: Icons.qr_code_scanner,
                  label: 'Single Scan',
                  subtitle: 'Scan one item at a time',
                  gradientColors: const [Color(0xFF1A2744), Color(0xFF243455)],
                  accentColor: const Color(0xFF00ACC1),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SingleScanScreen()),
                  ),
                ),
                _ScanCard(
                  icon: Icons.inventory_2_rounded,
                  label: 'Batch Scan',
                  subtitle: 'Scan multiple items fast',
                  gradientColors: const [Color(0xFF7B3F00), Color(0xFFF57C00)],
                  accentColor: const Color(0xFFFF9800),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BatchScanScreen()),
                  ),
                ),
              ]),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _ScanCard(
                icon: Icons.help_outline_rounded,
                label: 'Help & Guide',
                subtitle: 'Learn how to use ScanAiRZ',
                gradientColors: const [Color(0xFF0A3D5C), Color(0xFF0D5C8A)],
                accentColor: const Color(0xFF29B6F6),
                tall: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpGuideScreen()),
                ),
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradientColors;
  final Color accentColor;
  final VoidCallback onTap;
  final bool tall;

  const _ScanCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradientColors,
    required this.accentColor,
    required this.onTap,
    this.tall = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withAlpha(80),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: tall
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accentColor, size: 28),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withAlpha(170),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withAlpha(170),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, color: accentColor, size: 16),
                  ],
                ),
        ),
      ),
    );
  }
}
