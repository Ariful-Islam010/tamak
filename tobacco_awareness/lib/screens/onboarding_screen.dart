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

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "ধূমপান ছাড়ার সময় এখনই! 👿⚔️",
      "description": "নিকোটিন নামক দুষ্ট ডেমনকে হারিয়ে একটি নতুন এবং সুস্থ জীবনের পথে আজই প্রথম পদক্ষেপ নিন।",
      "gradient": AppTheme.heroGradient,
      "cartoon": const DemonCartoonWidget(type: "demon"),
    },
    {
      "title": "নিজেকে নতুনভাবে গড়ুন 🌳✨",
      "description": "প্রতিটি দিন ধূমপানমুক্ত রাখা আপনার তামাকমুক্ত বাগানে একটি সুন্দর সতেজ গাছ বড় করে তোলে।",
      "gradient": AppTheme.greenGradient,
      "cartoon": const DemonCartoonWidget(type: "garden"),
    },
    {
      "title": "টাকা বাঁচান ও রিওয়ার্ড জিতুন 💰🏆",
      "description": "ধূমপান না করে বাঁচানো টাকায় পূরণ করুন আপনার সকল স্বপ্ন ও অর্জন করুন আকর্ষণীয় সব ব্যাজ!",
      "gradient": AppTheme.fireGradient,
      "cartoon": const DemonCartoonWidget(type: "reward"),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentBg = _onboardingData[_currentPage]["gradient"] as LinearGradient;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              currentBg.colors[0].withValues(alpha: 0.15),
              AppTheme.demonDark,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthScreen()),
                      );
                    },
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
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
                    cartoon: _onboardingData[index]["cartoon"]!,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _onboardingData.length,
                          (index) => buildDot(index: index),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == _onboardingData.length - 1) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const AuthScreen()),
                              );
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOutBack,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentBg.colors[0],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                            shadowColor: currentBg.colors[0].withValues(alpha: 0.5),
                          ),
                          child: Text(
                            _currentPage == _onboardingData.length - 1
                                ? "Start Journey! 🚀"
                                : "Next ➡️",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AnimatedContainer buildDot({required int index}) {
    final currentBg = _onboardingData[_currentPage]["gradient"] as LinearGradient;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(right: 8),
      height: 10,
      width: _currentPage == index ? 28 : 10,
      decoration: BoxDecoration(
        color: _currentPage == index ? currentBg.colors[0] : Colors.white24,
        borderRadius: BorderRadius.circular(5),
        boxShadow: _currentPage == index
            ? [
                BoxShadow(
                  color: currentBg.colors[0].withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String title, description;
  final Widget cartoon;

  const OnboardingContent({
    super.key,
    required this.title,
    required this.description,
    required this.cartoon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: cartoon,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class DemonCartoonWidget extends StatefulWidget {
  final String type;
  const DemonCartoonWidget({super.key, required this.type});

  @override
  State<DemonCartoonWidget> createState() => _DemonCartoonWidgetState();
}

class _DemonCartoonWidgetState extends State<DemonCartoonWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: _buildArtwork(),
          ),
        );
      },
    );
  }

  Widget _buildArtwork() {
    if (widget.type == "demon") {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Glowing background bubble
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentPink.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Cute monster/demon box
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              color: AppTheme.demonMid,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: AppTheme.accentPink, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentPink.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Angry glowing yellow eyes
                    Text("👿", style: TextStyle(fontSize: 80)),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  "NICOTINE DEMON",
                  style: TextStyle(
                    color: AppTheme.accentPink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          // Sword icon slicing demon
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppTheme.accentYellow,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.black, size: 28),
            ),
          ),
        ],
      );
    } else if (widget.type == "garden") {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentLime.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: AppTheme.accentLime, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentLime.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("🌲", style: TextStyle(fontSize: 80)),
                SizedBox(height: 8),
                Text(
                  "MY QUIT FOREST",
                  style: TextStyle(
                    color: AppTheme.accentLime,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.water_drop, color: Colors.white, size: 24),
            ),
          ),
        ],
      );
    } else {
      // reward
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentYellow.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: AppTheme.accentYellow, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentYellow.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("🏆", style: TextStyle(fontSize: 80)),
                SizedBox(height: 8),
                Text(
                  "DREAMS & BADGES",
                  style: TextStyle(
                    color: AppTheme.accentYellow,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 15,
            bottom: 15,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.accentOrange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.savings, color: Colors.white, size: 28),
            ),
          ),
        ],
      );
    }
  }
}
