import 'dart:async';
import 'dart:io';

/// Utility for turning raw technical exceptions into professional, user-friendly messages
class ErrorUtils {
  static String getFriendlyErrorMessage(dynamic error) {
    if (error == null) return "অপ্রত্যাশিত একটি সমস্যা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন। 🙏";
    final errorStr = error.toString().toLowerCase();

    if (error is SocketException ||
        errorStr.contains('socketexception') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('connection timed out') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('no route to host') ||
        errorStr.contains('network_error') ||
        errorStr.contains('networkerror')) {
      return "ইন্টারনেট সংযোগ পাওয়া যাচ্ছে না। আপনার মোবাইল ডাটা বা ওয়াইফাই পরীক্ষা করুন। 📡";
    }

    if (error is TimeoutException ||
        errorStr.contains('timeout') ||
        errorStr.contains('timed out')) {
      return "সার্ভার থেকে সাড়া পেতে দেরি হচ্ছে। অনুগ্রহ করে একটু পর আবার চেষ্টা করুন। ⏳";
    }

    if (errorStr.contains('sign_in_cancelled') ||
        errorStr.contains('canceled') ||
        errorStr.contains('cancelled')) {
      return "সাইন-ইন প্রক্রিয়াটি বাতিল করা হয়েছে। 🔄";
    }

    return "দুঃখিত, অনুরোধটি সম্পন্ন করা সম্ভব হয়নি। কিছুক্ষণ পর আবার চেষ্টা করুন। 🙏";
  }
}
