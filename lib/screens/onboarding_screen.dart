import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/sight_controller.dart';
import '../core/constants/app_colors.dart';
import '../widgets/accessible_button.dart';
import '../widgets/accessible_header.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Voice Commands First',
      'desc': 'Speak anytime: "Describe surroundings", "Read text", "Identify medicine", "Recognize currency", or "Detect obstacles".',
      'icon': Icons.mic_rounded,
      'color': AppColors.primaryYellow,
      'audio': 'Voice commands first. You can speak anytime to activate any feature.'
    },
    {
      'title': 'Surroundings & Context',
      'desc': 'Gemini Vision describes objects, people, and spatial directions around you in real-time.',
      'icon': Icons.remove_red_eye_rounded,
      'color': AppColors.secondaryCyan,
      'audio': 'Describe Surroundings uses Gemini Vision to explain who and what is around you with directional awareness.'
    },
    {
      'title': 'Read Text & Documents',
      'desc': 'Fast OCR reads books, signboards, notices, medicine labels, and bus numbers aloud.',
      'icon': Icons.menu_book_rounded,
      'color': AppColors.readText,
      'audio': 'Read text uses OCR to instantly read signboards, documents, notices, and bus numbers aloud.'
    },
    {
      'title': 'Medicine Assistance',
      'desc': 'Verifies medicine packaging, active salt, dosage, and expiry dates with strict safety checks.',
      'icon': Icons.medication_rounded,
      'color': AppColors.medicine,
      'audio': 'Medicine assistance reads strip packaging, expiry dates, and dosage with safety warnings.'
    },
    {
      'title': 'Indian Currency Recognition',
      'desc': 'Identifies Indian Rupee banknotes (₹10 to ₹2000) and coins, guiding you if the note is folded.',
      'icon': Icons.account_balance_wallet_rounded,
      'color': AppColors.currency,
      'audio': 'Recognize currency identifies Indian Rupee banknotes and coins, and prompts you if repositioning is needed.'
    },
    {
      'title': 'Obstacle & Hazard Detection',
      'desc': 'Provides urgent directional audio alerts for stairs, curbs, approaching vehicles, and walking paths.',
      'icon': Icons.warning_rounded,
      'color': AppColors.hazards,
      'audio': 'Detect obstacles alerts you to stairs, curbs, vehicles, and hazards in your walking path.'
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _narrateCurrentSlide();
    });
  }

  void _narrateCurrentSlide() {
    final controller = Provider.of<SightController>(context, listen: false);
    controller.speakCurrentLanguage(_slides[_currentIndex]['audio']);
  }

  void _nextPage() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AccessibleHeader(
              title: 'SightAssist Guide',
              trailing: TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryYellow,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) {
                  setState(() => _currentIndex = idx);
                  _narrateCurrentSlide();
                },
                itemBuilder: (context, index) {
                  final item = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: item['color'],
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(
                            item['icon'],
                            size: 72,
                            color: AppColors.textInverse,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          item['title'],
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item['desc'],
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: i == _currentIndex ? 24 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: i == _currentIndex ? AppColors.primaryYellow : AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: AccessibleButton(
                label: _currentIndex == _slides.length - 1 ? 'Start SightAssist' : 'Next Tip',
                onPressed: _nextPage,
                backgroundColor: AppColors.primaryYellow,
                textColor: AppColors.textInverse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
