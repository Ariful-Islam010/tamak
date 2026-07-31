/// Helper utility for handling Bangladesh Standard Time (BST / UTC+6)
class TimeUtils {
  /// Returns current DateTime converted to Bangladesh Standard Time (UTC+6)
  static DateTime get nowBst {
    return DateTime.now().toUtc().add(const Duration(hours: 6));
  }

  /// Returns today's date string in 'YYYY-MM-DD' format based on BST (UTC+6)
  static String get todayBstDateString {
    return getBstDateString(nowBst);
  }

  /// Formats any given [dateTime] into 'YYYY-MM-DD' string in BST
  static String getBstDateString(DateTime dateTime) {
    // If not already adjusted to UTC+6, we convert UTC to BST
    final bstDate = dateTime.isUtc
        ? dateTime.add(const Duration(hours: 6))
        : dateTime.toUtc().add(const Duration(hours: 6));
    final year = bstDate.year.toString().padLeft(4, '0');
    final month = bstDate.month.toString().padLeft(2, '0');
    final day = bstDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Calculates calendar days difference between two dates in BST
  static int daysDifferenceBst(DateTime date1, DateTime date2) {
    final d1 = DateTime.utc(date1.year, date1.month, date1.day);
    final d2 = DateTime.utc(date2.year, date2.month, date2.day);
    return d1.difference(d2).inDays;
  }
}
