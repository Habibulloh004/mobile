String cleanProductName(String name) {
  // Check if the name contains '$' and remove everything from '$' onwards
  final dollarIndex = name.indexOf('\$');

  if (dollarIndex != -1) {
    return name.substring(0, dollarIndex).trim();
  }

  return name;
}

// helpers/index.dart

String formatPrice(num price, {String type = 'space'}) {
  // Step 1: Divide the price by 100
  double formattedPrice = price / 100;

  // Step 2: Format the number with 2 decimal places
  String priceString = formattedPrice.toStringAsFixed(2); // e.g., "32000.00"

  // Step 3: Split into integer and decimal parts
  List<String> parts = priceString.split('.'); // ["32000", "00"]
  String integerPart = parts[0];
  String decimalPart = parts[1];

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
  return '$formattedInteger.$decimalPart UZS';
}