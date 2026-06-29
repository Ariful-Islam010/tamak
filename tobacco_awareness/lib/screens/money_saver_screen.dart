import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/money_saver_provider.dart';

class MoneySaverScreen extends StatefulWidget {
  const MoneySaverScreen({super.key});

  @override
  State<MoneySaverScreen> createState() => _MoneySaverScreenState();
}

class _MoneySaverScreenState extends State<MoneySaverScreen> {

  void _showAddDreamDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.demonMid,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppTheme.accentPink, width: 3),
          ),
          title: const Text(
            "নতুন স্বপ্ন যোগ করুন 💭",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "স্বপ্নের নাম (যেমন: সাইকেল 🚲)",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "লক্ষ্য পরিমাণ (৳)",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("বাতিল", style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                final int? amount = int.tryParse(amountController.text);
                if (titleController.text.isNotEmpty && amount != null && amount > 0) {
                  context.read<MoneySaverProvider>().addDream(titleController.text, amount, AppTheme.accentPink);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPink,
                foregroundColor: Colors.white,
              ),
              child: const Text("যোগ করুন"),
            ),
          ],
        );
      },
    );
  }

  void _showAddMoneyDialog() {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.demonMid,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppTheme.accentLime, width: 3),
          ),
          title: const Text(
            "টাকা যোগ করুন 💰",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "যেমন: ৫০",
              hintStyle: const TextStyle(color: Colors.white38),
              prefixText: "৳ ",
              prefixStyle: const TextStyle(color: AppTheme.accentLime, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("বাতিল", style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                final int? amount = int.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  context.read<MoneySaverProvider>().addMoney(amount);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentLime,
                foregroundColor: Colors.white,
              ),
              child: const Text("যোগ করুন"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final moneyProvider = context.watch<MoneySaverProvider>();
    final String savingsStr = moneyProvider.totalSavings.toString()
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("টাকা সেভার 💰✨", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppTheme.demonDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Savings Dashboard
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: AppTheme.glowShadow(AppTheme.accentPink),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.savings_rounded, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "মোট জমানো অর্থ",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "৳$savingsStr",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: moneyProvider.hasAddedMoneyToday
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("আজকের জন্য টাকা যোগ করা হয়ে গেছে! আগামীকাল আবার যোগ করতে পারবেন। 🔒"),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        : _showAddMoneyDialog,
                    icon: Icon(
                      Icons.add_circle_rounded, 
                      color: moneyProvider.hasAddedMoneyToday ? Colors.grey : AppTheme.primaryPurple,
                      size: 24,
                    ),
                    label: Text(
                      "টাকা যোগ করুন",
                      style: TextStyle(
                        color: moneyProvider.hasAddedMoneyToday ? Colors.grey : AppTheme.primaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Wishlist Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "আমার স্বপ্নসমূহ 💭🌟", 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textColor),
                ),
                TextButton.icon(
                  onPressed: () {
                    if (moneyProvider.hasUnachievedDream) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("অনুগ্রহ করে আগের স্বপ্নটি পূরণ করুন! এরপর নতুন স্বপ্ন যোগ করতে পারবেন। 🔒"),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    } else {
                      _showAddDreamDialog();
                    }
                  },
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: moneyProvider.hasUnachievedDream ? Colors.grey : AppTheme.accentPink,
                  ),
                  label: Text(
                    "নতুন স্বপ্ন",
                    style: TextStyle(
                      color: moneyProvider.hasUnachievedDream ? Colors.grey : AppTheme.accentPink,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (moneyProvider.dreams.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Text("😢", style: TextStyle(fontSize: 50)),
                      const SizedBox(height: 12),
                      Text(
                        "এখনো কোনো স্বপ্ন যোগ করা হয়নি! ধূমপানমুক্ত জীবনে বেঁচে যাওয়া টাকা দিয়ে পূরণ করুন নতুন স্বপ্ন!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...moneyProvider.dreams.map((dream) => _buildWishlistCard(
                    context,
                    dream["title"],
                    dream["icon"],
                    dream["target"],
                    dream["color"] ?? AppTheme.accentPink,
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistCard(BuildContext context, String title, IconData icon, int targetAmount, Color color) {
    final totalSavings = context.read<MoneySaverProvider>().totalSavings;
    double progress = totalSavings / targetAmount;
    if (progress > 1.0) progress = 1.0;
    bool isCompleted = progress >= 1.0;

    final String targetStr = targetAmount.toString()
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');
    final String currentStr = totalSavings.toString()
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCompleted ? AppTheme.accentLime : AppTheme.primaryPurple.withValues(alpha: 0.1), 
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
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
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.w900, 
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted ? "অভিনন্দন! লক্ষ্য অর্জিত! 🎉" : "৳$currentStr / ৳$targetStr",
                      style: TextStyle(
                        color: isCompleted ? AppTheme.accentLime : AppTheme.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle_rounded, color: AppTheme.accentLime, size: 32),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
