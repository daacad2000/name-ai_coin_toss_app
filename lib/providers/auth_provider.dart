import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Aliased
import '../models/user_profile.dart';
import '../services/database_service.dart'; // To save/fetch user profile from Firestore

class AuthProvider with ChangeNotifier {
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final DatabaseService _databaseService; // For user profile operations

  UserProfile? _userProfile;
  fb_auth.User? _firebaseUser; // Firebase User object

  AuthProvider(this._databaseService) {
    // Listen to auth state changes
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  UserProfile? get userProfile => _userProfile;
  bool get isAuthenticated => _firebaseUser != null && _userProfile != null;
  String? get userId => _firebaseUser?.uid;


  Future<void> _onAuthStateChanged(fb_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      _firebaseUser = null;
      _userProfile = null;
    } else {
      _firebaseUser = firebaseUser;
      // Fetch or create user profile from Firestore
      _userProfile = await _databaseService.getUserProfile(firebaseUser.uid);
      if (_userProfile == null && firebaseUser.email != null) {
        // If new user (e.g. after social sign in or if profile creation failed before)
        // Create a basic profile. Onboarding should ideally handle full profile creation.
        print("Creating new user profile for UID: ${firebaseUser.uid}");
        _userProfile = UserProfile(userId: firebaseUser.uid, email: firebaseUser.email);
        await _databaseService.saveUserProfile(_userProfile!);
      }
    }
    notifyListeners();
  }

  Future<String?> signUp(String email, String password, {DateTime? birthDate, String? zodiacSign, String? tosserId, String? writerId}) async {
    try {
      fb_auth.UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _firebaseUser = userCredential.user;
      if (_firebaseUser != null) {
        // Create and save user profile to Firestore
        _userProfile = UserProfile(
          userId: _firebaseUser!.uid,
          email: email,
          birthDate: birthDate,
          zodiacSign: zodiacSign,
          defaultCoinTosserId: tosserId,
          defaultReportWriterId: writerId
        );
        await _databaseService.saveUserProfile(_userProfile!);
        notifyListeners();
        return null; // Success
      }
      return "User creation failed.";
    } on fb_auth.FirebaseAuthException catch (e) {
      return e.message; // Return error message
    } catch (e) {
      return "An unknown error occurred.";
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Auth state listener will handle fetching profile
      return null; // Success
    } on fb_auth.FirebaseAuthException catch (e) {
      return e.message; // Return error message
    } catch (e) {
      return "An unknown error occurred.";
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    // Auth state listener will set _userProfile to null and notify
  }

  Future<void> updateUserProfileDetails({DateTime? birthDate, String? zodiacSign, String? tosserId, String? writerId}) async {
    if (_userProfile != null) {
      bool changed = false;
      if (birthDate != null) {
        _userProfile!.birthDate = birthDate;
        changed = true;
      }
      if (zodiacSign != null && zodiacSign.isNotEmpty) {
         _userProfile!.zodiacSign = zodiacSign;
         changed = true;
      }
      if (tosserId != null) {
        _userProfile!.defaultCoinTosserId = tosserId;
        changed = true;
      }
      if (writerId != null) {
        _userProfile!.defaultReportWriterId = writerId;
        changed = true;
      }

      if (changed) {
        await _databaseService.updateUserProfile(_userProfile!);
        notifyListeners();
      }
    }
  }
}