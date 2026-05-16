class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  
  // Custom properties
  String? educationalInfo;
  String? tobaccoType;
  int? planDuration;
  DateTime? quitDate;
  
  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.educationalInfo,
    this.tobaccoType,
    this.planDuration,
    this.quitDate,
  });

  // Factory constructor to create UserModel from Firebase User
  factory UserModel.fromFirebaseUser(dynamic user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  // Method to copy with new properties
  UserModel copyWith({
    String? displayName,
    String? educationalInfo,
    String? tobaccoType,
    int? planDuration,
    DateTime? quitDate,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl,
      educationalInfo: educationalInfo ?? this.educationalInfo,
      tobaccoType: tobaccoType ?? this.tobaccoType,
      planDuration: planDuration ?? this.planDuration,
      quitDate: quitDate ?? this.quitDate,
    );
  }
}
