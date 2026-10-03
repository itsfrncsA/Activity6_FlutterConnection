import 'package:firebase_auth/firebase_auth.dart';

enum LoginType {
  firebase,
  dummyJson,
}

class UserModel {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final int? age;
  final String? gender;
  final String? image;
  final String? contactNo;
  final String? token;
  final String? refreshToken;
  final LoginType loginType;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.age,
    this.gender,
    this.image,
    this.contactNo,
    this.token,
    this.refreshToken,
    this.loginType = LoginType.dummyJson,
  });

  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;
    if (username.isNotEmpty) return username;
    return email.split('@').first;
  }

  factory UserModel.fromDummyJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? ''),
      gender: json['gender'],
      image: json['image'],
      contactNo: json['phone'] ?? json['contactNo'],
      token: json['accessToken'] ?? json['token'],
      refreshToken: json['refreshToken'],
      loginType: LoginType.dummyJson,
    );
  }

  factory UserModel.fromFirebaseUser(User user, {Map<String, dynamic>? additionalData}) {
    String? fName;
    String? lName;
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      final parts = user.displayName!.split(' ');
      fName = parts.first;
      if (parts.length > 1) {
        lName = parts.sublist(1).join(' ');
      }
    }

    return UserModel(
      id: user.uid,
      username: user.displayName ?? (user.email?.split('@').first ?? 'User'),
      email: user.email ?? '',
      firstName: additionalData?['firstName'] ?? fName,
      lastName: additionalData?['lastName'] ?? lName,
      age: additionalData?['age'] is int ? additionalData!['age'] : int.tryParse(additionalData?['age']?.toString() ?? ''),
      gender: additionalData?['gender'],
      image: user.photoURL ?? additionalData?['image'],
      contactNo: user.phoneNumber ?? additionalData?['contactNo'] ?? additionalData?['phone'],
      token: null,
      loginType: LoginType.firebase,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final loginTypeStr = json['loginType']?.toString();
    final type = loginTypeStr == LoginType.firebase.name
        ? LoginType.firebase
        : LoginType.dummyJson;

    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? ''),
      gender: json['gender'],
      image: json['image'],
      contactNo: json['contactNo'] ?? json['phone'],
      token: json['token'],
      refreshToken: json['refreshToken'],
      loginType: type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'gender': gender,
      'image': image,
      'contactNo': contactNo,
      'token': token,
      'refreshToken': refreshToken,
      'loginType': loginType.name,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    int? age,
    String? gender,
    String? image,
    String? contactNo,
    String? token,
    String? refreshToken,
    LoginType? loginType,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      image: image ?? this.image,
      contactNo: contactNo ?? this.contactNo,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      loginType: loginType ?? this.loginType,
    );
  }
}
