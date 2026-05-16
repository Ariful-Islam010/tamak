import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MoneySaverScreen extends StatelessWidget {
  const MoneySaverScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    "৳২,৫০০",
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Time based savings
            Row(
              children: [
                Expanded(child: _buildTimeCard(context, "দৈনিক", "৳৫০")),
                const SizedBox(width: 16),
                Expanded(child: _buildTimeCard(context, "সাপ্তাহিক", "৳৩৫০")),
                const SizedBox(width: 16),
                Expanded(child: _buildTimeCard(context, "মাসিক", "৳১,৫০০")),
              ],
            ),
            const SizedBox(height: 40),

            // Wishlist Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("আমার স্বপ্ন", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22)),
                TextButton(
                  onPressed: () {},
                  child: const Text("যোগ করুন"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildWishlistCard(context, "নতুন জুতো", Icons.directions_walk, 3500, 2500, AppTheme.primaryBlue),
            _buildWishlistCard(context, "হেডফোন", Icons.headphones, 1200, 1200, AppTheme.primaryGreen, isCompleted: true),
            _buildWishlistCard(context, "স্মার্টফোন", Icons.smartphone, 15000, 2500, AppTheme.accentOrange),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(BuildContext context, String title, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
          const SizedBox(height: 8),
          Text(amount, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textColor)),
        ],
      ),
    );
  }

  Widget _buildWishlistCard(BuildContext context, String title, IconData icon, int targetAmount, int currentAmount, Color color, {bool isCompleted = false}) {
    double progress = currentAmount / targetAmount;
    if (progress > 1.0) progress = 1.0;

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
                      isCompleted ? "লক্ষ্য অর্জিত!" : "৳$currentAmount / ৳$targetAmount",
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
