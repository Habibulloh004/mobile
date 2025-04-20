import 'package:flutter/material.dart';
import '../constant/index.dart';

// Utility class to convert hex colors to Flutter Colors
class ColorUtils {
  // Convert hex color string to Flutter Color
  static Color hexToColor(String hexString) {
    final hexCode = hexString.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  // Get app colors from constants
  static Color get primaryColor => hexToColor(Constants.primaryColor);
  static Color get secondaryColor => hexToColor(Constants.secondaryColor);
  static Color get accentColor => hexToColor(Constants.accentColor);
  static Color get bodyColor => hexToColor(Constants.bodyColor);
  static Color get buttonColor => hexToColor(Constants.buttonColor);
  static Color get errorColor => hexToColor(Constants.errorColor);
}