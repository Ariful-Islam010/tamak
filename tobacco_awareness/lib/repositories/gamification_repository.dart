import '../models/badge_model.dart';
import '../services/gamification_service.dart';
import '../utils/network_retry_helper.dart';

abstract class IGamificationRepository {
  Future<GamificationStatsModel> getStats();
  Future<void> syncStats(GamificationStatsModel stats);
}

class GamificationRepositoryImpl implements IGamificationRepository {
  final GamificationService _service;

  GamificationRepositoryImpl({GamificationService? service}) : _service = service ?? GamificationService();

  @override
  Future<GamificationStatsModel> getStats() async {
    try {
      return await NetworkRetryHelper.executeWithRetry(
        () => _service.fetchGamificationStats(),
        maxAttempts: 2,
      );
    } catch (_) {
      return await _service.loadCachedStats();
    }
  }

  @override
  Future<void> syncStats(GamificationStatsModel stats) async {
    await _service.syncGamificationState(stats);
  }
}
