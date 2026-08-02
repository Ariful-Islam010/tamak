import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/groq_ai_service.dart';
import '../providers/quit_plan_provider.dart';
import '../models/user_model.dart';
import 'home_dashboard_screen.dart';

class ProfileAssessmentScreen extends StatefulWidget {
  const ProfileAssessmentScreen({super.key});

  @override
  State<ProfileAssessmentScreen> createState() => _ProfileAssessmentScreenState();
}

class _ProfileAssessmentScreenState extends State<ProfileAssessmentScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cigarettesPerDayController = TextEditingController();

  String? _selectedGender;
  int? _selectedDuration;
  DateTime? _selectedDate;

  final List<String> _genders = ["পুরুষ", "মহিলা", "অন্যান্য"];
  final List<int> _durations = [7, 14, 30];

  int _selectedGenderIndex = 0;
  int _selectedDurationIndex = 0;

  @override
  void initState() {
    super.initState();
    _nameController.text = ""; // Empty by default
    _ageController.text = ""; // Empty by default
    _cigarettesPerDayController.text = ""; // Empty by default
    _selectedGender = _genders[0]; // Default: পুরুষ
    _selectedDuration = _durations[0]; // Default: 7 days
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _classController.dispose();
    _ageController.dispose();
    _cigarettesPerDayController.dispose();
    super.dispose();
  }

  /// Validate current page before moving forward
  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: // Name - MUST be entered
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("অনুগ্রহ করে আপনার নাম প্রবেশ করান!"),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      case 1: // Educational info - MUST be entered
        if (_classController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("অনুগ্রহ করে আপনার শিক্ষাগত তথ্য/শ্রেণি প্রবেশ করান!"),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      case 2: // Age - MUST be entered
        final age = int.tryParse(_ageController.text.trim());
        if (age == null || age <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("অনুগ্রহ করে আপনার বয়স সঠিকভাবে টাইপ করুন!"),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      case 3: // Gender - always has a default
        return _selectedGender != null;
      case 4: // Cigarettes per day - MUST be entered
        final cigs = int.tryParse(_cigarettesPerDayController.text.trim());
        if (cigs == null || cigs < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("অনুগ্রহ করে দৈনিক ধূমপানের পরিমাণ সঠিকভাবে টাইপ করুন!"),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      case 5: // Plan duration - always has a default
        return _selectedDuration != null;
      case 6: // Quit date - MUST be selected
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

    if (_currentPage < 6) {
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

    final authService = context.read<AuthService>();
    final quitPlanProvider = context.read<QuitPlanProvider>();
    final currentUser = authService.currentUser;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    // Generate AI Plan
    final String? aiPlan = await GroqAiService.generateQuitPlan(
      durationInDays: _selectedDuration ?? 7,
      cigarettesPerDay: int.tryParse(_cigarettesPerDayController.text) ?? 5,
      age: _ageController.text,
      gender: _selectedGender ?? "পুরুষ",
    );

    if (aiPlan != null) {
      await quitPlanProvider.saveAiPlan(aiPlan);
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
      final dummyUser = UserModel(
        uid: 'dummy',
        displayName: enteredName.isNotEmpty ? enteredName : "ব্যবহারকারী",
        educationalInfo: _classController.text.isNotEmpty ? _classController.text : "শিক্ষাগত তথ্য নেই",
        planDuration: _selectedDuration ?? 7,
        quitDate: _selectedDate,
        age: int.tryParse(_ageController.text) ?? 19,
        gender: _selectedGender ?? "পুরুষ",
      );
      await authService.updateUserData(dummyUser);
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
                value: (_currentPage + 1) / 7,
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
                    _buildCigarettesStep(),
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
                    child: Text(_currentPage == 6 ? "সম্পন্ন করুন" : "পরবর্তী"),
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
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight),
          ),
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
        decoration: const InputDecoration(
          hintText: "যেমন: একাদশ শ্রেণি / অনার্স ২য় বর্ষ",
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

  Widget _buildCigarettesStep() {
    return _buildStepContainer(
      "ধূমপানের পরিমাণ",
      "আপনি দিনে গড়ে কয়টি সিগারেট পান করেন? (অবশ্যই পূরণ করতে হবে)",
      TextField(
        controller: _cigarettesPerDayController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: "যেমন: ৫",
        ),
      ),
    );
  }

  Widget _buildPlanStep() {
    return _buildStepContainer(
      "আপনার লক্ষ্য",
      "আপনি কতদিনের মধ্যে ধূমপান ছাড়ার পরিকল্পনা করছেন?",
      SizedBox(
        height: 250,
        child: ListWheelScrollView.useDelegate(
          itemExtent: 80,
          perspective: 0.005,
          diameterRatio: 1.5,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            setState(() {
              _selectedDurationIndex = index;
              _selectedDuration = _durations[index];
            });
          },
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              final days = _durations[index];
              final isSelected = index == _selectedDurationIndex;
              return Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isSelected ? 160 : 120,
                  height: isSelected ? 80 : 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "$days দিন",
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppTheme.textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            },
            childCount: _durations.length,
          ),
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
