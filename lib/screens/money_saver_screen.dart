import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MoneySaverScreen extends StatefulWidget {
  const MoneySaverScreen({super.key});

  @override
  State<MoneySaverScreen> createState() => _MoneySaverScreenState();
}

class _MoneySaverScreenState extends State<MoneySaverScreen> {
  int _totalSavings = 0;

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
                final int? amount = int.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  setState(() {
                    _totalSavings += amount;
                  });
                }
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
    // English numerals to Bengali
    final String savingsStr = _totalSavings.toString()
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("টাকা সেভার"),
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
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, Color(0xFF34D399)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.savings, color: AppTheme.white, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "মোট সঞ্চয়",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.white.withOpacity(0.8),
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
                    onPressed: _showAddMoneyDialog,
                    icon: const Icon(Icons.add, color: AppTheme.primaryGreen),
                    label: const Text("যোগ করুন", style: TextStyle(color: AppTheme.primaryGreen)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.white,
                      foregroundColor: AppTheme.primaryGreen,
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
                Text("আমার স্বপ্ন", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22)),
                TextButton(
                  onPressed: () {},
                  child: const Text("নতুন স্বপ্ন"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildWishlistCard(context, "নতুন জুতো", Icons.directions_walk, 3500, AppTheme.primaryBlue),
            _buildWishlistCard(context, "হেডফোন", Icons.headphones, 1200, AppTheme.primaryGreen),
            _buildWishlistCard(context, "স্মার্টফোন", Icons.smartphone, 15000, AppTheme.accentOrange),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistCard(BuildContext context, String title, IconData icon, int targetAmount, Color color) {
    double progress = _totalSavings / targetAmount;
    if (progress > 1.0) progress = 1.0;
    bool isCompleted = progress >= 1.0;

    final String targetStr = targetAmount.toString()
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');
    final String currentStr = _totalSavings.toString()
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCompleted ? AppTheme.primaryGreen : Colors.transparent, width: 2),
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
                  color: color.withOpacity(0.1),
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
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
