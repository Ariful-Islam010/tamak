import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class EducationInfoScreen extends StatefulWidget {
  const EducationInfoScreen({super.key});

  @override
  State<EducationInfoScreen> createState() => _EducationInfoScreenState();
}

class _EducationInfoScreenState extends State<EducationInfoScreen> {
  late TextEditingController _educationController;

  @override
  void initState() {
    super.initState();
    _educationController = TextEditingController();
    
    // Auto-fill from AuthService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthService>().currentUser;
      if (user?.educationalInfo != null) {
        _educationController.text = user!.educationalInfo!;
      }
    });
  }

  @override
  void dispose() {
    _educationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("শিক্ষাগত তথ্য"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school, color: AppTheme.primaryBlue, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "আপনার শিক্ষাগত যোগ্যতা বা প্রতিষ্ঠানের নাম আপডেট করুন",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  Text("প্রতিষ্ঠান / ডিগ্রির নাম", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _educationController,
                    decoration: InputDecoration(
                      hintText: "যেমন: ঢাকা বিশ্ববিদ্যালয় / বিএসসি",
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final authService = context.read<AuthService>();
                        final currentUser = authService.currentUser;
                        
                        if (currentUser != null) {
                          final updatedUser = currentUser.copyWith(
                            educationalInfo: _educationController.text,
                          );
                          authService.updateUserData(updatedUser);
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("শিক্ষাগত তথ্য আপডেট হয়েছে!")),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text("সংরক্ষণ করুন"),
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
}
