
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanairz/screens/onboarding_screen.dart';
import 'package:scanairz/services/pc_connector.dart';
import 'package:scanairz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scanairz/screens/batches_screen.dart';
import 'package:scanairz/screens/history_screen.dart';
import 'package:scanairz/screens/main_scan_screen.dart';
import 'package:scanairz/screens/pc_sync_screen.dart';
import 'package:scanairz/screens/settings_screen.dart';
import 'package:scanairz/services/settings_service.dart';
import 'package:scanairz/theme_notifier.dart';
import 'package:scanairz/themes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:scanairz/services/remote_config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
  final remoteConfigService = await RemoteConfigService.create();
  final settingsService = SettingsService();
  final storageService = StorageService();
  final pcConnector = PcConnector();

  runApp(
    MultiProvider(
      providers: [
        Provider<RemoteConfigService>.value(value: remoteConfigService),
        Provider<SettingsService>.value(value: settingsService),
        Provider<StorageService>.value(value: storageService),
        Provider<PcConnector>.value(value: pcConnector),
      ],
      child: AiRZApp(onboardingComplete: onboardingComplete),
    ),
  );
}

class AiRZApp extends StatefulWidget {
  final bool onboardingComplete;
  const AiRZApp({super.key, required this.onboardingComplete});

  @override
  State<AiRZApp> createState() => _AiRZAppState();
}

class _AiRZAppState extends State<AiRZApp> {
  Future<ThemeData>? _initialThemeFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initialThemeFuture ??= _getInitialTheme(context);
  }

  Future<ThemeData> _getInitialTheme(BuildContext context) async {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    final settings = await settingsService.loadSettings();
    final String theme = settings['theme'] ?? 'System';
    if (theme == 'Light') {
      return AppThemes.lightTheme;
    } else if (theme == 'Dark') {
      return AppThemes.darkTheme;
    } else {
      if (brightness == Brightness.dark) {
        return AppThemes.darkTheme;
      } else {
        return AppThemes.lightTheme;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeData>(
      future: _initialThemeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        } else if (snapshot.hasError || !snapshot.hasData) {
          // Handle error or no data case. For simplicity, defaulting to light theme.
          return const MaterialApp(home: Scaffold(body: Center(child: Text('Error loading theme'))));
        } else {
          return ChangeNotifierProvider<ThemeNotifier>(
            create: (_) => ThemeNotifier(snapshot.data!),
            child: Consumer<ThemeNotifier>(
              builder: (context, themeNotifier, child) {
                return MaterialApp(
                  title: 'ScanAiRZ',
                  theme: themeNotifier.getTheme(),
                  home: widget.onboardingComplete ? const MainScreen() : const OnboardingScreen(),
                );
              },
            ),
          );
        }
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    MainScanScreen(),
    HistoryScreen(),
    BatchesScreen(),
    PcSyncScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Batches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sync),
            label: 'PC Sync',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
