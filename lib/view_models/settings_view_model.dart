import 'package:shared_preferences/shared_preferences.dart';
import 'package:ajedrez_app/utils/avatar_utils.dart';
import 'package:ajedrez_app/utils/board_styles.dart';
import 'package:ajedrez_app/utils/themes.dart';
import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  // Preference Keys
  static const String _themePreferenceKey = 'theme_preference';
  static const String _boardStylePreferenceKey = 'board_style_preference';
  static const String _userNamePreferenceKey = 'user_name_preference';
  static const String _avatarImageUrlPreferenceKey = 'avatar_image_url_preference';
  static const String _soundEnabledPreferenceKey = 'sound_enabled_preference';

  // Current Theme
  ThemeData _currentTheme = lightTheme; // Default to light theme
  ThemeData get currentTheme => _currentTheme;

  // Current Board Style
  BoardStyle _currentBoardStyle = classicBoardStyle; // Default to classic board style
  BoardStyle get currentBoardStyle => _currentBoardStyle;

  // Profile Information
  String _userName = 'Player'; // Default name
  String get userName => _userName;

  String _avatarImageUrl = predefinedAvatarUrls.first; // Default to the first predefined avatar
  String get avatarImageUrl => _avatarImageUrl;

  // Sound Settings
  bool _isSoundEnabled = true; // Default to sounds enabled
  bool get isSoundEnabled => _isSoundEnabled;

  SettingsViewModel() {
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Theme
      final themePreference = prefs.getString(_themePreferenceKey);
      if (themePreference == 'dark') {
        _currentTheme = darkTheme;
      } else {
        _currentTheme = lightTheme;
      }

      // Load Board Style
      final boardStylePreference = prefs.getString(_boardStylePreferenceKey);
      if (boardStylePreference != null) {
        _currentBoardStyle = getBoardStyleByName(boardStylePreference);
      } else {
        _currentBoardStyle = classicBoardStyle; // Default if nothing is stored
      }

      // Load Profile Information
      _userName = prefs.getString(_userNamePreferenceKey) ?? 'Player';
      
      final String? savedAvatarUrl = prefs.getString(_avatarImageUrlPreferenceKey);
      if (savedAvatarUrl != null && predefinedAvatarUrls.contains(savedAvatarUrl)) {
        _avatarImageUrl = savedAvatarUrl;
      } else {
        _avatarImageUrl = predefinedAvatarUrls.first; // Default if not found or invalid
      }

      // Load Sound Settings
      _isSoundEnabled = prefs.getBool(_soundEnabledPreferenceKey) ?? true; // Default to true

    } catch (e) {
      // If there's an error, default values
      _currentTheme = lightTheme;
      _currentBoardStyle = classicBoardStyle;
      _userName = 'Player';
      _avatarImageUrl = predefinedAvatarUrls.first; // Default avatar on error
      _isSoundEnabled = true; // Default sound to true on error
      print('Error loading preferences: $e');
    }
    notifyListeners();
  }

  Future<void> setTheme(ThemeData theme) async {
    if (theme == darkTheme) {
      _currentTheme = darkTheme;
      await _saveStringPreference(_themePreferenceKey, 'dark');
    } else {
      _currentTheme = lightTheme;
      await _saveStringPreference(_themePreferenceKey, 'light');
    }
    notifyListeners();
  }

  Future<void> setBoardStyle(BoardStyle style) async {
    _currentBoardStyle = style;
    await _saveStringPreference(_boardStylePreferenceKey, style.name);
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    await _saveStringPreference(_userNamePreferenceKey, name);
    notifyListeners();
  }

  Future<void> setAvatarImageUrl(String url) async {
    if (predefinedAvatarUrls.contains(url)) {
      _avatarImageUrl = url;
    } else {
      // If an invalid URL is somehow passed, default to the first predefined one
      // This could also log an error in a real application.
      _avatarImageUrl = predefinedAvatarUrls.first;
    }
    await _saveStringPreference(_avatarImageUrlPreferenceKey, _avatarImageUrl);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _isSoundEnabled = value;
    await _saveBoolPreference(_soundEnabledPreferenceKey, value);
    notifyListeners();
  }

  Future<void> _saveStringPreference(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      print('Error saving string preference for key $key: $e');
    }
  }

  Future<void> _saveBoolPreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      print('Error saving bool preference for key $key: $e');
    }
  }
}
