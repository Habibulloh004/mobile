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
  return parsedPrice;
}

bool isGroupModification(Map<String, dynamic> json) {
  // Check for dish_modification_id (indicates group mod)
  if (json.containsKey('dish_modification_id')) return true;

  // Check if price is a number type (group mods have number prices)
  if (json.containsKey('price') && json['price'] is num) return true;

  return false;
}

// Format price from API (in cents/minor units) to readable format
String formatPrice(
  num price, {
  String type = 'space',
  bool showCurrency = true,
  bool subtract = true,
}) {
  // Step 1: Divide the price by 100 for better display
  double formattedPrice = subtract ? price / 100 : price.toDouble();

  // Step 2: Format the number with 0 decimal places if it's a whole number, otherwise 2 decimal places
  String priceString =
      formattedPrice % 1 == 0
          ? formattedPrice.toInt().toString()
          : formattedPrice.toStringAsFixed(2);

  // Step 3: Split into integer and decimal parts
  List<String> parts = priceString.split('.');
  String integerPart = parts[0];
  String decimalPart = parts.length > 1 ? parts[1] : "";

  // Step 4: Add thousand separators to the integer part
  String separator = type == 'space' ? ' ' : ',';
  String formattedInteger = '';
  for (int i = 0; i < integerPart.length; i++) {
    if (i > 0 && (integerPart.length - i) % 3 == 0) {
      formattedInteger += separator;
    }
    formattedInteger += integerPart[i];
  }

  // Step 5: Combine the formatted integer part, decimal part, and currency
  if (decimalPart.isNotEmpty) {
    return showCurrency
        ? '$formattedInteger.$decimalPart ${Constants.currencySymbol}'
        : '$formattedInteger.$decimalPart';
  } else {
    return showCurrency
        ? '$formattedInteger ${Constants.currencySymbol}'
        : formattedInteger;
  }
}

// Safe extract price from product JSON
int extractPrice(dynamic priceData) {
  if (priceData is Map && priceData.isNotEmpty) {
    // Get the first value from the price map
    var firstPrice = priceData.values.first;
    return int.tryParse(firstPrice.toString()) ?? 0;
  } else if (priceData is String) {
    return int.tryParse(priceData) ?? 0;
  } else if (priceData is int) {
    return priceData;
  }
  return 0;
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
