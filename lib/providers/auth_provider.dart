// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initialize();
  }

void _initialize() async {
  // Check for existing session
  final session = _authService.currentSession;
  if (session != null) {
    _user = session.user;
    await loadProfile();
    notifyListeners();
  }
  
  // Listen to auth state changes
  _authService.authStateChanges.listen((AuthState state) {
    _user = state.session?.user;
    notifyListeners();
    
    if (_user != null) {
      loadProfile();
    } else {
      _profile = null;
    }
  });
}

  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.signUp(
        email: email,
        password: password,
        username: username,
      );

      _user = response.user;
      _isLoading = false;
      notifyListeners();

      if (_user != null) {
        await loadProfile();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      _user = response.user;
      _isLoading = false;
      notifyListeners();

      if (_user != null) {
        await loadProfile();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatErrorMessage(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _authService.signInWithGoogle();
      
      _isLoading = false;
      notifyListeners();

      if (success && _user != null) {
        await loadProfile();
      }
      
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      
      _user = null;
      _profile = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    try {
      _profile = await _authService.getUserProfile();
      notifyListeners();
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  Future<bool> updateProfile({
    String? username,
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.updateProfile(
        username: username,
        fullName: fullName,
        avatarUrl: avatarUrl,
      );

      await loadProfile();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.resetPassword(email);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _formatErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (error.contains('Email not confirmed')) {
      return 'Please verify your email before signing in';
    } else if (error.contains('User already registered')) {
      return 'This email is already registered';
    }
    return error;
  }
}