import 'package:flutter/material.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final String hintText;
  final bool autoFocus;
  final VoidCallback? onClear;
  final String? initialQuery;

  const SearchBarWidget({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.hintText = "Поиск",
    this.autoFocus = false,
    this.onClear,
    this.initialQuery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (initialQuery != null && initialQuery!.isNotEmpty) {
      controller.text = initialQuery!;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        autofocus: autoFocus,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(Icons.search, color: ColorUtils.accentColor),
          suffixIcon:
              controller.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[400]),
                    onPressed: () {
                      controller.clear();
                      onChanged("");
                      if (onClear != null) onClear!();
                    },
                  )
                  : null,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          fillColor: ColorUtils.primaryColor.withOpacity(0.5),
          filled: true,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: Constants.fontSizeRegular,
          ),
        ),
        style: TextStyle(
          color: ColorUtils.secondaryColor,
          fontSize: Constants.fontSizeRegular,
        ),
      ),
    );
  }
}
