/// Helper utility for handling Bangladesh Standard Time (BST / UTC+6)
class TimeUtils {
  /// Returns current local DateTime (device is already in BST/UTC+6)
  static DateTime get nowBst {
    // DateTime.now() is already local time. If device timezone is correctly
    // set to Bangladesh (UTC+6), this is already BST.
    // We do NOT double-convert by calling toUtc().add(6h).
    return DateTime.now();
  }

  /// Returns today's date string in 'YYYY-MM-DD' format
  static String get todayBstDateString {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Formats any given [dateTime] into 'YYYY-MM-DD' string
  static String getBstDateString(DateTime dateTime) {
    final dt = dateTime.toLocal();
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Calculates calendar days difference between two dates in local timezone
  static int daysDifferenceBst(DateTime date1, DateTime date2) {
    final local1 = date1.toLocal();
    final local2 = date2.toLocal();
    final d1 = DateTime(local1.year, local1.month, local1.day);
    final d2 = DateTime(local2.year, local2.month, local2.day);
    return d1.difference(d2).inDays;
  }
}
