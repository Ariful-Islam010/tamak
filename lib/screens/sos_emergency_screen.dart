import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';

class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key});

  @override
  State<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

class _SosEmergencyScreenState extends State<SosEmergencyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _timer;
  
  bool _isWaitingMode = false;
  bool _isBreathingMode = false;
  int _secondsRemaining = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // 4-7-8 approximation
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startWaitTimer() {
    setState(() {
      _isWaitingMode = true;
      _isBreathingMode = false;
      _secondsRemaining = 300;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isWaitingMode = false;
        });
      }
    });
  }

  void _startBreathing() {
    setState(() {
      _isBreathingMode = true;
      _isWaitingMode = false;
    });
    _timer?.cancel();
    _animationController.repeat(reverse: true);
  }

  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    
    // Bengali translation
    String minStr = minutes.toString().replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২').replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫').replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮').replaceAll('9', '৯');
    String secStr = seconds.toString().padLeft(2, '0').replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২').replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫').replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮').replaceAll('9', '৯');
    
    return '$minStr:$secStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF7D6), Color(0xFFE3F2FD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                "ইচ্ছেটা মাত্র ৫ মিনিটেই কমে যাবে!",
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontSize: 28,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "নিচের যেকোনো একটি উপায় বেছে নিন",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textLight,
                    ),
              ),
              const SizedBox(height: 40),

              if (!_isWaitingMode && !_isBreathingMode) ...[
                // Selection Menu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildActionOption(
                        "দয়া করে ৫ মিনিট অপেক্ষা করুন",
                        Icons.timer,
                        AppTheme.accentOrange,
                        _startWaitTimer,
                      ),
                      const SizedBox(height: 16),
                      _buildActionOption(
                        "৪-৭-৮ শ্বাস-প্রশ্বাস",
                        Icons.air,
                        AppTheme.primaryBlue,
                        _startBreathing,
                      ),
                    ],
                  ),
                ),
              ] else if (_isWaitingMode) ...[
                // Wait Mode
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentOrange.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, color: AppTheme.accentOrange, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _formattedTime,
                          style: const TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_isBreathingMode) ...[
                // Breathing Mode
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Container(
                          width: 150 + (_animationController.value * 100),
                          height: 150 + (_animationController.value * 100),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryBlue.withOpacity(0.1 + (_animationController.value * 0.2)),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryBlue,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.air, color: AppTheme.white, size: 48),
                      ),
                    ),
                  ],
                ),
              ],
              
              if (_isWaitingMode || _isBreathingMode) ...[
                const SizedBox(height: 40),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isWaitingMode = false;
                      _isBreathingMode = false;
                      _timer?.cancel();
                      _animationController.stop();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("অন্য উপায় বেছে নিন"),
                ),
              ],

              const Spacer(),

              // Distraction Cards (Always present)
              SizedBox(
                height: 150,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildDistractionCard("এক গ্লাস পানি খান", Icons.water_drop, Colors.blue),
                    _buildDistractionCard("বন্ধুকে কল করুন", Icons.call, Colors.green),
                    _buildDistractionCard("হাঁটাহাঁটি করুন", Icons.directions_walk, Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionOption(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDistractionCard(String title, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
