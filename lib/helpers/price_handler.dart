// lib/helpers/price_handler.dart
import 'package:flutter/foundation.dart';

/// Parses and processes price values from various formats into a standardized integer value
///
/// This function handles both string and numeric price values:
/// - For string values: Removes non-numeric characters, parses to int, and divides by 100
/// - For numeric values: Converts to int without division (assumes already processed)
///
/// @param value The price value to process (can be String, int, double, or dynamic)
/// @param [divideStringsByHundred=true] Whether to divide string prices by 100
/// @return Standardized integer price value
int parsePrice(dynamic value, {bool divideStringsByHundred = true}) {
  // Handle null values
  if (value == null) return 0;

  // Debug log the input value and its type
  debugPrint('🔢 Parsing price: $value (type: ${value.runtimeType})');

  // Handle numeric values (no division needed for numbers)
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
      if (divideStringsByHundred) {
        debugPrint(
          '💰 Dividing string price by 100: $numericValue ÷ 100 = ${numericValue / 100}',
        );
        return (numericValue ~/ 100);
      } else {
        return numericValue.toInt();
      }
    } catch (e) {
      debugPrint('❌ Error parsing price: $e');
      return 0;
    }
  }

  // For Map values (like API responses that have price in a nested structure)
  if (value is Map && value.isNotEmpty) {
    // Get the first value from the price map
    var firstPrice = value.values.first;
    debugPrint(
      '📊 Extracted price from map: $firstPrice (type: ${firstPrice?.runtimeType})',
    );

    // Recursive call to process the extracted price
    return parsePrice(
      firstPrice,
      divideStringsByHundred: divideStringsByHundred,
    );
  }

  // For any other type, try converting to string first, then parse
  try {
    return parsePrice(
      value.toString(),
      divideStringsByHundred: divideStringsByHundred,
    );
  } catch (e) {
    debugPrint('❌ Error parsing price of unknown type: $e');
    return 0;
  }
}

/// Formats a price integer to a readable string with currency symbol
///
/// @param price The integer price value
/// @param [type='space'] The type of separator to use ('space' or 'comma')
/// @param [showCurrency=true] Whether to show the currency symbol
/// @param [currencySymbol='сум'] The currency symbol to use
/// @return Formatted price string
String formatPrice(
  int price, {
  String type = 'space',
  bool showCurrency = true,
  String currencySymbol = 'сум',
}) {
  // Format the price as a string
  String priceString = price.toString();

  // Add thousand separators
  String separator = type == 'space' ? ' ' : ',';
  String formattedInteger = '';
  for (int i = 0; i < priceString.length; i++) {
    if (i > 0 && (priceString.length - i) % 3 == 0) {
      formattedInteger += separator;
    }
    formattedInteger += priceString[i];
  }

  // Add currency symbol if requested
  return showCurrency ? '$formattedInteger $currencySymbol' : formattedInteger;
}
