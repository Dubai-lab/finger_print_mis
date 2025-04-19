import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String role;
  final Timestamp createdAt;

  UserModel({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '\$firstName \$middleName \$lastName'.replaceAll(r'\$', '');
    }
    return '\$firstName \$lastName'.replaceAll(r'\$', '');
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      firstName: map['firstName'] ?? '',
      middleName: map['middleName'],
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'createdAt': createdAt,
    };
  }
}
