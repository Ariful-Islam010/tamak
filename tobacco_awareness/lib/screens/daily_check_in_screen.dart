import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/check_in_provider.dart';

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  final TextEditingController _reflectionController = TextEditingController();

  final List<Map<String, String>> _moods = [
    {"emoji": "😁", "label": "অসাধারণ"},
    {"emoji": "🙂", "label": "ভালো"},
    {"emoji": "😐", "label": "মোটামুটি"},
    {"emoji": "😔", "label": "খারাপ"},
    {"emoji": "😠", "label": "রাগান্বিত"},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckInProvider>().reset();
    });
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkInProvider = context.watch<CheckInProvider>();

    if (checkInProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.demonDark,
        appBar: AppBar(
          title: const Text("দৈনিক চেক-ইন 📝"),
          backgroundColor: AppTheme.demonDark,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentPink),
        ),
      );
    }

    if (checkInProvider.hasCheckedInToday) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text("দৈনিক চেক-ইন 📝"),
          backgroundColor: AppTheme.demonDark,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.accentLime, width: 3),
                boxShadow: AppTheme.glowShadow(AppTheme.accentLime),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("🎉", style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  const Text(
                    "আজকের চেক-ইন সম্পন্ন হয়েছে!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "নিকোটিন ডেমনকে পরাস্ত করতে আগামীকাল আবার আসুন।",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentLime,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("ফিরে যান", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("দৈনিক চেক-ইন 📝", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.demonDark,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.15), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "আজ কি আপনি তামাক ব্যবহার করেছেন? 👾",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoiceButton(
                          "না 🛡️", 
                          Icons.thumb_up_rounded, 
                          AppTheme.accentLime, 
                          checkInProvider.usedTobacco == false, 
                          () {
                            checkInProvider.setUsedTobacco(false);
                          }
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildChoiceButton(
                          "হ্যাঁ 👿", 
                          Icons.thumb_down_rounded, 
                          AppTheme.errorColor, 
                          checkInProvider.usedTobacco == true, 
                          () {
                            checkInProvider.setUsedTobacco(true);
                          }
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Craving Scale
            const Text("ইচ্ছার তীব্রতা 🔥", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textColor)),
            const SizedBox(height: 4),
            const Text("১ = একদম নেই, ১০ = খুব বেশি তীব্রতা", style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.2), width: 2),
              ),
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.accentOrange,
                  inactiveTrackColor: AppTheme.accentOrange.withValues(alpha: 0.2),
                  thumbColor: AppTheme.accentOrange,
                  overlayColor: AppTheme.accentOrange.withValues(alpha: 0.2),
                  trackHeight: 8,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                ),
                child: Slider(
                  value: checkInProvider.cravingLevel,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: checkInProvider.cravingLevel.round().toString(),
                  onChanged: (value) {
                    checkInProvider.setCravingLevel(value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Mood Selector
            const Text("আজ আপনার কেমন লাগছে? 💭", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textColor)),
            const SizedBox(height: 16),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 16,
                children: _moods.map((mood) {
                  final isSelected = checkInProvider.selectedMood == mood["label"];
                  return GestureDetector(
                    onTap: () => checkInProvider.setSelectedMood(mood["label"]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accentPink.withValues(alpha: 0.15) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? AppTheme.accentPink : AppTheme.primaryPurple.withValues(alpha: 0.1),
                          width: 2.5,
                        ),
                        boxShadow: isSelected 
                            ? [
                                BoxShadow(
                                  color: AppTheme.accentPink.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(mood["emoji"]!, style: const TextStyle(fontSize: 36)),
                          const SizedBox(height: 8),
                          Text(
                            mood["label"]!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? AppTheme.accentPink : AppTheme.textColor,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),

            // Reflection Text Box
            const Text("আজকের ভাবনা 📝", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textColor)),
            const SizedBox(height: 12),
            TextField(
              controller: _reflectionController,
              maxLines: 3,
              style: const TextStyle(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: "আজকের দিনটি কেমন কাটল তা সংক্ষেপে লিখুন...",
                fillColor: AppTheme.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppTheme.primaryPurple.withValues(alpha: 0.2)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: checkInProvider.usedTobacco == null
                    ? null
                    : () async {
                        await checkInProvider.submitCheckIn();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("দৈনিক চেক-ইন সম্পন্ন হয়েছে! 🎉"),
                              backgroundColor: AppTheme.accentLime,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPink,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 6,
                  shadowColor: AppTheme.accentPink.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("জমা দিন 🚀", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton(String text, IconData icon, Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.white : color.withValues(alpha: 0.5), 
            width: 3.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.white : color, size: 36),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isSelected ? AppTheme.white : AppTheme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
