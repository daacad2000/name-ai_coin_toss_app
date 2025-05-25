import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus { pendingGeneration, pendingReview, approved, rejected }

String reportStatusToString(ReportStatus status) => status.toString().split('.').last;
ReportStatus reportStatusFromString(String statusStr) =>
    ReportStatus.values.firstWhere((e) => e.toString().split('.').last == statusStr, orElse: () => ReportStatus.pendingGeneration);


class AIReport {
  final String? reportId;
  final String questionId;
  String reportText;
  final DateTime generatedTimestamp;
  final String sunSignUsed;
  ReportStatus status;
  DateTime? reviewedTimestamp;
  String? reviewerId;

  AIReport({
    this.reportId,
    required this.questionId,
    required this.reportText,
    required this.generatedTimestamp,
    required this.sunSignUsed,
    this.status = ReportStatus.pendingGeneration,
    this.reviewedTimestamp,
    this.reviewerId,
  });

  factory AIReport.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AIReport(
      reportId: doc.id,
      questionId: data['questionId'] as String,
      reportText: data['reportText'] as String,
      generatedTimestamp: (data['generatedTimestamp'] as Timestamp).toDate(),
      sunSignUsed: data['sunSignUsed'] as String,
      status: reportStatusFromString(data['status'] as String? ?? 'pendingGeneration'),
      reviewedTimestamp: (data['reviewedTimestamp'] as Timestamp?)?.toDate(),
      reviewerId: data['reviewerId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'questionId': questionId,
      'reportText': reportText,
      'generatedTimestamp': Timestamp.fromDate(generatedTimestamp),
      'sunSignUsed': sunSignUsed,
      'status': reportStatusToString(status),
      if (reviewedTimestamp != null) 'reviewedTimestamp': Timestamp.fromDate(reviewedTimestamp!),
      if (reviewerId != null) 'reviewerId': reviewerId,
    };
  }
}