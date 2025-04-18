import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/firebase/auth_services.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthServices _authServices = AuthServices();

  User? _firebaseUser;
  User? get firebaseUser => _firebaseUser;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _firebaseUser != null && _userModel != null;

  Future<bool> login(String email, String password) async {
    try {
      _errorMessage = null;
      User? user = await _authServices.signInWithEmailAndPassword(email, password);
      if (user != null) {
        _firebaseUser = user;
        // Fetch user model from Firestore
        _userModel = await _authServices.getUserData(user.uid, email: user.email);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Authentication failed.';
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authServices.signOut();
    _firebaseUser = null;
    _userModel = null;
    notifyListeners();
  }
}
