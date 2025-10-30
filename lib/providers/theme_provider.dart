// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'en';
  bool _autoSave = true;
  int _autoSaveInterval = 30; // seconds

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get autoSave => _autoSave;
  int get autoSaveInterval => _autoSaveInterval;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('isDarkMode') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _language = prefs.getString('language') ?? 'en';
      _autoSave = prefs.getBool('autoSave') ?? true;
      _autoSaveInterval = prefs.getInt('autoSaveInterval') ?? 30;
      notifyListeners();
    } catch (e) {
      print('Error loading theme preferences: $e');
    }
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', lang);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  Future<void> setAutoSave(bool value) async {
    _autoSave = value;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autoSave', value);
    } catch (e) {
      print('Error saving auto-save preference: $e');
    }
  }

  Future<void> setAutoSaveInterval(int seconds) async {
    _autoSaveInterval = seconds;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('autoSaveInterval', seconds);
    } catch (e) {
      print('Error saving auto-save interval: $e');
    }
  }
}