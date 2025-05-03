import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';


class AnimatedInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final String? suffixText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Function(String)? onChanged;
  final int maxLines;

  const AnimatedInputField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.obscureText = false,
    this.onChanged,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        suffixText: suffixText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: ColorUtils.accentColor.withOpacity(0.5),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: ColorUtils.accentColor, width: 2.0),
        ),
        // This makes the label float above the field when focused or filled
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        // Animation for the floating label
        floatingLabelStyle: TextStyle(
          color: ColorUtils.accentColor,
          fontWeight: FontWeight.bold,
        ),
        // The style for the label when focused/unfocused
        labelStyle: TextStyle(color: Colors.grey[600]),
        contentPadding: EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: prefixIcon != null ? 8.0 : 16.0,
        ),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      onChanged: onChanged,
      maxLines: maxLines,
      // Adding this to ensure smooth cursor and text animation
      cursorColor: ColorUtils.accentColor,
      style: TextStyle(
        color: ColorUtils.secondaryColor,
        fontSize: Constants.fontSizeRegular,
      ),
    );
  }
}
