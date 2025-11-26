import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1.0; // 1.0 = normal

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setFontScale(double scale) {
    _fontScale = scale.clamp(0.8, 1.4);
    notifyListeners();
  }
}
