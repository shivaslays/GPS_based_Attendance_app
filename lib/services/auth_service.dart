import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  String? _userType;
  bool _isLoading = false;

  User? get user => _user;
  String? get userType => _userType;
  bool get isLoading => _isLoading;

  AuthService() {
    _init();
  }

  void _init() async {
    _isLoading = true;
    notifyListeners();
    
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _loadUserType();
      } else {
        _userType = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _loadUserType() async {
    if (_user != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _userType = prefs.getString('userType');
        
        if (_userType == null) {
          // Check Firestore for user type
          final doc = await _firestore.collection('users').doc(_user!.uid).get();
          if (doc.exists) {
            _userType = doc.data()?['userType'];
            await prefs.setString('userType', _userType!);
          }
        }
      } catch (e) {
        print('Error loading user type: $e');
      }
    }
  }

  Future<bool> signIn(String email, String password, String userType) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Store user type
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userType', userType);
        _userType = userType;
        
        // Save to Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'userType': userType,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        return true;
      }
      return false;
    } catch (e) {
      print('Sign in error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password, String userType, String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Store user type
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userType', userType);
        _userType = userType;
        
        // Save to Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'userType': userType,
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        return true;
      }
      return false;
    } catch (e) {
      print('Sign up error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userType');
      await _auth.signOut();
      _userType = null;
    } catch (e) {
      print('Sign out error: $e');
    }
  }
}
