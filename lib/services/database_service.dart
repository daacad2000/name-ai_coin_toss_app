import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/sun_sign_interpretation.dart';
import '../models/user_question.dart';
import '../models/coin_toss_result.dart';
import '../models/ai_report.dart';


class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User Profile ---
  Future<void> saveUserProfile(UserProfile userProfile) async {
    try {
      await _db.collection('users').doc(userProfile.userId).set(userProfile.toFirestore());
    } catch (e) {
      print("Error saving user profile: $e");
      // Optionally rethrow or handle error
    }
  }

  Future<void> updateUserProfile(UserProfile userProfile) async {
    // Use update for partial updates if needed, set with merge for full object update
     try {
      await _db.collection('users').doc(userProfile.userId).set(userProfile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      print("Error updating user profile: $e");
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
    return null;
  }

  // --- Sun Sign Interpretations (Pre-loaded Data) ---
  Future<List<SunSignInterpretation>> getSunSignInterpretations() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _db.collection('SunSignInterpretations').get();
      return snapshot.docs.map((doc) => SunSignInterpretation.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching sun sign interpretations: $e");
      return [];
    }
  }
  // Note: You'll need to manually populate the 'SunSignInterpretations' collection in Firestore one time.
  // Example document in 'SunSignInterpretations' collection (Document ID: 'aries'):
  // { "signName": "Aries", "generalInterpretationText": "Aries are known for..." }


  // --- User Questions ---
  Future<DocumentReference?> saveUserQuestion(UserQuestion question) async {
    try {
      // userId should be set before calling this
      return await _db.collection('users').doc(question.userId).collection('userQuestions').add(question.toFirestore());
    } catch (e) {
      print("Error saving user question: $e");
      return null;
    }
  }

  Future<void> updateUserQuestion(UserQuestion question) async {
     if (question.questionId == null) return;
     try {
      await _db.collection('users').doc(question.userId).collection('userQuestions').doc(question.questionId).update(question.toFirestore());
    } catch (e) {
      print("Error updating user question: $e");
    }
  }

  // --- Coin Toss Results (Example: store as sub-collection of question) ---
  Future<void> saveCoinTossResult(CoinTossResult result, String userId, String questionId) async {
    try {
       await _db.collection('users').doc(userId).collection('userQuestions').doc(questionId).collection('coinTossResults').add(result.toFirestore());
    } catch (e) {
      print("Error saving coin toss result: $e");
    }
  }

  // --- AI Reports (Example: store as sub-collection of question) ---
  Future<DocumentReference?> saveAIReport(AIReport report, String userId, String questionId) async {
     try {
       // The report's questionId field should already link it.
       // Storing under user/question for easy querying and security rules.
       return await _db.collection('users').doc(userId).collection('userQuestions').doc(questionId).collection('aiReports').add(report.toFirestore());
    } catch (e) {
      print("Error saving AI report: $e");
      return null;
    }
  }

   Future<void> updateAIReport(AIReport report, String userId, String questionId) async {
    if (report.reportId == null) return;
    try {
      await _db.collection('users').doc(userId).collection('userQuestions').doc(questionId).collection('aiReports').doc(report.reportId).update(report.toFirestore());
    } catch (e) {
      print("Error updating AI Report: $e");
    }
  }


  // --- History Fetching (Simplified - gets all questions for a user) ---
  Future<List<UserQuestion>> getUserQuestionHistory(String userId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('userQuestions')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => UserQuestion.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching user question history: $e");
      return [];
    }
  }

  // You'll also need methods to fetch the associated reports and toss results for each question in history.
  // This can be done by fetching sub-collections when a specific history item is selected.
  Future<List<AIReport>> getReportsForQuestion(String userId, String questionId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection('users').doc(userId).collection('userQuestions').doc(questionId).collection('aiReports')
          .orderBy('generatedTimestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => AIReport.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching reports for question $questionId: $e");
      return [];
    }
  }
}