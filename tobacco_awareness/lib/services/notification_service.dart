import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Notification IDs
  static const int _morningReminderId = 1;
  static const int _eveningCheckInId = 2;
  static const int _streakReminderId = 3;
  static const int _motivationId = 4;
  static const int _planCompletionReminderId = 5;
  static const int _viewPlanReminderId = 6;
  static const int _instantId = 99;

  /// Initialize the notification service - call this in main()
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    _initialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  /// Create high-importance notification channel (Android 8+)
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'tobacco_awareness_channel',
      'তামাকমুক্ত জীবন',
      description: 'তামাক ছাড়ার অনুপ্রেরণামূলক বিজ্ঞপ্তি',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Request notification permission (Android 13+)
  Future<bool> requestPermission() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      final exactAlarmGranted =
          await androidImpl.requestExactAlarmsPermission();
      debugPrint(
          '🔔 Notification permission: $granted, Exact alarm: $exactAlarmGranted');
      return granted ?? false;
    }
    return true;
  }

  // ──────────────────────────────────────────────
  // NOTIFICATION DETAILS
  // ──────────────────────────────────────────────

  NotificationDetails _buildDetails({
    String channelId = 'tobacco_awareness_channel',
    String channelName = 'তামাকমুক্ত জীবন',
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: priority,
      playSound: true,
      enableVibration: true,
      styleInformation: const DefaultStyleInformation(true, true),
      icon: '@mipmap/launcher_icon',
      color: const Color(0xFF2E7D32),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  // ──────────────────────────────────────────────
  // INSTANT / ON-DEMAND NOTIFICATIONS
  // ──────────────────────────────────────────────

  /// Show an instant notification immediately
  Future<void> showInstantNotification({
    required String title,
    required String body,
    int id = _instantId,
  }) async {
    await _plugin.show(id, title, body, _buildDetails());
  }

  /// Show a welcome notification when user logs in
  Future<void> showWelcomeNotification(String name) async {
    await showInstantNotification(
      title: '🌿 স্বাগতম, $name!',
      body: 'আজ থেকে তামাকমুক্ত জীবনের যাত্রা শুরু। আপনি পারবেন! 💪',
      id: 10,
    );
  }

  /// Show streak milestone notification
  Future<void> showStreakNotification(int days) async {
    String emoji = days >= 7
        ? '🏆'
        : days >= 3
            ? '🔥'
            : '⭐';
    await showInstantNotification(
      title: '$emoji $days দিন তামাকমুক্ত!',
      body: _getStreakMessage(days),
      id: 11,
    );
  }

  /// Show savings milestone notification
  Future<void> showSavingsNotification(double amount) async {
    await showInstantNotification(
      title: '💰 সাশ্রয় মাইলফলক!',
      body: 'আপনি এখন পর্যন্ত ৳${amount.toStringAsFixed(0)} সাশ্রয় করেছেন!',
      id: 12,
    );
  }

  /// Show task completion notification
  Future<void> showTaskCompleteNotification(int completedCount, int total) async {
    if (completedCount == total) {
      await showInstantNotification(
        title: '🎉 সব কাজ সম্পন্ন!',
        body: 'আজকের সব চ্যালেঞ্জ সম্পন্ন হয়েছে। অসাধারণ কাজ করেছেন!',
        id: 13,
      );
    } else {
      await showInstantNotification(
        title: '✅ কাজ সম্পন্ন! ($completedCount/$total)',
        body: 'চালিয়ে যান! আরও ${total - completedCount}টি কাজ বাকি।',
        id: 13,
      );
    }
  }

  // ──────────────────────────────────────────────
  // SCHEDULED DAILY NOTIFICATIONS
  // ──────────────────────────────────────────────

  /// Schedule all daily reminders (call after login/setup)
  Future<void> scheduleAllDailyNotifications({
    DateTime? quitDate,
    String? currentDayTitle,
  }) async {
    await scheduleMorningMotivation(
      quitDate: quitDate,
      currentDayTitle: currentDayTitle,
    );
    await scheduleEveningCheckIn(quitDate: quitDate);
    await scheduleStreakReminder();
    await scheduleViewPlanReminder(hasAnsweredToday: false);
    debugPrint('📅 All daily notifications scheduled');
  }

  /// Morning motivation at 8:00 AM daily — plan-aware
  Future<void> scheduleMorningMotivation({
    DateTime? quitDate,
    String? currentDayTitle,
  }) async {
    await _plugin.cancel(_morningReminderId);

    final scheduledTime = _nextInstanceOf(8, 0);

    // Determine title and body based on plan status
    String notifTitle;
    String notifBody;

    if (quitDate != null) {
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final quitDay = DateTime(quitDate.year, quitDate.month, quitDate.day);
      final diff = today.difference(quitDay).inDays;

      if (diff < 0) {
        // Plan hasn't started yet
        final daysLeft = -diff;
        notifTitle = '⏳ পরিকল্পনা শুরু হতে $daysLeft দিন বাকি!';
        notifBody = 'প্রস্তুত থাকুন। তামাকমুক্ত জীবনের যাত্রা শুরু হতে চলেছে! 🜏';
      } else if (diff == 0) {
        // Day 1
        notifTitle = '🌅 আজ আপনার পরিকল্পনার ১ম দিন!';
        notifBody = currentDayTitle != null
            ? 'আজকের লক্ষ্য: $currentDayTitle - আপনি পারবেন! 💪'
            : 'তামাকমুক্ত যাত্রার প্রথম দিনে স্বাগতম! 🌱';
      } else {
        // Ongoing plan
        final dayNum = diff + 1;
        notifTitle = '🌅 সুপ্রভাত! পরিকল্পনার $dayNum তম দিন';
        notifBody = currentDayTitle != null
            ? 'আজকের লক্ষ্য: $currentDayTitle'
            : _getRandomMorningMessage();
      }
    } else {
      notifTitle = '🌅 সুপ্রভাত! নতুন দিন, নতুন সংকল্প';
      notifBody = _getRandomMorningMessage();
    }

    await _plugin.zonedSchedule(
      _morningReminderId,
      notifTitle,
      notifBody,
      scheduledTime,
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('⏰ Morning notification scheduled at 8:00 AM');
  }

  /// Evening check-in reminder at 8:00 PM daily
  Future<void> scheduleEveningCheckIn({DateTime? quitDate, bool forceTomorrow = false}) async {
    await _plugin.cancel(_eveningCheckInId);

    final scheduledTime = _nextInstanceOf(20, 0, forceTomorrow: forceTomorrow);

    // Use a generic body — since this repeats daily via matchDateTimeComponents,
    // a static day-number would become stale (always show "Day 2" etc).
    const String body = 'আজকের তামাক-মুক্ত দিন কেমন ছিল? চেক-ইন করুন এবং পয়েন্ট অর্জন করুন! 🌟';

    await _plugin.zonedSchedule(
      _eveningCheckInId,
      '📋 আজকের চেক-ইন করুন',
      body,
      scheduledTime,
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('⏰ Evening check-in scheduled at 8:00 PM');
  }

  /// Streak reminder at 12:00 PM daily (motivational push)
  Future<void> scheduleStreakReminder() async {
    await _plugin.cancel(_streakReminderId);

    final scheduledTime = _nextInstanceOf(12, 0);

    await _plugin.zonedSchedule(
      _streakReminderId,
      '💪 আপনার স্ট্রিক ধরে রাখুন!',
      'প্রতিদিনের ছোট পদক্ষেপ বড় পরিবর্তন আনে। আজও তামাকমুক্ত থাকুন!',
      scheduledTime,
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('⏰ Streak reminder scheduled at 12:00 PM');
  }

  /// Schedule a one-time notification at specific time
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    final tz.TZDateTime tzDateTime = tz.TZDateTime.from(scheduledAt, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ──────────────────────────────────────────────
  // CANCEL NOTIFICATIONS
  // ──────────────────────────────────────────────

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    debugPrint('🚫 All notifications cancelled');
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel only scheduled daily notifications (keep instant ones)
  Future<void> cancelDailyNotifications() async {
    await _plugin.cancel(_morningReminderId);
    await _plugin.cancel(_eveningCheckInId);
    await _plugin.cancel(_streakReminderId);
    await _plugin.cancel(_motivationId);
    await _plugin.cancel(_planCompletionReminderId);
    await _plugin.cancel(_viewPlanReminderId);
  }

  // ──────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────

  /// Get next scheduled time for a given hour:minute
  tz.TZDateTime _nextInstanceOf(int hour, int minute, {bool forceTomorrow = false}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now) || forceTomorrow) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.id}');
    // Navigation can be handled here if needed
  }

  String _getStreakMessage(int days) {
    if (days == 1) return 'প্রথম দিন সফলভাবে পার করেছেন! এটা একটা বড় পদক্ষেপ।';
    if (days == 3) return '৩ দিন ধরে তামাকমুক্ত! আপনার ফুসফুস পরিষ্কার হচ্ছে।';
    if (days == 7) return 'এক সপ্তাহ তামাকমুক্ত! আপনি একজন চ্যাম্পিয়ন! 🏆';
    if (days == 14) return 'দুই সপ্তাহ! আপনার শরীরে ইতিমধ্যে বড় পরিবর্তন আসছে।';
    if (days == 30) return 'এক মাস তামাকমুক্ত! অবিশ্বাস্য! আপনি অনুপ্রেরণা! 🌟';
    return '$days দিন ধরে তামাকমুক্ত থাকা অসাধারণ কীর্তি! চালিয়ে যান!';
  }

  String _getRandomMorningMessage() {
    final messages = [
      'আজও তামাকমুক্ত থাকার সংকল্প করুন। আপনি পারবেন! 🌿',
      'প্রতিটি তামাকমুক্ত দিন আপনার জীবনকে দীর্ঘায়িত করছে। 💚',
      'আজকের কাজগুলো সম্পন্ন করুন এবং পয়েন্ট অর্জন করুন!',
      'আপনার পরিবারের জন্য সুস্থ থাকুন। তামাক ছাড়ুন!',
      'শরীর সুস্থ, মন সুস্থ - তামাকমুক্ত জীবন সুন্দর! 🌸',
    ];
    final index = DateTime.now().day % messages.length;
    return messages[index];
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      return await androidImpl.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  /// Get all pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }

  /// Schedule a one-time reminder at 9:00 PM to complete today's plan if not answered yet
  Future<void> schedulePlanCompletionReminder({required bool hasAnsweredToday}) async {
    await _plugin.cancel(_planCompletionReminderId);

    if (hasAnsweredToday) {
      debugPrint('Plan completion reminder cancelled: User already responded today');
      return;
    }

    final now = DateTime.now();
    final reminderTime = DateTime(now.year, now.month, now.day, 21, 0); // 9:00 PM

    DateTime scheduledTime = reminderTime;
    if (now.isAfter(reminderTime)) {
      scheduledTime = reminderTime.add(const Duration(days: 1));
    }

    final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      _planCompletionReminderId,
      '📋 আজকের পরিকল্পনা সম্পন্ন করেছেন?',
      'আজকের তামাক বর্জন লক্ষ্য কি সম্পন্ন করেছেন? হ্যাঁ অথবা না ক্লিক করে আপডেট করুন!',
      tzDateTime,
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('⏰ Plan completion reminder scheduled for: $scheduledTime');
  }

  /// Schedule daily reminder to view today's quit plan at 10:00 AM
  Future<void> scheduleViewPlanReminder({required bool hasAnsweredToday}) async {
    await _plugin.cancel(_viewPlanReminderId);

    // If already answered today, schedule for tomorrow
    final scheduledTime = _nextInstanceOf(10, 0, forceTomorrow: hasAnsweredToday);

    await _plugin.zonedSchedule(
      _viewPlanReminderId,
      '📋 আজকের তামাকমুক্ত পরিকল্পনা',
      'আপনার আজকের লক্ষ্য ও এআই টাস্কটি দেখে নিন এবং দিনটি সফল করুন! 🌿',
      scheduledTime,
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('⏰ View plan reminder scheduled. forceTomorrow: $hasAnsweredToday');
  }
}
