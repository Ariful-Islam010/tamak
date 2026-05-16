import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  bool? _usedTobacco;
  double _cravingLevel = 5;
  String? _selectedMood;
  
  final List<Map<String, String>> _moods = [
    {"emoji": "😁", "label": "অসাধারণ"},
    {"emoji": "🙂", "label": "ভালো"},
    {"emoji": "😐", "label": "মোটামুটি"},
    {"emoji": "😔", "label": "খারাপ"},
    {"emoji": "😠", "label": "রাগান্বিত"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("দৈনিক চেক-ইন"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "আজ কি আপনি তামাক ব্যবহার করেছেন?",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoiceButton("না", Icons.thumb_up, AppTheme.primaryGreen, _usedTobacco == false, () {
                          setState(() => _usedTobacco = false);
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildChoiceButton("হ্যাঁ", Icons.thumb_down, AppTheme.errorColor, _usedTobacco == true, () {
                          setState(() => _usedTobacco = true);
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Craving Scale
            Text("ইচ্ছার তীব্রতা", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text("১ = একদম নেই, ১০ = খুব বেশি", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.accentOrange,
                inactiveTrackColor: AppTheme.accentOrange.withOpacity(0.2),
                thumbColor: AppTheme.accentOrange,
                overlayColor: AppTheme.accentOrange.withOpacity(0.2),
                trackHeight: 8,
              ),
              child: Slider(
                value: _cravingLevel,
                min: 1,
                max: 10,
                divisions: 9,
                label: _cravingLevel.round().toString(),
                onChanged: (value) {
                  setState(() => _cravingLevel = value);
                },
              ),
            ),
            const SizedBox(height: 32),

            // Mood Selector
            Text("আজ আপনার কেমন লাগছে?", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood["label"];
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood["label"]),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(mood["emoji"]!, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          mood["label"]!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? AppTheme.primaryBlue : AppTheme.textLight,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Reflection Text Box
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "আজকের দিনটি সম্পর্কে কিছু লিখুন (ঐচ্ছিক)",
                fillColor: AppTheme.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Show success animation logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("চেক-ইন সম্পন্ন হয়েছে! +10 XP")),
                  );
                  Navigator.pop(context);
                },
                child: const Text("জমা দিন"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton(String text, IconData icon, Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.white : color, size: 32),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.white : AppTheme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
