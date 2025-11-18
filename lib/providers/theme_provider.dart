import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeOption { light, dark, system }

class ThemeProvider with ChangeNotifier {
  ThemeOption _themeOption = ThemeOption.system;
  
  ThemeOption get themeOption => _themeOption;
  
  ThemeMode get themeMode {
    switch (_themeOption) {
      case ThemeOption.light:
        return ThemeMode.light;
      case ThemeOption.dark:
        return ThemeMode.dark;
      case ThemeOption.system:
        return ThemeMode.system;
    }
  }
  
  ThemeProvider() {
    _loadThemePreference();
  }
  
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme_option') ?? 'system';
    
    switch (themeString) {
      case 'light':
        _themeOption = ThemeOption.light;
        break;
      case 'dark':
        _themeOption = ThemeOption.dark;
        break;
      default:
        _themeOption = ThemeOption.system;
    }
    notifyListeners();
  }
  
  Future<void> setThemeOption(ThemeOption option) async {
    _themeOption = option;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_option', option.name);
  }
}
