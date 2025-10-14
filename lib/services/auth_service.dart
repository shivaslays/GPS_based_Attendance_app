import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  String? _userType;
  String? _userName;
  bool _isLoading = false;

  User? get user => _user;
  String? get userType => _userType;
  String? get userName => _userName;
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
        await _loadUserData();
      } else {
        _userType = null;
        _userName = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _userType = prefs.getString('userType');
        _userName = prefs.getString('userName');
        
        if (_userType == null || _userName == null) {
          // Check Firestore for user data
          final doc = await _firestore.collection('users').doc(_user!.uid).get();
          if (doc.exists) {
            final data = doc.data()!;
            _userType = data['userType'];
            _userName = data['name'];
            
            // Save to preferences
            if (_userType != null) {
              await prefs.setString('userType', _userType!);
            }
            if (_userName != null) {
              await prefs.setString('userName', _userName!);
            }
          }
        }
      } catch (e) {
        print('Error loading user data: $e');
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
        
        // Load user data from Firestore to get the name
        await _loadUserData();
        
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
        // Store user type and name
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userType', userType);
        await prefs.setString('userName', name);
        _userType = userType;
        _userName = name;
        
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
      await prefs.remove('userName');
      await _auth.signOut();
      _userType = null;
      _userName = null;
    } catch (e) {
      print('Sign out error: $e');
    }
  }
}

