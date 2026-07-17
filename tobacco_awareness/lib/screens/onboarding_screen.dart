import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "ধূমপান ছাড়ার সময় এখনই!",
      "description": "একটি নতুন এবং সুস্থ জীবনের পথে আজই প্রথম ধাপ ফেলুন।",
      "image": "assets/images/onboarding1.png", // Placeholder
    },
    {
      "title": "নিজেকে নতুনভাবে গড়ুন।",
      "description": "প্রতিটি দিন ধূমপানমুক্ত থাকা আপনার জন্য একটি নতুন বিজয়।",
      "image": "assets/images/onboarding2.png", // Placeholder
    },
    {
      "title": "স্বাস্থ্যই আপনার শক্তি।",
      "description": "সুস্থ শরীর ও মন নিয়ে পরিবার ও নিজের জন্য এগিয়ে যান।",
      "image": "assets/images/onboarding3.png", // Placeholder
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.loginBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) => OnboardingContent(
                  title: _onboardingData[index]["title"]!,
                  description: _onboardingData[index]["description"]!,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => buildDot(index: index),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _onboardingData.length - 1) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const AuthScreen()),
                            );
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                          }
                        },
                        child: Text(
                          _currentPage == _onboardingData.length - 1
                              ? "Start Your Journey"
                              : "Next",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AnimatedContainer buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppTheme.primaryBlue : AppTheme.textLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String title, description;

  const OnboardingContent({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Placeholder
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.favorite_rounded, size: 100, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textLight,
                ),
          ),
        ],
      ),
    );
  }
}
