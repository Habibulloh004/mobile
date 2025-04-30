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
  bool subtract =
      false, // Changed default to false since most prices are already normalized
  String currencySymbol = 'сум',
}) {
  // Step 1: Apply division if needed (most prices should already be normalized)
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
        ? '$formattedInteger.$decimalPart $currencySymbol'
        : '$formattedInteger.$decimalPart';
  } else {
    return showCurrency
        ? '$formattedInteger $currencySymbol'
        : formattedInteger;
  }
}

int parsePrice(dynamic value, {bool divideBy100 = true}) {
  // Handle null values
  if (value == null) return 0;

  // Debug log the input value and its type
  debugPrint('🔢 Parsing price: $value (type: ${value.runtimeType})');

  // Handle numeric values (no division needed)
  if (value is int) return value;
  if (value is double) return value.toInt();

  // Handle string values
  if (value is String) {
    try {
      // Clean the string (remove non-numeric chars except decimal point)
      String cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');

      if (cleaned.isEmpty) return 0;

      // Parse the string to a numeric value
      num numericValue;
      if (cleaned.contains('.')) {
        numericValue = double.parse(cleaned);
      } else {
        numericValue = int.parse(cleaned);
      }

      // Apply division by 100 if needed (for string prices)
      if (divideBy100) {
        debugPrint(
          '💰 Dividing string price by 100: $numericValue ÷ 100 = ${numericValue / 100}',
        );
        return (numericValue / 100).toInt();
      } else {
        return numericValue.toInt();
      }
    } catch (e) {
      debugPrint('❌ Error parsing price: $e');
      return 0;
    }
  }

  // For any other type, try converting to string first, then parse
  try {
    return parsePrice(value.toString(), divideBy100: divideBy100);
  } catch (e) {
    debugPrint('❌ Error parsing price of unknown type: $e');
    return 0;
  }
}

int extractPrice(dynamic priceData) {
  // Debug the input
  debugPrint(
    '📊 Extracting price from: $priceData (type: ${priceData?.runtimeType})',
  );

  if (priceData is Map && priceData.isNotEmpty) {
    // Get the first value from the price map
    var firstPrice = priceData.values.first;
    debugPrint(
      '📊 Extracted price from map: $firstPrice (type: ${firstPrice?.runtimeType})',
    );

    // ALWAYS divide by 100 for consistency with API values
    if (firstPrice is String) {
      // Parse string to integer and divide by 100
      int parsed =
          int.tryParse(firstPrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      int result = parsed ~/ 100;
      debugPrint(
        '📊 String price from map: $firstPrice → $parsed → $result (divided by 100)',
      );
      return result;
    } else if (firstPrice is num) {
      // For numeric values, still divide by 100
      int result = (firstPrice ~/ 100);
      debugPrint(
        '📊 Numeric price from map: $firstPrice → $result (divided by 100)',
      );
      return result;
    }
  } else if (priceData is String) {
    // Parse string to integer and divide by 100
    int parsed = int.tryParse(priceData.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    int result = parsed ~/ 100;
    debugPrint(
      '📊 String price: $priceData → $parsed → $result (divided by 100)',
    );
    return result;
  } else if (priceData is int || priceData is double) {
    // For numeric values, still divide by 100
    int result = (priceData is double ? priceData.toInt() : priceData) ~/ 100;
    debugPrint('📊 Numeric price: $priceData → $result (divided by 100)');
    return result;
  }

  debugPrint('📊 Could not extract price, returning 0');
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
