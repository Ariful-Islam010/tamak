import 'package:flutter_test/flutter_test.dart';
import 'package:quit_mate/utils/time_utils.dart';

void main() {
  group('TimeUtils Unit Tests', () {
    test('todayBstDateString সঠিক YYYY-MM-DD ফরম্যাটে দেখায়', () {
      final result = TimeUtils.todayBstDateString;
      // YYYY-MM-DD ফরম্যাট চেক করছি regex দিয়ে
      expect(result, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });

    test('getBstDateString UTC time কে BST (UTC+6) তে কনভার্ট করে', () {
      // UTC তে ১ জানুয়ারি রাত ১১টা = BST তে ২ জানুয়ারি সকাল ৫টা
      final utcTime = DateTime.utc(2024, 1, 1, 23, 0, 0);
      final result = TimeUtils.getBstDateString(utcTime);
      expect(result, equals('2024-01-02'));
    });

    test('getBstDateString Local time হলে সরাসরি ব্যবহার করে', () {
      final localTime = DateTime(2024, 6, 15);
      final result = TimeUtils.getBstDateString(localTime);
      expect(result, equals('2024-06-15'));
    });

    test('daysDifferenceBst দুই তারিখের পার্থক্য সঠিকভাবে গণনা করে', () {
      final date1 = DateTime(2024, 6, 20);
      final date2 = DateTime(2024, 6, 15);
      final diff = TimeUtils.daysDifferenceBst(date1, date2);
      expect(diff, equals(5));
    });

    test('daysDifferenceBst একই তারিখ হলে 0 দেখায়', () {
      final date = DateTime(2024, 6, 15);
      expect(TimeUtils.daysDifferenceBst(date, date), equals(0));
    });

    test('daysDifferenceBst আগের তারিখ দিলে negative দেখায়', () {
      final earlier = DateTime(2024, 6, 10);
      final later = DateTime(2024, 6, 15);
      expect(TimeUtils.daysDifferenceBst(earlier, later), equals(-5));
    });

    test('nowBst DateTime object রিটার্ন করে', () {
      final now = TimeUtils.nowBst;
      expect(now, isA<DateTime>());
    });
  });
}
