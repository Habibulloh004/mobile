import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poster_app/constant/index.dart';
import 'package:poster_app/utils/color_utils.dart';

class WebTextareaField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final int maxLines;
  final int? maxLength;
  final Function(String)? onChanged;

  const WebTextareaField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.maxLines = 4,
    this.maxLength,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontSize: Constants.fontSizeMedium,
            fontWeight: FontWeight.bold,
            color: ColorUtils.secondaryColor,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: Constants.fontSizeRegular,
              color: ColorUtils.secondaryColor,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: Constants.fontSizeRegular,
              ),
              filled: true,
              fillColor: Colors.white,
              counterText: '', // Hide the counter text
              contentPadding: EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: ColorUtils.accentColor,
                  width: 2,
                ),
              ),
            ),
            cursorColor: ColorUtils.accentColor,
            cursorWidth: 2,
            cursorRadius: Radius.circular(1),
          ),
        ),
        // Optional character counter display
        if (maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 8.0),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${value.text.length}/$maxLength',
                    style: TextStyle(
                      fontSize: Constants.fontSizeSmall,
                      color: value.text.length > (maxLength! * 0.8)
                          ? (value.text.length > maxLength! ? Colors.red : Colors.orange)
                          : Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}