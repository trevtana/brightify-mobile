import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initAuthListener();
    _checkCurrentUser();
  }

  /// Check if user is already logged in (persistence)
  void _checkCurrentUser() {
    final currentUser = _firebaseService.currentUser;
    if (currentUser != null) {
      debugPrint('🔐 AuthProvider: Found existing user: ${currentUser.email}');
      _user = currentUser;
      _loadUserData();
      notifyListeners();
    } else {
      debugPrint('🔐 AuthProvider: No existing user found');
    }
  }

  /// Initialize auth state listener
  void _initAuthListener() {
    _firebaseService.authStateChanges.listen((User? user) {
      debugPrint('🔐 AuthProvider: Auth state changed - User: ${user?.email ?? "null"}');
      _user = user;
      if (user != null) {
        _loadUserData();
      } else {
        _userData = null;
      }
      notifyListeners();
    });
  }

  /// Manually set user (for auth wrapper)
  void setUser(User user) {
    _user = user;
    _loadUserData();
    notifyListeners();
  }

  /// Load user data from Firestore
  Future<void> _loadUserData() async {
    if (_user == null) return;
    
    try {
      _userData = await _firebaseService.getUserData(_user!.uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  /// Register with email and password
  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await _firebaseService.registerWithEmailPassword(
        email: email,
        password: password,
        name: name,
      );

      if (credential != null) {
        _user = credential.user;
        await _loadUserData();
        _setLoading(false);
        return true;
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await _firebaseService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      if (credential != null) {
        _user = credential.user;
        await _loadUserData();
        _setLoading(false);
        return true;
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await _firebaseService.signInWithGoogle();

      if (credential != null) {
        _user = credential.user;
        await _loadUserData();
        _setLoading(false);
        return true;
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _firebaseService.signOut();
      _user = null;
      _userData = null;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _firebaseService.resetPassword(email);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Reload user data
  Future<void> reloadUser() async {
    await _user?.reload();
    _user = _firebaseService.currentUser;
    await _loadUserData();
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
