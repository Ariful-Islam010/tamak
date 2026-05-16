import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'home_dashboard_screen.dart';

class ProfileAssessmentScreen extends StatefulWidget {
  const ProfileAssessmentScreen({super.key});

  @override
  State<ProfileAssessmentScreen> createState() => _ProfileAssessmentScreenState();
}

class _ProfileAssessmentScreenState extends State<ProfileAssessmentScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();

  String? _selectedTobaccoType;
  int? _selectedDuration;
  DateTime? _selectedDate;

  final List<String> _tobaccoTypes = ["সিগারেট", "জর্দা/গুল", "বিড়ি", "অন্যান্য"];
  final List<int> _durations = [7, 14, 30];

  @override
  void initState() {
    super.initState();
    // Auto-fill name from AuthService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthService>().currentUser;
      if (user?.displayName != null) {
        _nameController.text = user!.displayName!;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("প্রোফাইল সেটআপ"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "আপনার সম্পর্কে কিছু তথ্য দিন",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              "এই তথ্যগুলো আমাদের আপনাকে আরও ভালোভাবে সাহায্য করতে সাহায্য করবে।",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight),
            ),
            const SizedBox(height: 32),

            // Name
            _buildInputField("আপনার নাম", "আপনার পূর্ণ নাম লিখুন", _nameController),
            const SizedBox(height: 24),

            // Education Info
            _buildInputField("শিক্ষাগত তথ্য", "যেমন: ঢাকা বিশ্ববিদ্যালয় / বিএসসি", _educationController),
            const SizedBox(height: 24),

            // Age & Gender (Simplified for mockup)
            Row(
              children: [
                Expanded(
                  child: _buildInputField("বয়স", "যেমন: ২৫"),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField("লিঙ্গ", "নির্বাচন করুন"),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tobacco Type
            Text("তামাকের ধরণ", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _tobaccoTypes.map((type) {
                final isSelected = _selectedTobaccoType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedTobaccoType = type);
                  },
                  selectedColor: AppTheme.primaryBlue.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryBlue : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Plan Duration
            Text("পরিকল্পনার মেয়াদ", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: _durations.map((days) {
                final isSelected = _selectedDuration == days;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDuration = days),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryBlue : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "$days",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppTheme.white : AppTheme.textColor,
                            ),
                          ),
                          Text(
                            "দিন",
                            style: TextStyle(
                              color: isSelected ? AppTheme.white.withOpacity(0.8) : AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Start Date Picker
            Text("শুরুর তারিখ", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                    const SizedBox(width: 16),
                    Text(
                      _selectedDate == null
                          ? "তারিখ নির্বাচন করুন"
                          : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Complete Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final authService = context.read<AuthService>();
                  final currentUser = authService.currentUser;
                  
                  if (currentUser != null) {
                    final updatedUser = currentUser.copyWith(
                      displayName: _nameController.text.isNotEmpty ? _nameController.text : null,
                      educationalInfo: _educationController.text.isNotEmpty ? _educationController.text : null,
                      tobaccoType: _selectedTobaccoType,
                      planDuration: _selectedDuration,
                      quitDate: _selectedDate,
                    );
                    authService.updateUserData(updatedUser);
                  } else {
                    // For mockup without actual auth
                    final dummyUser = UserModel(
                      uid: 'dummy',
                      displayName: _nameController.text.isNotEmpty ? _nameController.text : "ব্যবহারকারী",
                      educationalInfo: _educationController.text.isNotEmpty ? _educationController.text : "শিক্ষাগত তথ্য নেই",
                    );
                    authService.updateUserData(dummyUser);
                  }

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeDashboardScreen()),
                  );
                },
                child: const Text("সম্পন্ন করুন"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String hint, [TextEditingController? controller]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }
}
