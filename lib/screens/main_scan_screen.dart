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
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1A2744),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/app_icon.png', height: 24, errorBuilder: (_,__,___) => const Icon(Icons.qr_code_scanner, color: Color(0xFF00ACC1), size: 24)),
                  const SizedBox(width: 10),
                  const Text(
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
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A0E1A), Color(0xFF1A2744), Color(0xFF243455)],
                  ),
                ),
                child: Center(
                  child: Consumer<PcConnector>(
                    builder: (context, pc, _) {
                      return Container(
                        margin: const EdgeInsets.only(top: 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: pc.isConnected ? Colors.green.withAlpha(40) : Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: pc.isConnected ? Colors.green.withAlpha(100) : Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(pc.isConnected ? Icons.check_circle : Icons.error_outline, 
                                 color: pc.isConnected ? Colors.greenAccent : Colors.white60, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              pc.isConnected ? 'Connected to PC' : 'Offline Mode',
                              style: TextStyle(color: pc.isConnected ? Colors.greenAccent : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
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
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                'QUICK SCAN MODES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white38 : Colors.grey.shade600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildListDelegate([
                _ScanCard(
                  icon: Icons.qr_code_scanner,
                  label: 'Single Scan',
                  subtitle: 'One by one',
                  color: const Color(0xFF00ACC1),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SingleScanScreen())),
                ),
                _ScanCard(
                  icon: Icons.inventory_2_rounded,
                  label: 'Batch Scan',
                  subtitle: 'Continuous',
                  color: const Color(0xFFF57C00),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BatchScanScreen())),
                ),
              ]),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            sliver: SliverToBoxAdapter(
              child: _SupportCard(
                icon: Icons.help_outline_rounded,
                title: 'Help & User Guide',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpGuideScreen())),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ScanCard({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withAlpha(60), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 16),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _SupportCard({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.black12,
      leading: Icon(icon, color: const Color(0xFF00ACC1)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}
