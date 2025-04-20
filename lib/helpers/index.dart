import '../constant/index.dart';

String cleanProductName(String name) {
  // Check if the name contains '$' and remove everything from '$' onwards
  final dollarIndex = name.indexOf('\$');

  if (dollarIndex != -1) {
    return name.substring(0, dollarIndex).trim();
  }

  return name;
}

// Format price from API (in cents/minor units) to readable format
String formatPrice(num price, {String type = 'space', bool showCurrency = true}) {
  // Step 1: Divide the price by 100 for better display
  double formattedPrice = price / 100;

  // Step 2: Format the number with 0 decimal places if it's a whole number, otherwise 2 decimal places
  String priceString = formattedPrice % 1 == 0
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