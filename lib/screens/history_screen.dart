import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../models/user_question.dart';
import '../models/ai_report.dart'; // For displaying report status or summary

class HistoryScreen extends StatefulWidget {
  static const routeName = '/history';

  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<UserQuestion>> _historyFuture;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    if (authProvider.userId != null) {
      _historyFuture = databaseService.getUserQuestionHistory(authProvider.userId!);
    } else {
      // Handle case where user is not logged in, though AuthGate should prevent this.
      _historyFuture = Future.value([]);
    }
  }

  Future<List<AIReport>> _fetchReportsForQuestion(String questionId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
     if (authProvider.userId != null && questionId.isNotEmpty) { // Ensure questionId is not empty
      return databaseService.getReportsForQuestion(authProvider.userId!, questionId);
    }
    return [];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Insights History')),
      body: FutureBuilder<List<UserQuestion>>(
        future: _historyFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No history yet. Ask some questions!'));
          } else {
            final historyItems = snapshot.data!;
            return ListView.builder(
              itemCount: historyItems.length,
              itemBuilder: (ctx, index) {
                final item = historyItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(item.questionText, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('Asked on: ${item.timestamp.toLocal().toString().split(' ')[0]}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      if (item.questionId == null || item.questionId!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Missing question ID.")));
                        return;
                      }
                      showDialog(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          title: const Text("Question Details"),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("Question:", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(item.questionText),
                                const SizedBox(height: 10),
                                // You might want to resolve IDs to names here if you store AICharacter details in AppStateProvider
                                Text("Tossed by Character ID: ${item.coinTosserId}"),
                                Text("Report by Character ID: ${item.reportWriterId}"),
                                const SizedBox(height: 10),
                                const Text("Report Details:", style: TextStyle(fontWeight: FontWeight.bold)),
                                FutureBuilder<List<AIReport>>(
                                  future: _fetchReportsForQuestion(item.questionId!),
                                  builder: (context, reportSnapshot) {
                                    if (reportSnapshot.connectionState == ConnectionState.waiting) {
                                      return const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator());
                                    }
                                    if (reportSnapshot.hasError || !reportSnapshot.hasData || reportSnapshot.data!.isEmpty) {
                                      return const Text("No report found or error loading.", style: TextStyle(fontStyle: FontStyle.italic));
                                    }
                                    final report = reportSnapshot.data!.first;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Status: ${reportStatusToString(report.status)}", style: TextStyle(color: report.status == ReportStatus.approved ? Colors.green.shade700 : Colors.orange.shade700)),
                                        if(report.status == ReportStatus.approved) ...[
                                          const SizedBox(height: 8),
                                          const Text("Content:", style: TextStyle(fontWeight: FontWeight.bold)),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(4)
                                            ),
                                            child: Text(report.reportText, style: const TextStyle(fontSize: 13)),
                                          ),
                                        ] else if (report.status == ReportStatus.pendingReview) ...[
                                            const SizedBox(height: 8),
                                            const Text("This report is currently awaiting review by our team.", style: TextStyle(fontStyle: FontStyle.italic)),
                                        ] else if (report.status == ReportStatus.rejected) ...[
                                          const SizedBox(height: 8),
                                          Text("This report was not approved.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.red.shade700)),
                                        ],
                                      ],
                                    );
                                  },
                                )
                              ],
                            ),
                          ),
                          actions: [TextButton(child: const Text("Close"), onPressed: () => Navigator.of(dialogCtx).pop())],
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}