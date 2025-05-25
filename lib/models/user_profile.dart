import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  String? email;
  DateTime? birthDate;
  String? zodiacSign;
  String? defaultCoinTosserId;
  String? defaultReportWriterId;

  UserProfile({
    required this.userId,
    this.email,
    this.birthDate,
    this.zodiacSign,
    this.defaultCoinTosserId,
    this.defaultReportWriterId,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserProfile(
      userId: doc.id,
      email: data['email'] as String?,
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      zodiacSign: data['zodiacSign'] as String?,
      defaultCoinTosserId: data['defaultCoinTosserId'] as String?,
      defaultReportWriterId: data['defaultReportWriterId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (email != null) 'email': email,
      if (birthDate != null) 'birthDate': Timestamp.fromDate(birthDate!),
      if (zodiacSign != null) 'zodiacSign': zodiacSign,
      if (defaultCoinTosserId != null) 'defaultCoinTosserId': defaultCoinTosserId,
      if (defaultReportWriterId != null) 'defaultReportWriterId': defaultReportWriterId,
    };
  }
}