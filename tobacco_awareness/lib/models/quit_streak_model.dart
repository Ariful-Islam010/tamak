class QuitStreakModel {
  final int currentStreak;
  final int maxStreak;
  final String? lastCheckInDate;
  final int totalCigarettesAvoided;
  final double moneySaved;

  QuitStreakModel({
    required this.currentStreak,
    required this.maxStreak,
    this.lastCheckInDate,
    required this.totalCigarettesAvoided,
    required this.moneySaved,
  });

  factory QuitStreakModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return QuitStreakModel.empty();
    return QuitStreakModel(
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      maxStreak: (json['max_streak'] as num?)?.toInt() ?? 0,
      lastCheckInDate: json['last_check_in_date'] as String?,
      totalCigarettesAvoided: (json['total_cigarettes_avoided'] as num?)?.toInt() ?? 0,
      moneySaved: (json['money_saved'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory QuitStreakModel.empty() {
    return QuitStreakModel(
      currentStreak: 0,
      maxStreak: 0,
      lastCheckInDate: null,
      totalCigarettesAvoided: 0,
      moneySaved: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_streak': currentStreak,
      'max_streak': maxStreak,
      'last_check_in_date': lastCheckInDate,
      'total_cigarettes_avoided': totalCigarettesAvoided,
      'money_saved': moneySaved,
    };
  }
}
