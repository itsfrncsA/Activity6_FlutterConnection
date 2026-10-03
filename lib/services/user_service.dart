import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<void> _syncToFirestoreUsers(UserModel user) async {
    try {
      if (user.id.isNotEmpty) {
        await _firestore.collection('Users').doc(user.id).set({
          'uid': user.id,
          'email': user.email,
          'username': user.username,
          'firstName': user.firstName ?? user.username,
          'lastName': user.lastName ?? '',
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error syncing user to Firestore Users collection: $e');
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final userCredential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user != null) {
      final userModel = UserModel.fromFirebaseUser(userCredential.user!);
      await saveUserSession(userModel);
      await _syncToFirestoreUsers(userModel);
    }

    return userCredential;
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user != null) {
      final userModel = UserModel.fromFirebaseUser(userCredential.user!);
      await saveUserSession(userModel);
      await _syncToFirestoreUsers(userModel);
    }

    return userCredential;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
    await clearSession();
  }

  Future<void> updateUsername({required String username}) async {
    if (currentUser != null) {
      await currentUser!.updateDisplayName(username);
      final currentData = await getUserData();
      if (currentData != null) {
        final updated = currentData.copyWith(username: username);
        await saveUserSession(updated);
      }
    } else {
      final currentData = await getUserData();
      if (currentData != null) {
        final updated = currentData.copyWith(username: username);
        await saveUserSession(updated);
      }
    }
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final loginType = await getLoginType();
    if (loginType == LoginType.firebase && currentUser != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.delete();
      await firebaseAuth.signOut();
    }
    await clearSession();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final loginType = await getLoginType();
    if (loginType == LoginType.firebase && currentUser != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.updatePassword(newPassword);
    } else {
      // For DummyJSON or local session, update locally stored data
      final currentData = await getUserData();
      if (currentData != null) {
        await saveUserSession(currentData);
      }
    }
  }

  // DummyJSON Authentication API
  Future<UserModel> loginWithDummyJson({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(AppConstants.dummyJsonLoginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final userModel = UserModel.fromDummyJson(data);
      await saveUserSession(userModel);
      return userModel;
    } else {
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'DummyJSON Login failed');
    }
  }

  // DummyJSON Registration API
  Future<UserModel> registerDummyJsonUser({
    required Map<String, dynamic> userData,
  }) async {
    final response = await http.post(
      Uri.parse(AppConstants.dummyJsonAddUserUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final userModel = UserModel(
        id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        username: data['username'] ?? userData['username'] ?? '',
        email: data['email'] ?? userData['email'] ?? '',
        firstName: data['firstName'] ?? userData['firstName'],
        lastName: data['lastName'] ?? userData['lastName'],
        age: data['age'] is int ? data['age'] : int.tryParse(data['age']?.toString() ?? ''),
        gender: data['gender'] ?? userData['gender'],
        contactNo: data['phone'] ?? userData['contactNo'],
        token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        loginType: LoginType.dummyJson,
      );
      await saveUserSession(userModel);
      return userModel;
    } else {
      throw Exception('Failed to register user to DummyJSON');
    }
  }

  // Save session to SharedPreferences
  Future<void> saveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await prefs.setString(AppConstants.keyLoginType, user.loginType.name);
    if (user.token != null) {
      await prefs.setString(AppConstants.keyToken, user.token!);
    }
    if (user.refreshToken != null) {
      await prefs.setString(AppConstants.keyRefreshToken, user.refreshToken!);
    }
    await prefs.setString(AppConstants.keyUserData, jsonEncode(user.toJson()));
  }

  // Fetch unified UserData
  Future<UserModel?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(AppConstants.keyUserData);

    if (currentUser != null) {
      Map<String, dynamic>? additional;
      if (jsonStr != null) {
        try {
          additional = jsonDecode(jsonStr);
        } catch (_) {}
      }
      return UserModel.fromFirebaseUser(currentUser!, additionalData: additional);
    }

    if (jsonStr != null) {
      try {
        final map = jsonDecode(jsonStr);
        return UserModel.fromJson(map);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Get active LoginType
  Future<LoginType?> getLoginType() async {
    if (currentUser != null) {
      return LoginType.firebase;
    }
    final prefs = await SharedPreferences.getInstance();
    final typeStr = prefs.getString(AppConstants.keyLoginType);
    if (typeStr == LoginType.firebase.name) return LoginType.firebase;
    if (typeStr == LoginType.dummyJson.name) return LoginType.dummyJson;
    return null;
  }

  // Check login status
  Future<bool> isLoggedIn() async {
    if (currentUser != null) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  // Clear session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyIsLoggedIn);
    await prefs.remove(AppConstants.keyLoginType);
    await prefs.remove(AppConstants.keyToken);
    await prefs.remove(AppConstants.keyRefreshToken);
    await prefs.remove(AppConstants.keyUserData);
  }
}
