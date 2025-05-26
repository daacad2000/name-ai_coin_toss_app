import 'package:flutter/foundation.dart';
import '../models/ai_character.dart';
import '../models/sun_sign_interpretation.dart';
import '../services/database_service.dart'; // To load sun signs

class AppStateProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService(); // Or get from Provider

  final List<AICharacter> _availableCharacters = [
    AICharacter(characterId: 'char1', name: 'Oracle Luna', avatarUrl: 'assets/images/oracle_luna.png', description: 'Wise and insightful.', role: AIChatacterRole.reportWriter, voiceTone: "calm"),
    AICharacter(characterId: 'char2', name: 'Flip Quantum', avatarUrl: 'assets/images/flip_quantum.png', description: 'Energetic coin tosser.', role: AIChatacterRole.coinTosser),
    AICharacter(characterId: 'char3', name: 'Analyst Prime', avatarUrl: 'assets/images/analyst_prime.png', description: 'Detailed reports.', role: AIChatacterRole.reportWriter, voiceTone: "analytical"),
  ]; // Ensure these assets exist or use network URLs

  AICharacter? _selectedCoinTosser;
  AICharacter? _selectedReportWriter;

  List<SunSignInterpretation> _sunSignInterpretations = [];
  bool _sunSignsLoaded = false;

  // App states for UI
  bool _isQuestionValidating = false;
  String? _questionValidationFeedback;
  bool _isCoinTossing = false;
  Map<String, int>? _tossResults; // {'Heads': X, 'Tails': Y}
  bool _isReportGenerating = false;
  String? _reportStatusMessage; // e.g. "Pending Review", "Approved"


  AppStateProvider() {
    // Initialize default characters if desired (e.g., first in list)
    if (_availableCharacters.isNotEmpty) {
        _selectedCoinTosser = _availableCharacters.firstWhere((c) => c.role == AIChatacterRole.coinTosser, orElse: () => _availableCharacters.first);
        _selectedReportWriter = _availableCharacters.firstWhere((c) => c.role == AIChatacterRole.reportWriter, orElse: () => _availableCharacters.first);
    }
    _loadSunSignInterpretations();
  }

  List<AICharacter> get availableCharacters => _availableCharacters;
  AICharacter? get selectedCoinTosser => _selectedCoinTosser;
  AICharacter? get selectedReportWriter => _selectedReportWriter;
  List<SunSignInterpretation> get sunSignInterpretations => _sunSignInterpretations;
  bool get sunSignsLoaded => _sunSignsLoaded;

  bool get isQuestionValidating => _isQuestionValidating;
  String? get questionValidationFeedback => _questionValidationFeedback;
  bool get isCoinTossing => _isCoinTossing;
  Map<String, int>? get tossResults => _tossResults;
  bool get isReportGenerating => _isReportGenerating;
  String? get reportStatusMessage => _reportStatusMessage;


  void selectCoinTosser(AICharacter? character) {
    _selectedCoinTosser = character;
    notifyListeners();
  }

  void selectReportWriter(AICharacter? character) {
    _selectedReportWriter = character;
    notifyListeners();
  }

  Future<void> _loadSunSignInterpretations() async {
    _sunSignInterpretations = await _databaseService.getSunSignInterpretations();
    _sunSignsLoaded = true;
    notifyListeners();
    // This data should be pre-loaded into your Firestore 'SunSignInterpretations' collection
  }

  SunSignInterpretation? getSunSignInterpretation(String? birthDateOrSignName, {DateTime? birthDate}) {
    if (!_sunSignsLoaded || sunSignInterpretations.isEmpty) return null;
    if (birthDateOrSignName == null && birthDate == null) return null;

    String targetSignName = birthDateOrSignName ?? "";
    if (birthDate != null) {
        targetSignName = _determineSunSignFromDate(birthDate);
    }

    try {
      return _sunSignInterpretations.firstWhere(
        (interp) => interp.signName.toLowerCase() == targetSignName.toLowerCase() || interp.signId.toLowerCase() == targetSignName.toLowerCase()
      );
    } catch (e) {
      print("Sun sign not found: $targetSignName");
      return null;
    }
  }

  String _determineSunSignFromDate(DateTime date) {
    // Simplified logic - for production, use a reliable astrology library
    int day = date.day;
    int month = date.month;
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "Aries";
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "Taurus";
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return "Gemini";
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return "Cancer";
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "Leo";
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return "Virgo";
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return "Libra";
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return "Scorpio";
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return "Sagittarius";
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return "Capricorn";
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "Aquarius";
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return "Pisces";
    return ""; // Should not happen
  }

  // --- Methods to manage app states ---
  void setQuestionValidating(bool validating, {String? feedback}) {
    _isQuestionValidating = validating;
    _questionValidationFeedback = feedback;
    notifyListeners();
  }

  void setCoinTossing(bool tossing) {
    _isCoinTossing = tossing;
    if (!tossing) _tossResults = null; // Clear results when starting new toss
    notifyListeners();
  }

  void setTossResults(int heads, int tails) {
    _tossResults = {'Heads': heads, 'Tails': tails};
    _isCoinTossing = false; // Toss is complete
    notifyListeners();
  }

  void setReportGenerating(bool generating, {String? statusMessage}) {
    _isReportGenerating = generating;
    _reportStatusMessage = statusMessage;
    notifyListeners();
  }

  void resetQuestionFlowStates() {
    _isQuestionValidating = false;
    _questionValidationFeedback = null;
    _isCoinTossing = false;
    _tossResults = null;
    _isReportGenerating = false;
    _reportStatusMessage = null;
    notifyListeners();
  }
}