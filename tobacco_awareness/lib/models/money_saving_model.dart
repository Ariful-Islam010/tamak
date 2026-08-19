import 'package:flutter/material.dart';

class SavingsGoalModel {
  final String title;
  final int targetAmount;
  final int currentAmount;
  final bool isCompleted;
  final Color color;
  final IconData icon;

  SavingsGoalModel({
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.isCompleted = false,
    this.color = Colors.blue,
    this.icon = Icons.star,
  });

  /// Enforces maximum 10,000 TK constraint
  static const int maxGoalAmount = 10000;

  factory SavingsGoalModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return SavingsGoalModel(title: '', targetAmount: 0);
    }
    int target = (json['target'] ?? json['target_amount'] as num?)?.toInt() ?? 0;
    if (target > maxGoalAmount) target = maxGoalAmount;

    return SavingsGoalModel(
      title: json['title'] as String? ?? '',
      targetAmount: target,
      currentAmount: (json['current_amount'] as num?)?.toInt() ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      color: json['color'] != null ? Color(json['color'] as int) : Colors.blue,
      icon: Icons.star,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'target': targetAmount,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'is_completed': isCompleted,
      'color': color.toARGB32(),
    };
  }
}

class MoneySavingRecord {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;

  MoneySavingRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
  });

  factory MoneySavingRecord.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return MoneySavingRecord(
        id: '',
        userId: '',
        amount: 0.0,
        date: DateTime.now(),
      );
    }
    return MoneySavingRecord(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'created_at': date.toIso8601String(),
    };
  }
}
