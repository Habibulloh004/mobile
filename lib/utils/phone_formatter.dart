import 'package:flutter/services.dart';

class UzbekPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Always ensure the phone number starts with +998
    if (!newValue.text.startsWith('+998')) {
      return oldValue;
    }

    // Handle backspace
    if (oldValue.text.length > newValue.text.length) {
      return newValue;
    }

    // Get only digits after +998
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.startsWith('998')) {
      digitsOnly = digitsOnly.substring(3); // Remove 998 from the digits
    }

    // Build formatted number
    String formatted = '+998';

    // Add spacing and formatting based on the length of the digits
    if (digitsOnly.isNotEmpty) {
      // Add the area code with parentheses if we have it
      if (digitsOnly.length > 0) {
        // Add opening parenthesis and space after +998
        formatted += ' (';
        formatted += digitsOnly.substring(0, min(2, digitsOnly.length));

        // Add closing parenthesis
        if (digitsOnly.length > 2) {
          formatted += ') ';

          // Add the next 3 digits with spacing
          formatted += digitsOnly.substring(2, min(5, digitsOnly.length));

          if (digitsOnly.length > 5) {
            formatted += ' ';
            formatted += digitsOnly.substring(5, min(7, digitsOnly.length));

            if (digitsOnly.length > 7) {
              formatted += ' ';
              formatted += digitsOnly.substring(7, min(9, digitsOnly.length));
            }
          }
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }
}

// Helper function to get raw phone number without formatting
String getRawPhoneNumber(String formattedNumber) {
  return formattedNumber.replaceAll(RegExp(r'\D'), '');
}

// Helper function to format saved phone number for display
String formatSavedPhoneNumber(String rawPhone) {
  if (rawPhone.startsWith('+998') && rawPhone.length >= 13) {
    String digitsAfterCode = rawPhone.substring(4);
    String formatted =
        '+998 (${digitsAfterCode.substring(0, 2)}) ${digitsAfterCode.substring(2, 5)} ${digitsAfterCode.substring(5, 7)} ${digitsAfterCode.substring(7, 9)}';
    return formatted;
  }
  return rawPhone;
}
