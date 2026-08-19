class GamificationStatsModel {
  final int currentStreak;
  final int longestStreak;
  final int totalTobaccoFreeDays;
  final int totalCheckIns;
  final int totalSavingsAmount;
  final int planDuration;
  final int sosCount;
  final int messagesCount;
  final int plantStage;
  final bool hasPestAttack;
  final int pestDaysClean;
  final int completedTrees;
  final int completedTasksCount;
  final bool hasPlan;

  GamificationStatsModel({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalTobaccoFreeDays = 0,
    this.totalCheckIns = 0,
    this.totalSavingsAmount = 0,
    this.planDuration = 7,
    this.sosCount = 0,
    this.messagesCount = 0,
    this.plantStage = 0,
    this.hasPestAttack = false,
    this.pestDaysClean = 0,
    this.completedTrees = 0,
    this.completedTasksCount = 0,
    this.hasPlan = false,
  });

  factory GamificationStatsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return GamificationStatsModel();
    return GamificationStatsModel(
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      totalTobaccoFreeDays: (json['total_tobacco_free_days'] as num?)?.toInt() ?? 0,
      totalCheckIns: (json['total_check_ins'] as num?)?.toInt() ?? 0,
      totalSavingsAmount: (json['total_savings_amount'] as num?)?.toInt() ?? 0,
      planDuration: (json['plan_duration'] as num?)?.toInt() ?? 7,
      sosCount: (json['sos_count'] as num?)?.toInt() ?? 0,
      messagesCount: (json['messages_count'] as num?)?.toInt() ?? 0,
      plantStage: (json['plant_stage'] as num?)?.toInt() ?? 0,
      hasPestAttack: json['has_pest_attack'] as bool? ?? false,
      pestDaysClean: (json['pest_days_clean'] as num?)?.toInt() ?? 0,
      completedTrees: (json['completed_trees'] as num?)?.toInt() ?? 0,
      completedTasksCount: (json['completed_tasks_count'] as num?)?.toInt() ?? 0,
      hasPlan: json['has_plan'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_tobacco_free_days': totalTobaccoFreeDays,
      'total_check_ins': totalCheckIns,
      'total_savings_amount': totalSavingsAmount,
      'plan_duration': planDuration,
      'sos_count': sosCount,
      'messages_count': messagesCount,
      'plant_stage': plantStage,
      'has_pest_attack': hasPestAttack,
      'pest_days_clean': pestDaysClean,
      'completed_trees': completedTrees,
      'completed_tasks_count': completedTasksCount,
      'has_plan': hasPlan,
    };
  }
}
