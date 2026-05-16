import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuitPlanScreen extends StatefulWidget {
  const QuitPlanScreen({super.key});

  @override
  State<QuitPlanScreen> createState() => _QuitPlanScreenState();
}

class _QuitPlanScreenState extends State<QuitPlanScreen> {
  int _currentStep = 0;
  int? _selectedDuration;
  final List<String> _selectedTriggers = [];
  
  final List<int> _durations = [7, 14, 30];
  final List<String> _triggers = ["মানসিক চাপ", "বন্ধুদের আড্ডা", "একঘেয়েমি", "কাজের চাপ", "সকালের চা/কফি", "খাবারের পর"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("নতুন পরিকল্পনা"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      decoration: BoxDecoration(
                        color: index <= _currentStep ? AppTheme.primaryBlue : AppTheme.primaryBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            Expanded(
              child: [
                _buildDurationStep(),
                _buildTriggerStep(),
                _buildTimelinePreview(),
              ][_currentStep],
            ),
            
            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _currentStep--);
                        },
                        child: const Text("পেছনে"),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(_currentStep < 2 ? "পরবর্তী" : "সংরক্ষণ করুন"),
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

  Widget _buildDurationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("পরিকল্পনার মেয়াদ", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Text("আপনি কত দিনের চ্যালেঞ্জ নিতে চান?", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
          const SizedBox(height: 32),
          Column(
            children: _durations.map((days) {
              final isSelected = _selectedDuration == days;
              return GestureDetector(
                onTap: () => setState(() => _selectedDuration = days),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.white.withOpacity(0.2) : AppTheme.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.flag, color: isSelected ? AppTheme.white : AppTheme.primaryBlue),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$days দিনের চ্যালেঞ্জ", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: isSelected ? AppTheme.white : AppTheme.textColor)),
                          Text("নিজেকে প্রস্তুত করুন", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isSelected ? AppTheme.white.withOpacity(0.8) : AppTheme.textLight)),
                        ],
                      ),
                      const Spacer(),
                      if (isSelected) const Icon(Icons.check_circle, color: AppTheme.white),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("আপনার ট্রিগার কি?", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Text("কোন সময়গুলোতে আপনার ধূমপান করতে ইচ্ছা হয়?", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _triggers.map((trigger) {
              final isSelected = _selectedTriggers.contains(trigger);
              return FilterChip(
                label: Text(trigger),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTriggers.add(trigger);
                    } else {
                      _selectedTriggers.remove(trigger);
                    }
                  });
                },
                selectedColor: AppTheme.accentOrange.withOpacity(0.2),
                checkmarkColor: AppTheme.accentOrange,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.accentOrange : AppTheme.textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppTheme.accentOrange : Colors.grey.withOpacity(0.2),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelinePreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("আপনার পরিকল্পনা", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Text("আজকের লক্ষ্য", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
          const SizedBox(height: 32),
          
          // Focus only on today's task
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.self_improvement, color: AppTheme.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  "মানসিক চাপ নিয়ন্ত্রণ",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "আজ আপনার মূল ফোকাস হবে স্ট্রেস বা মানসিক চাপ কমানো। যখনই ধূমপান করতে ইচ্ছা করবে, লম্বা শ্বাস নিন এবং অন্য কাজে মনোযোগ দিন।",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textColor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle),
                  label: const Text("আমি প্রস্তুত"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
