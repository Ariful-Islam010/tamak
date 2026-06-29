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

  final TextEditingController _classController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cigarettesPerDayController = TextEditingController();

  String? _selectedGender;
  int? _selectedDuration;
  DateTime? _selectedDate;

  final List<String> _genders = ["পুরুষ", "মহিলা", "অন্যান্য"];
  final List<int> _durations = [7, 14, 30];

  int _selectedAge = 19;
  int _selectedGenderIndex = 0;
  int _selectedCigarettes = 5;
  int _selectedDurationIndex = 0;

  @override
  void initState() {
    super.initState();
    _ageController.text = "19";
    _cigarettesPerDayController.text = "5";
    _selectedGender = _genders[0];
    _selectedDuration = _durations[0];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _classController.dispose();
    _ageController.dispose();
    _cigarettesPerDayController.dispose();
    super.dispose();
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        return true;
      case 1:
        return _ageController.text.isNotEmpty;
      case 2:
        return _selectedGender != null;
      case 3:
        return _cigarettesPerDayController.text.isNotEmpty;
      case 4:
        return _selectedDuration != null;
      case 5:
        if (_selectedDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("অনুগ্রহ করে শুরুর তারিখ নির্বাচন করুন!"),
              backgroundColor: AppTheme.errorColor,
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
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator(color: AppTheme.accentPink));
      },
    );

    final String? aiPlan = await GroqAiService.generateQuitPlan(
      durationInDays: _selectedDuration ?? 7,
      cigarettesPerDay: int.tryParse(_cigarettesPerDayController.text) ?? 5,
      age: _ageController.text,
      gender: _selectedGender ?? "পুরুষ",
    );

    if (aiPlan != null) {
      await quitPlanProvider.saveAiPlan(aiPlan);
    }
    
    if (context.mounted) {
      Navigator.pop(context);
    }

    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(
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
        displayName: "ব্যবহারকারী",
        educationalInfo: _classController.text.isNotEmpty ? _classController.text : "শিক্ষাগত তথ্য নেই",
        planDuration: _selectedDuration ?? 7,
        quitDate: _selectedDate,
        age: int.tryParse(_ageController.text) ?? 19,
        gender: _selectedGender ?? "পুরুষ",
      );
      await authService.updateUserData(dummyUser);
    }
    
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text("প্রাথমিক তথ্য 📝", style: TextStyle(fontWeight: FontWeight.bold)),
          automaticallyImplyLeading: false,
          backgroundColor: AppTheme.demonDark,
          centerTitle: true,
          leading: _currentPage > 0 
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: AppTheme.accentPink.withValues(alpha: 0.05),
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
                  color: AppTheme.accentCyan.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / 6,
                    backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentPink),
                    minHeight: 6,
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
                    padding: const EdgeInsets.all(20.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPink,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: AppTheme.accentPink.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(
                          _currentPage == 5 ? "সম্পন্ন করুন 🚀" : "পরবর্তী ➡️",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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

  Widget _buildStepContainer(String title, String subtitle, Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textColor),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textLight, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildClassStep() {
    return _buildStepContainer(
      "শিক্ষাগত যোগ্যতা 🎓",
      "আপনি কোন ক্লাসে পড়েন বা আপনার শিক্ষাগত তথ্য দিন।",
      TextField(
        controller: _classController,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: "যেমন: একাদশ শ্রেণি / অনার্স ২য় বর্ষ",
          fillColor: AppTheme.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: AppTheme.primaryPurple.withValues(alpha: 0.2)),
          ),
        ),
      ),
    );
  }

  Widget _buildAgeStep() {
    return _buildStepContainer(
      "আপনার বয়স 🎂",
      "আপনার বর্তমান বয়স কত?",
      SizedBox(
        height: 250,
        child: ListWheelScrollView.useDelegate(
          itemExtent: 80,
          perspective: 0.005,
          diameterRatio: 1.5,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            setState(() {
              _selectedAge = 12 + index;
              _ageController.text = _selectedAge.toString();
            });
          },
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              final age = 12 + index;
              final isSelected = age == _selectedAge;
              return Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 130 : 90,
                  height: isSelected ? 80 : 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accentLime : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? Colors.white : AppTheme.primaryPurple.withValues(alpha: 0.1),
                      width: 3,
                    ),
                    boxShadow: isSelected ? AppTheme.glowShadow(AppTheme.accentLime) : null,
                  ),
                  child: Text(
                    age.toString(),
                    style: TextStyle(
                      fontSize: isSelected ? 32 : 22,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : AppTheme.textColor,
                    ),
                  ),
                ),
              );
            },
            childCount: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderStep() {
    return _buildStepContainer(
      "লিঙ্গ 👥",
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
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 170 : 130,
                  height: isSelected ? 80 : 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accentCyan : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? Colors.white : AppTheme.primaryPurple.withValues(alpha: 0.1),
                      width: 3,
                    ),
                    boxShadow: isSelected ? AppTheme.glowShadow(AppTheme.accentCyan) : null,
                  ),
                  child: Text(
                    gender,
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 18,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : AppTheme.textColor,
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
      "ধূমপানের পরিমাণ 🚬",
      "আপনি দিনে গড়ে কয়টি সিগারেট পান করেন?",
      SizedBox(
        height: 250,
        child: ListWheelScrollView.useDelegate(
          itemExtent: 80,
          perspective: 0.005,
          diameterRatio: 1.5,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            setState(() {
              _selectedCigarettes = index + 1;
              _cigarettesPerDayController.text = _selectedCigarettes.toString();
            });
          },
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              final count = index + 1;
              final isSelected = count == _selectedCigarettes;
              return Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 130 : 90,
                  height: isSelected ? 80 : 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.errorColor : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? Colors.white : AppTheme.primaryPurple.withValues(alpha: 0.1),
                      width: 3,
                    ),
                    boxShadow: isSelected ? AppTheme.glowShadow(AppTheme.errorColor) : null,
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: isSelected ? 32 : 22,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : AppTheme.textColor,
                    ),
                  ),
                ),
              );
            },
            childCount: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanStep() {
    return _buildStepContainer(
      "আপনার লক্ষ্য 🗓️",
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
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 170 : 130,
                  height: isSelected ? 80 : 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accentLime : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? Colors.white : AppTheme.primaryPurple.withValues(alpha: 0.1),
                      width: 3,
                    ),
                    boxShadow: isSelected ? AppTheme.glowShadow(AppTheme.accentLime) : null,
                  ),
                  child: Text(
                    "$days দিন",
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 18,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : AppTheme.textColor,
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
      "শুরুর তারিখ 📅",
      "আপনি কবে থেকে এই পরিকল্পনা শুরু করতে চান? (অবশ্যই নির্বাচন করুন)",
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppTheme.accentPink,
                    onPrimary: Colors.white,
                    surface: AppTheme.demonMid,
                    onSurface: Colors.white,
                  ),
                  dialogBackgroundColor: AppTheme.demonDark,
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() => _selectedDate = picked);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _selectedDate != null 
                  ? AppTheme.accentLime 
                  : AppTheme.primaryPurple.withValues(alpha: 0.2),
              width: 3,
            ),
            boxShadow: _selectedDate != null ? AppTheme.glowShadow(AppTheme.accentLime) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_rounded, 
                color: _selectedDate != null ? AppTheme.accentLime : AppTheme.accentPink,
                size: 28,
              ),
              const SizedBox(width: 16),
              Text(
                _selectedDate == null
                    ? "তারিখ নির্বাচন করুন"
                    : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _selectedDate != null ? AppTheme.accentLime : AppTheme.textColor,
                ),
              ),
              if (_selectedDate != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle_rounded, color: AppTheme.accentLime, size: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
