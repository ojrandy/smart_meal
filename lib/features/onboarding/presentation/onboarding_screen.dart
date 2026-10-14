import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Welcome to SmartMeal",
      "subtitle":
          "Discover meals you will enjoy with AI-powered recommendations tailored to your taste.",
      "image": "assets/images/bckimg1.png",
    },
    {
      "title": "Plan Your Meals",
      "subtitle":
          "Manage your budget and plan your weekly recipes efficiently with intelligent tracking.",
      "image": "assets/images/bckimg2.png",
    },
    {
      "title": "Smarter Food Decisions",
      "subtitle":
          "Get personalized recommendations and insights to make healthier food choices",
      "image": "assets/images/bckimg3.png",
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    context.go('/auth/login');
  }

  void _onNext() {
    if (_currentIndex == _onboardingData.length - 1) {
      context.go('/auth/login');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _onboardingData[index]["image"]!,
                    fit: BoxFit.cover,
                  ),
                  // Gradient shadow
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0.5, 0.75, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 24,
                    right: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _onboardingData[index]["title"]!,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    36, // Increased font size as requested
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _onboardingData[index]["subtitle"]!,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white70,
                                fontSize:
                                    20, // Increased font size as requested
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 56,
                        ), // Increased from 32 to push title and paragraph up
                        // Page Indicator
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            _onboardingData.length,
                            (indicatorIndex) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: _currentIndex == indicatorIndex ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentIndex == indicatorIndex
                                    ? AppColors.primary
                                    : Colors.white54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Next / Start Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentIndex == _onboardingData.length - 1
                                      ? "Get started"
                                      : "Next",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_currentIndex ==
                                    _onboardingData.length - 1) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // Skip Button at Top Right
          Positioned(
            top: 60,
            right: 24,
            child: TextButton(
              onPressed: _onSkip,
              child: const Text(
                "Skip",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
