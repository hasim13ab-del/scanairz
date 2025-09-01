import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'batch_scan_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'pc_sync_screen.dart';
import 'help_section_screen.dart';
import 'main_scan_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_navbar.dart';

class MainAppShell extends ConsumerStatefulWidget {
  const MainAppShell({super.key});

  @override
  ConsumerState<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends ConsumerState<MainAppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    BatchScanScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        title: const Text('Scanairz'),
        backgroundColor: AppTheme.darkNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.scanner),
            onPressed: () {
              _navigateToScreen(const MainScanScreen());
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              _navigateToScreen(const PcSyncScreen());
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.darkNavy,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xCCE94560), // AppTheme.primaryRed with 80% opacity
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: Color(0xFFE94560), // AppTheme.primaryRed
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Scanairz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Professional Scanner',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.scanner, color: Colors.white),
              title: const Text('Scan Barcode', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen(const MainScanScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Colors.white),
              title: const Text('Batch Scan', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 0;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.white),
              title: const Text('Scan History', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 1;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 2;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync, color: Colors.white),
              title: const Text('PC Sync', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen(const PcSyncScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.white),
              title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen(const HelpSectionScreen());
              },
            ),
            const Divider(color: Color(0x3DFFFFFF)), // White with 24% opacity
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.white),
              title: const Text('Exit', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Add exit logic if needed
              },
            ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomNavbar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: () {
          _navigateToScreen(const MainScanScreen());
        },
        backgroundColor: const Color(0xFFE94560), // AppTheme.primaryRed
        child: const Icon(Icons.scanner),
      ) : null,
    );
  }
}