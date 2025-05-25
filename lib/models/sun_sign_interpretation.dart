import 'package:cloud_firestore/cloud_firestore.dart';

class SunSignInterpretation {
  final String signId; // e.g., "aries" (document ID in Firestore)
  final String signName; // e.g., "Aries"
  final String generalInterpretationText;

  SunSignInterpretation({
    required this.signId,
    required this.signName,
    required this.generalInterpretationText,
  });

  factory SunSignInterpretation.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SunSignInterpretation(
      signId: doc.id,
      signName: data['signName'] as String,
      generalInterpretationText: data['generalInterpretationText'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'signName': signName,
      'generalInterpretationText': generalInterpretationText,
    };
  }
}