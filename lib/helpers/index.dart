import '../constant/index.dart';

String cleanProductName(String name) {
  // Check if the name contains '$' and remove everything from '$' onwards
  final dollarIndex = name.indexOf('\$');

  if (dollarIndex != -1) {
    return name.substring(0, dollarIndex).trim();
  }

  return name;
}

// Add or update these helper functions in your helpers/index.dart file

// Function to extract and properly format product price
int extractPrice(dynamic rawPrice) {
  // If price is null or empty, return 0
  if (rawPrice == null || rawPrice.toString().isEmpty) {
    return 0;
  }

  // Try to parse the price to a number
  int parsedPrice;
  try {
    // Handle various formats - strings, doubles, etc.
    if (rawPrice is int) {
      parsedPrice = rawPrice;
    } else if (rawPrice is double) {
      parsedPrice = rawPrice.toInt();
    } else {
      // Try to parse string to number
      parsedPrice =
          int.tryParse(rawPrice.toString().replaceAll(RegExp(r'[^0-9]'), '')) ??
          0;
    }
  } catch (e) {
    print('Error parsing price: $e');
    parsedPrice = 0;
  }

  // Divide base product prices by 100
  return parsedPrice ~/ 100;
}

// Function to extract and properly format modification price
int extractModificationPrice(dynamic rawPrice, bool isGroupModification) {
  // If price is null or empty, return 0
  if (rawPrice == null || rawPrice.toString().isEmpty) {
    return 0;
  }

  // Try to parse the price to a number
  int parsedPrice;
  try {
    // Handle various formats - strings, doubles, etc.
    if (rawPrice is int) {
      parsedPrice = rawPrice;
    } else if (rawPrice is double) {
      parsedPrice = rawPrice.toInt();
    } else {
      // Try to parse string to number
      parsedPrice =
          int.tryParse(rawPrice.toString().replaceAll(RegExp(r'[^0-9]'), '')) ??
          0;
    }
  } catch (e) {
    print('Error parsing modification price: $e');
    parsedPrice = 0;
  }

  // For group modifications, return as is (no division)
  // For regular modifications, divide by 100
  return isGroupModification ? parsedPrice : parsedPrice ~/ 100;
}

// Add or update this function in your helpers/index.dart file

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
    return '0 сум';
  }

  // Convert to numeric value
  num numericPrice;

  if (price is int) {
    numericPrice = price;
  } else if (price is double) {
    numericPrice = price;
  } else {
    // Try to parse string to number
    try {
      numericPrice = double.parse(price.toString());
    } catch (e) {
      print('Error parsing price: $e');
      return '0 сум';
    }
  }

  // Apply division if needed
  // subtract=true: Divide by 100 (for display of regular prices and regular mods)
  // subtract=false: Don't divide (for display of group modification prices)
  final formattedValue = subtract ? numericPrice ~/ 100 : numericPrice.toInt();

  // Return formatted with currency
  return '${formattedValue.toString()} сум';
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
