import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String _username = '';

  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;

  // Simulate an async login (this must be async)
  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 250)); // simulate network
    if (username == 'a' && password == 'a') {
      _isLoggedIn = true;
      _username = username;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isLoggedIn = false;
    _username = '';
    notifyListeners();
  }
}
