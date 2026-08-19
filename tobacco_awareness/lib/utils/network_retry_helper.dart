import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkRetryHelper {
  /// Executes an async network task with exponential backoff retries.
  /// Standard delay sequence: 1s -> 2s -> 4s.
  static Future<T> executeWithRetry<T>(
    Future<T> Function() task, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    bool Function(Object error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      attempt++;
      try {
        return await task();
      } catch (error) {
        final isNetworkException = error is SocketException ||
            error is TimeoutException ||
            (error is HttpException) ||
            (shouldRetry != null && shouldRetry(error));

        if (attempt >= maxAttempts || !isNetworkException) {
          debugPrint('⚡ [NetworkRetryHelper] Max attempts reached or non-retryable error: $error');
          rethrow;
        }

        debugPrint('⚡ [NetworkRetryHelper] Retry attempt $attempt/$maxAttempts failed ($error). Retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * backoffMultiplier).round());
      }
    }
  }
}
