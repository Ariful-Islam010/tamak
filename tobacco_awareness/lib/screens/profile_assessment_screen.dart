import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/groq_ai_service.dart';
import '../providers/quit_plan_provider.dart';
import 'home_dashboard_screen.dart';


class ProfileAssessmentScreen extends ConsumerStatefulWidget {
  const ProfileAssessmentScreen({super.key});

  @override
  ConsumerState<ProfileAssessmentScreen> createState() => _ProfileAssessmentScreenState();
}

class _ProfileAssessmentScreenState extends ConsumerState<ProfileAssessmentScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _customDurationController = TextEditingController();

  String? _selectedGender;
  int? _selectedDuration;
  DateTime? _selectedDate;
  bool _isCustomDuration = false;

  final List<String> _genders = ["পুরুষ", "মহিলা", "অন্যান্য"];
  final List<int> _durations = [7, 14, 30, 60];

  int _selectedGenderIndex = 0;
  int _selectedDurationIndex = 0;

  @override
  void initState() {
    super.initState();
    _nameController.text = ""; // Empty by default
    _ageController.text = ""; // Empty by default
    _selectedGender = _genders[0]; // Default: পুরুষ
    _selectedDuration = _durations[0]; // Default: 7 days
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _classController.dispose();
    _ageController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  /// Validate current page before moving forward
  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: // Name - MUST be entered
        final nameVal = _nameController.text.trim();
        if (nameVal.length < 3 || nameVal.length > 20) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("আপনার নাম অন্তত ৩ থেকে সর্বোচ্চ ২০ অক্ষরের হতে হবে!"),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      case 1: // Educational info - MUST be entered
        final eduVal = _classController.text.trim();
        if (eduVal.isEmpty || eduVal.length > 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("শিক্ষাগত তথ্য আবশ্যক এবং সর্বোচ্চ ১০০ অক্ষরের হতে পারবে!"),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      case 2: // Age - MUST be entered
        final age = int.tryParse(_ageController.text.trim());
        if (age == null || age < 7 || age > 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("আপনার বয়স ৭ থেকে ১০০ বছরের মধ্যে হতে হবে!"),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      case 3: // Gender - always has a default
        return _selectedGender != null;
      case 4: // Plan duration
        if (_isCustomDuration) {
          final customVal = int.tryParse(_customDurationController.text.trim());
          if (customVal == null || customVal <= 0 || customVal > 365) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("অনুগ্রহ করে ১ থেকে ৩৬৫ দিনের মধ্যে দিন সংখ্যা প্রবেশ করান!"),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return false;
          }
          _selectedDuration = customVal;
          return true;
        }
        if (_selectedDuration == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("অনুগ্রহ করে তামাক ছাড়ার মেয়াদ নির্বাচন করুন!"),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      case 5: // Quit date - MUST be selected
        if (_selectedDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("অনুগ্রহ করে শুরুর তারিখ নির্বাচন করুন!"),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _nextPage() {
    if (!_validateCurrentPage()) return;

    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _finishAssessment();
    }
  }

  void _finishAssessment() async {
    // Final validation
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("অনুগ্রহ করে শুরুর তারিখ নির্বাচন করুন!"),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final authService = ref.read(authServiceProvider);
    final quitPlan = ref.read(quitPlanProvider);
    final currentUser = authService.currentUser;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
                  SizedBox(height: 20),
                  Text(
                    "AI আপনার জন্য বিশেষ পরিকল্পনা তৈরি করছে...",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "সবগুলো দিনের গাইড ধাপে ধাপে সঠিকভাবে প্রস্তুত হচ্ছে, অনুগ্রহ করে কিছুক্ষণ অপেক্ষা করুন।",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Generate AI Plan
    final String? aiPlan = await GroqAiService.generateQuitPlan(
      durationInDays: _selectedDuration ?? 7,
      age: _ageController.text,
      gender: _selectedGender ?? "পুরুষ",
    );

    if (aiPlan != null) {
      await quitPlan.saveAiPlan(aiPlan);
    }
    
    if (mounted) {
      Navigator.pop(context); // Dismiss loading dialog
    }

    final enteredName = _nameController.text.trim();

    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(
        displayName: enteredName.isNotEmpty ? enteredName : null,
        educationalInfo: _classController.text.isNotEmpty ? _classController.text : null,
        planDuration: _selectedDuration ?? 7,
        quitDate: _selectedDate,
        age: int.tryParse(_ageController.text) ?? 19,
        gender: _selectedGender ?? "পুরুষ",
      );
      await authService.updateUserData(updatedUser);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('অনুগ্রহ করে আগে লগইন করুন')),
        );
      }
      return;
    }
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent user from going back without completing onboarding
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.loginBackgroundColor,
        appBar: AppBar(
          title: const Text("প্রাথমিক তথ্য"),
          automaticallyImplyLeading: false, // No back button for onboarding
          leading: _currentPage > 0 
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300), 
                      curve: Curves.easeIn,
                    );
                  },
                ) 
              : null,
        ),
        body: Stack(
          children: [
            // Decorative background elements
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -100,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: Column(
            children: [
              // Progress Indicator
              LinearProgressIndicator(
                value: (_currentPage + 1) / 6,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildNameStep(),
                    _buildClassStep(),
                    _buildAgeStep(),
                    _buildGenderStep(),
                    _buildPlanStep(),
                    _buildDateStep(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(_currentPage == 5 ? "সম্পন্ন করুন" : "পরবর্তী"),
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

  Widget _buildStepContainer(String title, String subtitle, Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight),
            ),
          ],
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return _buildStepContainer(
      "আপনার নাম",
      "আপনার পরিচয়ের জন্য একটি নাম দিন। (অবশ্যই পূরণ করতে হবে)",
      TextField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: "যেমন: রাহুল ইসলাম",
          prefixIcon: Icon(Icons.person_outline),
        ),
      ),
    );
  }

  Widget _buildClassStep() {
    return _buildStepContainer(
      "শিক্ষাগত যোগ্যতা",
      "আপনি কোন ক্লাসে পড়েন বা আপনার শিক্ষাগত তথ্য দিন।",
      TextField(
        controller: _classController,
        maxLength: 100,
        decoration: const InputDecoration(
          hintText: "যেমন: একাদশ শ্রেণি / অনার্স ২য় বর্ষ (সর্বোচ্চ ১০০ অক্ষর)",
        ),
      ),
    );
  }

  Widget _buildAgeStep() {
    return _buildStepContainer(
      "আপনার বয়স",
      "আপনার বর্তমান বয়স কত? (অবশ্যই পূরণ করতে হবে)",
      TextField(
        controller: _ageController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: "যেমন: ১৯",
        ),
      ),
    );
  }

  Widget _buildGenderStep() {
    return _buildStepContainer(
      "লিঙ্গ",
      "আপনার লিঙ্গ নির্বাচন করুন।",
      SizedBox(
        height: 250,
        child: ListWheelScrollView.useDelegate(
          itemExtent: 80,
          perspective: 0.005,
          diameterRatio: 1.5,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            setState(() {
              _selectedGenderIndex = index;
              _selectedGender = _genders[index];
            });
          },
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              final gender = _genders[index];
              final isSelected = index == _selectedGenderIndex;
              return Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isSelected ? 160 : 120,
                  height: isSelected ? 80 : 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    gender,
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppTheme.textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            },
            childCount: _genders.length,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanStep() {
    return _buildStepContainer(
      "তামাক ছাড়ার পরিকল্পনা",
      "",
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "অপশন ১: মেয়াদী প্যাকেজ নির্বাচন করুন",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _durations.length,
              itemBuilder: (context, index) {
                final days = _durations[index];
                final isSelected = !_isCustomDuration && _selectedDuration == days;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _isCustomDuration = false;
                      _selectedDurationIndex = index;
                      _selectedDuration = days;
                      _customDurationController.clear();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : AppTheme.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$days দিন",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.textColor,
                          ),
                        ),
                        Text(
                          index == 0
                              ? "১ সপ্তাহ"
                              : index == 1
                                  ? "২ সপ্তাহ"
                                  : index == 2
                                      ? "১ মাস"
                                      : "২ মাস",
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.9)
                                : AppTheme.textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  "অপশন ২: নিজের ইচ্ছেমতো দিন টাইপ করুন",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _isCustomDuration,
                  activeThumbColor: AppTheme.primaryGreen,
                  onChanged: (val) {
                    setState(() {
                      _isCustomDuration = val;
                      if (!val) {
                        _selectedDuration = _durations[_selectedDurationIndex];
                      }
                    });
                  },
                ),
              ],
            ),
            if (_isCustomDuration) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customDurationController,
                keyboardType: TextInputType.number,
                autofocus: true,
                onChanged: (val) {
                  final d = int.tryParse(val.trim());
                  if (d != null && d > 0 && d <= 365) {
                    setState(() {
                      _selectedDuration = d;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: "দিন সংখ্যা টাইপ করুন",
                  hintText: "যেমন: ২১, ৪৫, ৯০ দিন",
                  suffixText: "দিন",
                  prefixIcon: const Icon(Icons.edit_calendar, color: AppTheme.primaryGreen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "সর্বনিম্ন ১ দিন থেকে সর্বোচ্চ ৩৬৫ দিন পর্যন্ত যেকোনো সংখ্যা টাইপ করতে পারবেন।",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateStep() {
    return _buildStepContainer(
      "শুরুর তারিখ",
      "আপনি কবে থেকে এই পরিকল্পনা শুরু করতে চান? (অবশ্যই নির্বাচন করুন)",
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) {
            setState(() => _selectedDate = picked);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectedDate != null 
                  ? AppTheme.primaryGreen 
                  : Colors.grey.withValues(alpha: 0.2),
              width: _selectedDate != null ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today, 
                color: _selectedDate != null ? AppTheme.primaryGreen : AppTheme.primaryBlue,
              ),
              const SizedBox(width: 16),
              Text(
                _selectedDate == null
                    ? "তারিখ নির্বাচন করুন"
                    : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _selectedDate != null ? AppTheme.primaryGreen : null,
                ),
              ),
              if (_selectedDate != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
