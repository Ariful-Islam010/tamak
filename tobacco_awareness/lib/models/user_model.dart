class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  // Profile fields matching DB schema
  String? educationalInfo;
  int? planDuration;
  DateTime? quitDate;
  String? aiQuitPlan;
  int? age;
  String? gender;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.educationalInfo,
    this.planDuration,
    this.quitDate,
    this.aiQuitPlan,
    this.age,
    this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return UserModel(uid: '');
    }
    int? parseNum(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }
    return UserModel(
      uid: json['uid']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email']?.toString(),
      displayName: json['displayName']?.toString() ?? json['display_name']?.toString(),
      photoUrl: json['photoUrl']?.toString() ?? json['photo_url']?.toString(),
      educationalInfo: json['educationalInfo']?.toString() ?? json['educational_info']?.toString(),
      planDuration: parseNum(json['planDuration'] ?? json['plan_duration']),
      quitDate: json['quitDate'] != null
          ? DateTime.tryParse(json['quitDate'].toString())
          : json['quit_date'] != null
              ? DateTime.tryParse(json['quit_date'].toString())
              : null,
      aiQuitPlan: json['aiQuitPlan']?.toString() ?? json['ai_quit_plan']?.toString(),
      age: parseNum(json['age']),
      gender: json['gender']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'educationalInfo': educationalInfo,
      'planDuration': planDuration,
      'quitDate': quitDate?.toIso8601String(),
      'aiQuitPlan': aiQuitPlan,
      'age': age,
      'gender': gender,
    };
  }

  UserModel copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    String? educationalInfo,
    int? planDuration,
    DateTime? quitDate,
    String? aiQuitPlan,
    int? age,
    String? gender,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      educationalInfo: educationalInfo ?? this.educationalInfo,
      planDuration: planDuration ?? this.planDuration,
      quitDate: quitDate ?? this.quitDate,
      aiQuitPlan: aiQuitPlan ?? this.aiQuitPlan,
      age: age ?? this.age,
      gender: gender ?? this.gender,
    );
  }
}
