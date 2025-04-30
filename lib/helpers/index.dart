// lib/helpers/index.dart
// Updated helper functions for price handling

import 'package:flutter/cupertino.dart';

import '../constant/index.dart';

String cleanProductName(String name) {
  // Check if the name contains '$' and remove everything from '$' onwards
  final dollarIndex = name.indexOf('\$');

  if (dollarIndex != -1) {
    return name.substring(0, dollarIndex).trim();
  }

  return name;
}

int _parseToInt(dynamic value) {
  if (value == null) return 0;

  if (value is int) return value;
  if (value is double) return value.toInt();

  try {
    // Remove non-numeric characters
    return int.parse(value.toString().replaceAll(RegExp(r'[^0-9]'), ''));
  } catch (e) {
    debugPrint('Error parsing value: $e');
    return 0;
  }
}

// Function to extract and properly format product price
int extractPrice(dynamic rawPrice) {
  // If price is null or empty, return 0
  if (rawPrice == null || rawPrice.toString().isEmpty) {
    return 0;
  }

  // Parse to int
  int parsedPrice = _parseToInt(rawPrice);

  // IMPORTANT: Divide base product prices by 100
  return parsedPrice ~/ 100;
}

bool isGroupModification(Map<String, dynamic> json) {
  // Check for dish_modification_id (indicates group mod)
  if (json.containsKey('dish_modification_id')) return true;

  // Check if price is a number type (group mods have number prices)
  if (json.containsKey('price') && json['price'] is num) return true;

  return false;
}

// Function to extract and properly format modification price
int extractModificationPrice(dynamic rawPrice, bool isGroupModification) {
  // If price is null or empty, return 0
  if (rawPrice == null || rawPrice.toString().isEmpty) {
    return 0;
  }

  // Parse to int
  int parsedPrice = _parseToInt(rawPrice);

  // Debug log
  debugPrint(
    '📊 Modification price: $rawPrice (parsed: $parsedPrice, isGroup: $isGroupModification)',
  );

  // IMPORTANT CHANGE: Always divide all prices by 100, regardless of type
  return parsedPrice ~/ 100;
}

/**
 * Formats a price value for display
 *
 * @param dynamic price - The price value (can be int, double, or String)
 * @param bool subtract - Whether to divide the price by 100 (defaults to true)
 * @return String - The formatted price string
 */

String formatPrice(dynamic price, {bool subtract = true}) {
  // Handle null values
  if (price == null) {
    return '0 ${Constants.currencySymbol}';
  }

  // Parse to numeric value
  int numericPrice = _parseToInt(price);

  // Debug log
  debugPrint('💰 Formatting price: $price → $numericPrice, subtract: $subtract');

  // IMPORTANT CHANGE: If subtract is false, don't perform any division (prices are already divided)
  // If subtract is true (default), divide by 100 for backward compatibility
  final formattedValue = subtract ? numericPrice ~/ 100 : numericPrice;

  // Return formatted with currency
  return '${formattedValue.toString()} ${Constants.currencySymbol}';
}

// Get image URL from product
String getImageUrl(dynamic photoUrl, dynamic photoOriginUrl) {
  // First try to use photo_origin if available
  if (photoOriginUrl != null && photoOriginUrl.toString().isNotEmpty) {
    String url = photoOriginUrl.toString();
    if (!url.startsWith('http')) {
      return 'https://joinposter.com$url';
    }
    return url;
  }

  // Fallback to regular photo
  if (photoUrl != null && photoUrl.toString().isNotEmpty) {
    String url = photoUrl.toString();
    if (!url.startsWith('http')) {
      return 'https://joinposter.com$url';
    }
    return url;
  }

  // Fallback to default image
  return "assets/images/no_image.png";
}
