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
