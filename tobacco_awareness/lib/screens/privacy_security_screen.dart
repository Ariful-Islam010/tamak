import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

class PrivacySecurityScreen extends ConsumerStatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  ConsumerState<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends ConsumerState<PrivacySecurityScreen> {
  bool _isDeleting = false;

  void _showDeleteAccountDialog() {
    final randomCode = "DELETE-${Random().nextInt(9000) + 1000}";
    final textController = TextEditingController();
    bool isMatch = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "অ্যাকাউন্ট ডিলিট নিশ্চিতকরণ",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "সতর্কতা: অ্যাকাউন্ট ডিলিট করলে আপনার সমস্ত অগ্রগতি, স্ট্রাইক, ব্যাজ ও হিস্ট্রি স্থায়ীভাবে মুছে যাবে। এটি আর পুনরুদ্ধার করা সম্ভব হবে না।",
                    style: TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "নিচে প্রদর্শিত সিকিউরিটি কোডটি হুবহু টাইপ করুন:",
                          style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          randomCode,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    onChanged: (val) {
                      setDialogState(() {
                        isMatch = val.trim() == randomCode;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "যেমন: $randomCode",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("বাতিল", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: isMatch
                    ? () async {
                        Navigator.pop(ctx);
                        _executeAccountDeletion();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.red.shade200,
                ),
                child: const Text("স্থায়ীভাবে ডিলিট করুন", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _executeAccountDeletion() async {
    setState(() => _isDeleting = true);
    try {
      await ref.read(authServiceProvider).deleteAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("আপনার অ্যাকাউন্ট ও تمام ডেটা স্থায়ীভাবে মুছে ফেলা হয়েছে।"),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("অ্যাকাউন্ট ডিলিট করতে সমস্যা হয়েছে: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text("প্রাইভেসি ও সিকিউরিটি"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppTheme.primaryPurple,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              "তথ্য নিরাপত্তা",
              "আপনার সমস্ত ব্যক্তিগত তথ্য এবং তামাক বর্জনের ইতিহাস আমাদের সুরক্ষিত সার্ভারে (Secure Server) সম্পূর্ণ এনক্রিপ্ট অবস্থায় সুরক্ষিত থাকে। আপনার অনুমতি ছাড়া এই ডেটা তৃতীয় কোনো পক্ষের সাথে শেয়ার করা হয় না।",
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              "লোকাল স্টোরেজ পলিসি",
              "অ্যাপটির গতি বাড়ানোর জন্য কিছু সাধারণ প্রোগ্রেস ডেটা আপনার ডিভাইসের লোকাল স্টোরেজে (Hive) ক্যাশ হিসেবে রাখা হয়। লগআউট করার সাথে সাথে এই লোকাল ক্যাশ ডেটা মুছে ফেলা হয়।",
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              "গুগল সাইন-ইন",
              "গুগল সাইন-ইন এর ক্ষেত্রে আমরা শুধুমাত্র আপনার ডিসপ্লে নাম, ইমেইল এবং প্রোফাইল ফটোর লিংক ব্যবহার করি যা অ্যাকাউন্ট ভেরিফিকেশনের জন্য প্রয়োজন।",
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              "অ্যাকাউন্ট ও ডেটা মোছার নিয়ম (Data Deletion)",
              "গুগল প্লে স্টোরের পলিসি অনুযায়ী আপনি যেকোনো সময় অ্যাপ ও ব্যাকএন্ড সার্ভার থেকে আপনার সমস্ত ডেটা স্থায়ীভাবে ডিলিট করতে পারেন। নিচে 'অ্যাকাউন্ট ও সমস্ত ডাটা ডিলিট করুন' বাটনে ক্লিক করে সরাসরি ১-ক্লিকে স্থায়ীভাবে আপনার সমস্ত ডাটা মুছে ফেলুন।",
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isDeleting ? null : _showDeleteAccountDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_forever_rounded),
                label: Text(
                  _isDeleting ? "মুছে ফেলা হচ্ছে..." : "অ্যাকাউন্ট ও সমস্ত ডাটা ডিলিট করুন",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textLight,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
