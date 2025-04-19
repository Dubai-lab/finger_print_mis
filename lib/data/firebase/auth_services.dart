import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AuthServices {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<UserModel?> getUserData(String uid, {String? email}) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else if (email != null) {
        // Try querying by email if doc by uid not found
        QuerySnapshot query = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          var doc = query.docs.first;
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }
      // If not found in 'users', try 'student' collection
      DocumentSnapshot studentDoc = await _firestore.collection('students').doc(uid).get();
      if (studentDoc.exists) {
        return UserModel.fromMap(studentDoc.data() as Map<String, dynamic>, studentDoc.id);
      } else if (email != null) {
        QuerySnapshot studentQuery = await _firestore
            .collection('students')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (studentQuery.docs.isNotEmpty) {
          var doc = studentQuery.docs.first;
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }
      // If not found in 'students', try 'instructors' collection
      DocumentSnapshot instructorDoc = await _firestore.collection('instructors').doc(uid).get();
      if (instructorDoc.exists) {
        return UserModel.fromMap(instructorDoc.data() as Map<String, dynamic>, instructorDoc.id);
      } else if (email != null) {
        QuerySnapshot instructorQuery = await _firestore
            .collection('instructors')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (instructorQuery.docs.isNotEmpty) {
          var doc = instructorQuery.docs.first;
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserModel>> getInstructors() async {
    try {
      QuerySnapshot query = await _firestore.collection('users').get();
      List<UserModel> allUsers = query.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      List<UserModel> instructors = allUsers.where((user) {
        String role = user.role.toLowerCase().trim();
        return role.contains('instructor');
      }).toList();
      print('Filtered \${instructors.length} instructors from \${allUsers.length} users');
      return instructors;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
