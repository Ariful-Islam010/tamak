import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/money_saver_provider.dart';

class MoneySaverScreen extends ConsumerStatefulWidget {
  const MoneySaverScreen({super.key});

  @override
  ConsumerState<MoneySaverScreen> createState() => _MoneySaverScreenState();
}

class _MoneySaverScreenState extends ConsumerState<MoneySaverScreen> {

  void _showAddDreamDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("নতুন স্বপ্ন যোগ করুন"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: "স্বপ্নের নাম (যেমন: সাইকেল)"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "লক্ষ্য পরিমাণ (৳)"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("বাতিল"),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final int? amount = int.tryParse(amountController.text.trim());
                
                if (title.length < 3 || title.length > 20) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("স্বপ্নের নাম ৩ থেকে ২০ অক্ষরের মধ্যে হতে হবে!"),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("সঠিক টাকার পরিমাণ টাইপ করুন (০ এর বেশি)!"),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                ref.read(moneySaverProvider).addDream(title, amount, AppTheme.primaryBlue);
                Navigator.pop(context);
              },
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
          title: const Text("টাকা যোগ করুন"),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "যেমন: ৫০",
              prefixText: "৳ ",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("বাতিল"),
            ),
            ElevatedButton(
              onPressed: () {
                final int? amount = int.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("সঠিক টাকার পরিমাণ টাইপ করুন (০ এর বেশি)!"),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }
                ref.read(moneySaverProvider).addMoney(amount);
                Navigator.pop(context);
              },
              child: const Text("যোগ করুন"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final moneyProvider = ref.watch(moneySaverProvider);
    // English numerals to Bengali
    final String savingsStr = moneyProvider.totalSavings.toString()
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');

    return Scaffold(
      backgroundColor: const Color(0xFF3EA74D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3EA74D),
        foregroundColor: Colors.white,
        title: const Text("টাকা সেভার", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Savings Dashboard
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(Icons.savings, color: AppTheme.white, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "মোট সঞ্চয়",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.white.withValues(alpha: 0.8),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "৳$savingsStr",
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: moneyProvider.hasAddedMoneyToday
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("আজকের জন্য টাকা যোগ করা হয়ে গেছে! আগামীকাল আবার যোগ করতে পারবেন।"),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        : _showAddMoneyDialog,
                    icon: Icon(Icons.add, color: moneyProvider.hasAddedMoneyToday ? Colors.grey : AppTheme.primaryGreen),
                    label: Text(
                      "যোগ করুন",
                      style: TextStyle(color: moneyProvider.hasAddedMoneyToday ? Colors.grey : AppTheme.primaryGreen),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.white,
                      foregroundColor: moneyProvider.hasAddedMoneyToday ? Colors.grey : AppTheme.primaryGreen,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Wishlist Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "আমার স্বপ্ন",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: Colors.white),
                ),
                TextButton.icon(
                  onPressed: () {
                    if (moneyProvider.hasUnachievedDream) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("অনুগ্রহ করে আগের স্বপ্নটি পূরণ করুন! এরপর নতুন স্বপ্ন যোগ করতে পারবেন।"),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    } else {
                      _showAddDreamDialog();
                    }
                  },
                  icon: Icon(
                    Icons.add,
                    color: moneyProvider.hasUnachievedDream ? Colors.white54 : Colors.white,
                  ),
                  label: Text(
                    "নতুন স্বপ্ন",
                    style: TextStyle(
                      color: moneyProvider.hasUnachievedDream ? Colors.white54 : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...List.generate(moneyProvider.dreams.length, (index) {
              final dream = moneyProvider.dreams[index];
              final allocatedSavings = moneyProvider.getAllocatedSavings()[index];
              return _buildWishlistCard(
                context,
                dream["title"],
                dream["icon"],
                dream["target"],
                dream["color"],
                allocatedSavings,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistCard(BuildContext context, String title, IconData icon, int targetAmount, Color color, int allocatedSavings) {
    double progress = allocatedSavings / targetAmount;
    if (progress > 1.0) progress = 1.0;
    bool isCompleted = progress >= 1.0;

    final String targetStr = targetAmount.toString()
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');
    final String currentStr = allocatedSavings.toString()
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? AppTheme.primaryGreen : Colors.grey.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      isCompleted ? "লক্ষ্য অর্জিত!" : "৳$currentStr / ৳$targetStr",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isCompleted ? AppTheme.primaryGreen : AppTheme.textLight,
                            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                          ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 28),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
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
