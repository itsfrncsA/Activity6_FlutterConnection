import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = userService.value;

  UserModel? _user;
  LoginType? _loginType;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  LoginType? get loginType => _loginType ?? _user?.loginType;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  UserProvider() {
    loadUserData();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadUserData() async {
    _setLoading(true);
    try {
      _user = await _userService.getUserData();
      _loginType = await _userService.getLoginType();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Firebase Sign In
  Future<bool> signInWithFirebase({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final credential = await _userService.signIn(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        _user = UserModel.fromFirebaseUser(credential.user!);
        _loginType = LoginType.firebase;
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _formatAuthError(e);
      _setLoading(false);
      return false;
    }
  }

  String _formatAuthError(dynamic e) {
    final str = e.toString();
    if (str.contains('configuration-not-found') || str.contains('CONFIGURATION_NOT_FOUND')) {
      return 'Firebase Authentication is not initialized. Please go to Firebase Console > Authentication > Get Started & enable Email/Password.';
    }
    if (str.contains('email-already-in-use')) {
      return 'This email is already registered. Please sign in instead.';
    }
    if (str.contains('weak-password')) {
      return 'The password is too weak. Please use at least 6 characters.';
    }
    if (str.contains('invalid-email')) {
      return 'The email address is invalid.';
    }
    if (str.contains('user-not-found') || str.contains('wrong-password') || str.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    return str;
  }

  // Firebase Sign Up
  Future<bool> signUpWithFirebase({
    required String email,
    required String password,
    required String username,
    String? firstName,
    String? lastName,
    int? age,
    String? contactNo,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final credential = await _userService.createAccount(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await credential.user!.updateDisplayName(username);
        final additional = {
          'firstName': firstName,
          'lastName': lastName,
          'age': age,
          'contactNo': contactNo,
          'username': username,
        };
        final userModel = UserModel.fromFirebaseUser(
          credential.user!,
          additionalData: additional,
        );
        await _userService.saveUserSession(userModel);
        _user = userModel;
        _loginType = LoginType.firebase;
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _formatAuthError(e);
      _setLoading(false);
      return false;
    }
  }

  // DummyJSON Sign In
  Future<bool> signInWithDummyJson({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await _userService.loginWithDummyJson(
        username: username,
        password: password,
      );
      _user = user;
      _loginType = LoginType.dummyJson;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // DummyJSON Sign Up
  Future<bool> signUpWithDummyJson({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    int? age,
    String? contactNo,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final userData = {
        'username': username,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'phone': contactNo,
      };
      final user = await _userService.registerDummyJsonUser(userData: userData);
      _user = user;
      _loginType = LoginType.dummyJson;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Update Username
  Future<bool> updateUsername(String username) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _userService.updateUsername(username: username);
      if (_user != null) {
        _user = _user!.copyWith(username: username);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Reset/Change Password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        email: email,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Delete Account
  Future<bool> deleteAccount({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _userService.deleteAccount(
        email: email,
        password: password,
      );
      _user = null;
      _loginType = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _userService.signOut();
      _user = null;
      _loginType = null;
    } finally {
      _setLoading(false);
    }
  }
}
