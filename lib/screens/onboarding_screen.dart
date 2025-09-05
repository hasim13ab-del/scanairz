
import 'package:flutter/material.dart';
import 'package:scanairz/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              _buildPage(
                title: "Welcome to ScanAiRZ",
                description: "Ditch the clunky scanner. Your phone is all you need.",
                imagePath: "assets/images/illustrate the replacement of traditional barcode scanner with the mobile app.jpg",
              ),
              _buildPage(
                title: "Effortless Inventory Management",
                description:
                    "Effortlessly track inventory. Scan and log items in seconds.",
                imagePath: "assets/images/mobile scanning barcode for inventory illustrate.jpg",
              ),
              _buildPage(
                title: "Seamless PC Connectivity",
                description:
                    "Sync scans to your PC. Connect via Wi-Fi, Bluetooth, or USB.",
                imagePath: "assets/images/smartphone  wifi connecting it to a desktop computer, suggesting data transfer of a scanned barcode.add blueetoth and wifi usb logo.jpg",
              ),
            ],
          ),
          Positioned(
            bottom: 80,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    3,
                    (index) => _buildDot(index: index),
                  ),
                ),
                if (_currentPage == 2)
                  ElevatedButton(
                    onPressed: _completeOnboarding,
                    child: const Text("Get Started"),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
      {required String title,
      required String description,
      required String imagePath}) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FractionallySizedBox(
            widthFactor: 0.6,
            child: Image.asset(imagePath),
          ),
          const SizedBox(height: 50),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required int index}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
