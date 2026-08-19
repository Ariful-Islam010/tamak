import '../models/money_saving_model.dart';
import '../services/money_saver_service.dart';
import '../utils/network_retry_helper.dart';

abstract class IMoneySaverRepository {
  Future<List<MoneySavingRecord>> getSavings();
  Future<List<SavingsGoalModel>> getGoals();
  Future<bool> saveMoney(int amount);
  Future<bool> createGoal({required String title, required int targetAmount});
}

class MoneySaverRepositoryImpl implements IMoneySaverRepository {
  final MoneySaverService _service;

  MoneySaverRepositoryImpl({MoneySaverService? service}) : _service = service ?? MoneySaverService();

  static const int maxAmountLimit = 10000;

  @override
  Future<List<MoneySavingRecord>> getSavings() async {
    try {
      return await NetworkRetryHelper.executeWithRetry(
        () => _service.fetchSavings(),
        maxAttempts: 2,
      );
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<SavingsGoalModel>> getGoals() async {
    try {
      return await NetworkRetryHelper.executeWithRetry(
        () => _service.fetchGoals(),
        maxAttempts: 2,
      );
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> saveMoney(int amount) async {
    int safeAmount = amount > maxAmountLimit ? maxAmountLimit : amount;
    return await _service.addMoneySaved(safeAmount);
  }

  @override
  Future<bool> createGoal({required String title, required int targetAmount}) async {
    int safeTarget = targetAmount > maxAmountLimit ? maxAmountLimit : targetAmount;
    return await _service.addGoal(title: title, targetAmount: safeTarget);
  }
}
