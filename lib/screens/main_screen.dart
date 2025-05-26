import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/app_state_provider.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../models/user_question.dart';
import '../models/coin_toss_result.dart';
import '../models/ai_report.dart';
import '../models/ai_character.dart';
import '../widgets/toss_simulation_view_with_canvas.dart';
import 'history_screen.dart';


class MainScreen extends StatefulWidget {
  static const routeName = '/main';

  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _questionController = TextEditingController();
  final AIService _aiService = AIService();

  bool _showSimulation = false;
  String? _currentQuestionId;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);

      if (authProvider.userProfile?.defaultCoinTosserId != null) {
        try {
          final tosser = appStateProvider.availableCharacters.firstWhere(
              (c) => c.characterId == authProvider.userProfile!.defaultCoinTosserId);
          appStateProvider.selectCoinTosser(tosser);
        } catch (e) {
           if (appStateProvider.availableCharacters.any((c) => c.role == AIChatacterRole.coinTosser)) {
             appStateProvider.selectCoinTosser(appStateProvider.availableCharacters.firstWhere((c) => c.role == AIChatacterRole.coinTosser));
           }
        }
      } else if (appStateProvider.selectedCoinTosser == null && appStateProvider.availableCharacters.any((c) => c.role == AIChatacterRole.coinTosser)) {
         appStateProvider.selectCoinTosser(appStateProvider.availableCharacters.firstWhere((c) => c.role == AIChatacterRole.coinTosser));
      }


      if (authProvider.userProfile?.defaultReportWriterId != null) {
         try {
            final writer = appStateProvider.availableCharacters.firstWhere(
              (c) => c.characterId == authProvider.userProfile!.defaultReportWriterId);
            appStateProvider.selectReportWriter(writer);
         } catch (e) {
            if (appStateProvider.availableCharacters.any((c) => c.role == AIChatacterRole.reportWriter)) {
              appStateProvider.selectReportWriter(appStateProvider.availableCharacters.firstWhere((c) => c.role == AIChatacterRole.reportWriter));
            }
         }
      } else if (appStateProvider.selectedReportWriter == null && appStateProvider.availableCharacters.any((c) => c.role == AIChatacterRole.reportWriter)) {
         appStateProvider.selectReportWriter(appStateProvider.availableCharacters.firstWhere((c) => c.role == AIChatacterRole.reportWriter));
      }
    });
  }


  Future<void> _submitQuestionAndStartFlow() async {
    final questionText = _questionController.text.trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);


    if (questionText.isEmpty || authProvider.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a question.')));
      return;
    }
    if (appStateProvider.selectedCoinTosser == null || appStateProvider.selectedReportWriter == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select AI characters first.')));
        return;
    }

    appStateProvider.resetQuestionFlowStates();
    appStateProvider.setQuestionValidating(true);

    QuestionValidationResult validationResult = await _aiService.validateQuestionWithAI(questionText);
    if (!mounted) return;
    appStateProvider.setQuestionValidating(false, feedback: validationResult.feedback);

    if (!validationResult.isValid) {
      return;
    }

    UserQuestion newQuestion = UserQuestion(
      userId: authProvider.userId!,
      questionText: questionText,
      timestamp: DateTime.now(),
      isValidated: true,
      coinTosserId: appStateProvider.selectedCoinTosser!.characterId,
      reportWriterId: appStateProvider.selectedReportWriter!.characterId,
    );

    DocumentReference? questionRef = await databaseService.saveUserQuestion(newQuestion);
    if (questionRef == null) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving your question. Please try again.')));
        return;
    }
    _currentQuestionId = questionRef.id;

    setState(() {
      _showSimulation = true;
    });
    appStateProvider.setCoinTossing(true);
  }

  void _handleSimulationComplete(int heads, int tails) async {
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    if (!mounted) return;
    appStateProvider.setTossResults(heads, tails);
    setState(() {
      _showSimulation = false;
    });

    if (_currentQuestionId == null || authProvider.userId == null) return;

    CoinTossResult tossResultData = CoinTossResult(
      questionId: _currentQuestionId!,
      headsCount: heads,
      tailsCount: tails,
      timestamp: DateTime.now(),
    );
    await databaseService.saveCoinTossResult(tossResultData, authProvider.userId!, _currentQuestionId!);

    if (!mounted) return;
    appStateProvider.setReportGenerating(true, statusMessage: "Generating your personalized report...");

    final userProfile = authProvider.userProfile;
    String sunSignInfo = "No horoscope data provided.";
    if (userProfile?.zodiacSign != null || userProfile?.birthDate != null) {
        final interpretation = appStateProvider.getSunSignInterpretation(
            userProfile?.zodiacSign,
            birthDate: userProfile?.birthDate
        );
        if (interpretation != null) {
            sunSignInfo = interpretation.generalInterpretationText;
        } else if (userProfile?.zodiacSign != null) {
            sunSignInfo = "General traits for ${userProfile!.zodiacSign}.";
        } else if (userProfile?.birthDate != null) {
            sunSignInfo = "General traits for sun sign determined by birth date.";
        }
    }

    List<UserQuestion> history = await databaseService.getUserQuestionHistory(authProvider.userId!);
    List<Map<String, dynamic>> historyForAI = history.take(3).map((q) => {
        'question': q.questionText,
    }).toList();

    String generatedReportText = await _aiService.generateAIReport(
      originalQuestion: _questionController.text.trim(),
      tossResults: {'Heads': heads, 'Tails': tails},
      sunSignInterpretation: sunSignInfo,
      userHistory: historyForAI,
    );

    AIReport newReport = AIReport(
        questionId: _currentQuestionId!,
        reportText: generatedReportText,
        generatedTimestamp: DateTime.now(),
        sunSignUsed: userProfile?.zodiacSign ?? (userProfile?.birthDate != null ? appStateProvider.getSunSignInterpretation(null, birthDate: userProfile!.birthDate)?.signName ?? "N/A" : "N/A"),
        status: ReportStatus.pendingReview
    );
    await databaseService.saveAIReport(newReport, authProvider.userId!, _currentQuestionId!);

    if (!mounted) return;
    appStateProvider.setReportGenerating(false, statusMessage: "Your report is pending review by our team.");
    _questionController.clear();
  }


  @override
  Widget build(BuildContext context) {
    final appStateProvider = Provider.of<AppStateProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coin Toss Advisor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).pushNamed(HistoryScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Your AI Companions:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                    Expanded(child: _buildCharacterSelector(context, appStateProvider, true)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildCharacterSelector(context, appStateProvider, false)),
                ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _questionController,
                      decoration: InputDecoration(
                        labelText: 'Enter your Yes/No question',
                        border: const OutlineInputBorder(),
                        suffixIcon: appStateProvider.isQuestionValidating ? const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width:20, height:20, child:CircularProgressIndicator(strokeWidth: 2))) : null,
                      ),
                      maxLines: 3,
                      enabled: !appStateProvider.isCoinTossing && !appStateProvider.isReportGenerating && !_showSimulation,
                    ),
                    if (appStateProvider.questionValidationFeedback != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        appStateProvider.questionValidationFeedback!,
                        style: TextStyle(color: appStateProvider.questionValidationFeedback!.contains("good") ? Colors.green.shade700 : Colors.red.shade700),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (appStateProvider.isCoinTossing || appStateProvider.isReportGenerating || _showSimulation) ? null : _submitQuestionAndStartFlow,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(appStateProvider.isCoinTossing || appStateProvider.isReportGenerating || _showSimulation ? 'Processing...' : 'Flip Coins & Get Insight'),
            ),
            const SizedBox(height: 20),
            if (_showSimulation)
              TossSimulationViewWithCanvas(
                onSimulationComplete: _handleSimulationComplete,
              ),
            if (!_showSimulation && appStateProvider.tossResults != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Final Toss Results:', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Heads: ${appStateProvider.tossResults!['Heads']}, Tails: ${appStateProvider.tossResults!['Tails']}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            if (appStateProvider.reportStatusMessage != null)
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    appStateProvider.reportStatusMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterSelector(BuildContext context, AppStateProvider appState, bool isTosser) {
    final characters = appState.availableCharacters.where((c) {
        return isTosser ? c.role == AIChatacterRole.coinTosser : c.role == AIChatacterRole.reportWriter;
    }).toList();
    
    if (characters.isEmpty) { // Fallback if no specific role characters are defined
        characters.addAll(appState.availableCharacters);
    }

    AICharacter? selectedChar = isTosser ? appState.selectedCoinTosser : appState.selectedReportWriter;

    if (selectedChar != null && !characters.any((c) => c.characterId == selectedChar!.characterId)) {
        selectedChar = characters.isNotEmpty ? characters.first : null;
    }
     if (selectedChar == null && characters.isNotEmpty) {
        selectedChar = characters.first;
         // Update provider with this default if it was null
        WidgetsBinding.instance.addPostFrameCallback((_){
            if(isTosser && appState.selectedCoinTosser == null) appState.selectCoinTosser(selectedChar);
            if(!isTosser && appState.selectedReportWriter == null) appState.selectReportWriter(selectedChar);
        });
    }


    return DropdownButtonFormField<AICharacter>(
      decoration: InputDecoration(
        labelText: isTosser ? 'Coin Tosser' : 'Report Writer',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15), // Adjusted padding
      ),
      value: selectedChar,
      isExpanded: true,
      items: characters.map((AICharacter char) {
        return DropdownMenuItem<AICharacter>(
          value: char,
          child: Row(children: [
            // Image.network(char.avatarUrl, width: 20, height: 20, errorBuilder: (c,o,s) => Icon(Icons.person, size: 20)), // If using network URLs
            // For local assets, ensure they are in pubspec.yaml and project structure
            Image.asset(char.avatarUrl, width: 24, height: 24, errorBuilder: (c,o,s) => const Icon(Icons.person_pin_circle_outlined, size: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text(char.name, overflow: TextOverflow.ellipsis)),
          ]),
        );
      }).toList(),
      onChanged: (AICharacter? newValue) {
        if (newValue != null) {
          if (isTosser) {
            appState.selectCoinTosser(newValue);
          } else {
            appState.selectReportWriter(newValue);
          }
        }
      },
    );
  }
}