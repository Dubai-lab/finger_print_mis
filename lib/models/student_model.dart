import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String? id;
  final String name;
  final String registrationNumber;
  final List<String>? recentlyAccessedClasses;
  final List<String>? joinedCourses;

  StudentModel({
    this.id,
    required this.name,
    required this.registrationNumber,
    this.recentlyAccessedClasses,
    this.joinedCourses,
  });

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentModel(
      id: doc.id,
      name: data['name'] ?? '',
      registrationNumber: data['registrationNumber'] ?? '',
      recentlyAccessedClasses: List<String>.from(data['recentlyAccessedClasses'] ?? []),
      joinedCourses: List<String>.from(data['joinedCourses'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'registrationNumber': registrationNumber,
      'recentlyAccessedClasses': recentlyAccessedClasses ?? [],
      'joinedCourses': joinedCourses ?? [],
    };
  }
}
