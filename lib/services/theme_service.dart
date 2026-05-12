import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static ThemeMode _themeMode = ThemeMode.light;

  static ThemeMode get themeMode => _themeMode;
  static bool get isDarkMode => isDarkForMode(_themeMode);
  static bool get isLightMode => !isDarkMode;
  static Brightness get platformBrightness =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  static Future<void> setThemeMode(ThemeMode mode) async {
    final normalizedMode = _normalize(mode);
    _themeMode = normalizedMode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, normalizedMode.name);

    if (!_isFirebaseInitialized()) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'themeMode': normalizedMode.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving theme to Firebase: $e');
    }
  }

  static Future<void> loadTheme() async {
    _themeMode = ThemeMode.light;

    final prefs = await SharedPreferences.getInstance();
    final localTheme = prefs.getString(_themeKey);
    if (localTheme != null) {
      _themeMode = _parseTheme(localTheme);
      return;
    }

    if (!_isFirebaseInitialized()) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final remoteTheme = doc.data()?['themeMode'] as String?;
      if (remoteTheme != null) {
        _themeMode = _parseTheme(remoteTheme);
        await prefs.setString(_themeKey, _themeMode.name);
      }
    } catch (e) {
      debugPrint('Error loading theme from Firebase: $e');
    }
  }

  static Future<void> toggleTheme() async {
    await setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  static ThemeMode _parseTheme(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  static ThemeMode _normalize(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return ThemeMode.dark;
      case ThemeMode.system:
        return ThemeMode.system;
      case ThemeMode.light:
        return ThemeMode.light;
    }
  }

  static bool isDarkForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return platformBrightness == Brightness.dark;
      case ThemeMode.light:
        return false;
    }
  }

  static bool _isFirebaseInitialized() {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }
}
