import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("আমার প্রোফাইল"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              color: AppTheme.white,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                        child: const Icon(Icons.person, size: 60, color: AppTheme.primaryBlue),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.accentYellow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, size: 16, color: AppTheme.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("রাকিব হোসেন", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24)),
                  Text("rakib@example.com", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "তামাকমুক্ত শুরু: ১ মে, ২০২৬",
                      style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats Quick View
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(child: _buildStatItem(context, "দিন", "১৫")),
                  Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
                  Expanded(child: _buildStatItem(context, "লেভেল", "Warrior")),
                  Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
                  Expanded(child: _buildStatItem(context, "টাকা সেভ", "৳১৫০০")),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings List
            _buildListTile(context, "প্রোফাইল সম্পাদনা", Icons.person_outline),
            _buildListTile(context, "ভাষা (Language)", Icons.language, trailing: "বাংলা"),
            _buildListTile(context, "নোটিফিকেশন", Icons.notifications_none),
            _buildListTile(context, "প্রাইভেসি ও সিকিউরিটি", Icons.lock_outline),
            _buildListTile(context, "সাহায্য ও সাপোর্ট", Icons.help_outline),
            
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Logout and go to AuthScreen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: AppTheme.errorColor),
                  label: const Text("লগআউট", style: TextStyle(color: AppTheme.errorColor)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.errorColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textLight)),
      ],
    );
  }

  Widget _buildListTile(BuildContext context, String title, IconData icon, {String? trailing}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        trailing: trailing != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(trailing, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              )
            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
