class Constants {
  // User identification
  static const int userId = 1;

  // App theme colors
  static const String primaryColor = "#D5E2FD";  // Light blue
  static const String secondaryColor = "#3E3E3E"; // Dark gray
  static const String accentColor = "#5F93FE";    // Bright blue
  static const String bodyColor = "#FFFFFF";      // White
  static const String buttonColor = "#3E3E3E";    // Dark gray for buttons
  static const String errorColor = "#FF5252";     // Error red

  // Font sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeRegular = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 24.0;

  // API base URL
  static const String apiBaseUrl = "http://172.20.10.9:8080/api";
  static const String defaultApiToken = "";

  // Other app constants
  static const String appName = "Foodery";
  static const String appVersion = "1.0.0";
  static const bool isDevelopment = true;

  // Currency formatting
  static const String currencySymbol = "сум";
}

// Helper class to convert HEX colors to Flutter Colors
class AppColors {
  static int getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }
}