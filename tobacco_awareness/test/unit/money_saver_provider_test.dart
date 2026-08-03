import 'package:flutter_test/flutter_test.dart';
import 'package:tamakmukto_jibon/providers/money_saver_provider.dart';

/// MoneySaverProvider-এর pure logic টেস্ট করার জন্য
/// একটি টেস্টযোগ্য সাবক্লাস তৈরি করা হয়েছে
/// যেটি HiveHelper বা HTTP ছাড়াই কাজ করে
class TestableMoneySaverProvider extends MoneySaverProvider {
  TestableMoneySaverProvider() : super.testable();
}

void main() {
  group('MoneySaverProvider - getAllocatedSavings() Unit Tests', () {
    late MoneySaverProvider provider;

    setUp(() {
      provider = MoneySaverProvider.testable();
    });

    test('কোনো Dream না থাকলে খালি লিস্ট রিটার্ন করে', () {
      provider.setTestData(totalSavings: 500, dreams: []);
      expect(provider.getAllocatedSavings(), isEmpty);
    });

    test('১টি Dream থাকলে পুরো সেভিংস সেটিতেই বরাদ্দ হয়', () {
      provider.setTestData(
        totalSavings: 500,
        dreams: [
          {'title': 'বই', 'target': 1000},
        ],
      );
      final allocations = provider.getAllocatedSavings();
      expect(allocations[0], equals(500));
    });

    test('Dream পূরণ হলে বাকি টাকা পরেরটিতে যায়', () {
      provider.setTestData(
        totalSavings: 1500,
        dreams: [
          {'title': 'বই', 'target': 1000},  // index 0 = নতুন
          {'title': 'কলম', 'target': 500},  // index 1 = পুরনো
        ],
      );
      final allocations = provider.getAllocatedSavings();
      // পুরনো dream (index 1) আগে পূরণ হয়: ৫০০
      expect(allocations[1], equals(500));
      // নতুন dream (index 0): ১৫০০ - ৫০০ = ১০০০
      expect(allocations[0], equals(1000));
    });

    test('টাকা কম থাকলে আংশিক বরাদ্দ হয়', () {
      provider.setTestData(
        totalSavings: 200,
        dreams: [
          {'title': 'বই', 'target': 1000},
        ],
      );
      expect(provider.getAllocatedSavings()[0], equals(200));
    });

    test('hasUnachievedDream — Dream না থাকলে false দেখায়', () {
      provider.setTestData(totalSavings: 0, dreams: []);
      expect(provider.hasUnachievedDream, isFalse);
    });

    test('hasUnachievedDream — টাকা কম থাকলে true দেখায়', () {
      provider.setTestData(
        totalSavings: 100,
        dreams: [
          {'title': 'বই', 'target': 1000},
        ],
      );
      expect(provider.hasUnachievedDream, isTrue);
    });

    test('hasUnachievedDream — সব Dream পূরণ হলে false দেখায়', () {
      provider.setTestData(
        totalSavings: 1000,
        dreams: [
          {'title': 'বই', 'target': 1000},
        ],
      );
      expect(provider.hasUnachievedDream, isFalse);
    });
  });
}
