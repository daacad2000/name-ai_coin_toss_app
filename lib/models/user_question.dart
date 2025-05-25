import 'package:cloud_firestore/cloud_firestore.dart';

class UserQuestion {
  final String? questionId; // Nullable if creating before saving to Firestore
  final String userId;
  final String questionText;
  final DateTime timestamp;
  bool isValidated;
  String coinTosserId;
  String reportWriterId;

  UserQuestion({
    this.questionId,
    required this.userId,
    required this.questionText,
    required this.timestamp,
    this.isValidated = false,
    required this.coinTosserId,
    required this.reportWriterId,
  });

  factory UserQuestion.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserQuestion(
      questionId: doc.id,
      userId: data['userId'] as String,
      questionText: data['questionText'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isValidated: data['isValidated'] as bool? ?? false,
      coinTosserId: data['coinTosserId'] as String,
      reportWriterId: data['reportWriterId'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'questionText': questionText,
      'timestamp': Timestamp.fromDate(timestamp),
      'isValidated': isValidated,
      'coinTosserId': coinTosserId,
      'reportWriterId': reportWriterId,
    };
  }
}