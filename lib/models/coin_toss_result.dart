import 'package:cloud_firestore/cloud_firestore.dart';

class CoinTossResult {
  final String? resultId;
  final String questionId;
  final int headsCount;
  final int tailsCount;
  final DateTime timestamp;

  CoinTossResult({
    this.resultId,
    required this.questionId,
    required this.headsCount,
    required this.tailsCount,
    required this.timestamp,
  });

   factory CoinTossResult.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CoinTossResult(
      resultId: doc.id,
      questionId: data['questionId'] as String,
      headsCount: data['headsCount'] as int,
      tailsCount: data['tailsCount'] as int,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'questionId': questionId,
      'headsCount': headsCount,
      'tailsCount': tailsCount,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}