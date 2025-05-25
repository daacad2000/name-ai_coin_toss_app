import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_state_provider.dart';
import '../models/ai_character.dart';
// import 'main_screen.dart'; // Not needed directly, AuthGate handles it

class OnboardingScreen extends StatefulWidget {
  static const routeName = '/onboarding';

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _email = '';
  String _password = '';
  DateTime? _birthDate;
  String? _selectedZodiacSign;
  AICharacter? _selectedTosser;
  AICharacter? _selectedWriter;
  bool _isLoading = false;

  final List<String> _zodiacSigns = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
  ];

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _trySubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState?.save();
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String? error;

      if (_isLogin) {
        error = await authProvider.login(_email, _password);
      } else {
        error = await authProvider.signUp(
          _email,
          _password,
          birthDate: _birthDate,
          zodiacSign: _selectedZodiacSign,
          tosserId: _selectedTosser?.characterId,
          writerId: _selectedWriter?.characterId
        );
      }

      if (mounted) {
         setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? ''),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
            }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    // Initialize dropdown selections if null
    if (_selectedTosser == null && appState.availableCharacters.any((c) => c.role == AIChatacterRole.coinTosser)) {
        _selectedTosser = appState.availableCharacters.firstWhere((c) => c.role == AIChatacterRole.coinTosser, orElse: () => appState.availableCharacters.first);
    }
    if (_selectedWriter == null && appState.availableCharacters.any((c) => c.role == AIChatacterRole.reportWriter)) {
        _selectedWriter = appState.availableCharacters.firstWhere((c) => c.role == AIChatacterRole.reportWriter, orElse: () => appState.availableCharacters.first);
    }


    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  _isLogin ? 'Login' : 'Create Account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 30),
                TextFormField(
                  key: ValueKey('email_onboarding'),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                  onSaved: (value) => _email = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  key: ValueKey('password_onboarding'),
                  decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 7) {
                      return 'Password must be at least 7 characters long.';
                    }
                    return null;
                  },
                  onSaved: (value) => _password = value!,
                ),
                SizedBox(height: 20),
                if (!_isLogin) ...[
                  Text("Personalize your experience (Optional):", style: Theme.of(context).textTheme.titleSmall),
                  SizedBox(height: 10),
                  ListTile(
                    title: Text(_birthDate == null ? 'Select Birth Date' : 'Birth Date: ${_birthDate!.toLocal().toString().split(' ')[0]}'),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () => _selectBirthDate(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Or Select Zodiac Sign', border: OutlineInputBorder()),
                    value: _selectedZodiacSign,
                    items: _zodiacSigns.map((String sign) {
                      return DropdownMenuItem<String>(value: sign, child: Text(sign));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedZodiacSign = value),
                  ),
                  SizedBox(height: 20),
                  Text("Default Coin Tosser:", style: Theme.of(context).textTheme.titleSmall),
                  DropdownButtonFormField<AICharacter>(
                    decoration: InputDecoration(border: OutlineInputBorder()),
                    value: _selectedTosser,
                    items: appState.availableCharacters
                        .where((c) => c.role == AIChatacterRole.coinTosser || appState.availableCharacters.length <=2)
                        .map((AICharacter char) {
                      return DropdownMenuItem<AICharacter>(value: char, child: Text(char.name));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedTosser = value),
                  ),
                  SizedBox(height: 10),
                  Text("Default Report Writer:", style: Theme.of(context).textTheme.titleSmall),
                  DropdownButtonFormField<AICharacter>(
                     decoration: InputDecoration(border: OutlineInputBorder()),
                    value: _selectedWriter,
                    items: appState.availableCharacters
                        .where((c) => c.role == AIChatacterRole.reportWriter || appState.availableCharacters.length <=2)
                        .map((AICharacter char) {
                      return DropdownMenuItem<AICharacter>(value: char, child: Text(char.name));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedWriter = value),
                  ),
                  SizedBox(height: 24),
                ],
                if (_isLoading)
                  Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    child: Text(_isLogin ? 'Login' : 'Sign Up'),
                    onPressed: _trySubmit,
                  ),
                SizedBox(height: 12),
                TextButton(
                  child: Text(_isLogin ? 'Create new account' : 'I already have an account'),
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}