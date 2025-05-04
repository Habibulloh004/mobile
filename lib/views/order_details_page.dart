import 'package:flutter/material.dart';
import 'dart:convert';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../helpers/index.dart';
import '../models/order_model.dart';

class OrderDetailsPage extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorUtils.bodyColor,
      appBar: AppBar(
        backgroundColor: ColorUtils.bodyColor,
        elevation: 0,
        title: Text(
          'Заказ №${order.id}',
          style: TextStyle(
            color: ColorUtils.secondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorUtils.secondaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Delivery type selector (non-functional, just for UI)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: null, // Non-functional
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          order.deliveryType == 'delivery'
                              ? ColorUtils.primaryColor
                              : Colors.grey[200],
                      foregroundColor: ColorUtils.secondaryColor,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor:
                          order.deliveryType == 'delivery'
                              ? ColorUtils.primaryColor
                              : Colors.grey[200],
                      disabledForegroundColor: ColorUtils.secondaryColor,
                    ),
                    child: Text("Доставка"),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: null, // Non-functional
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          order.deliveryType != 'delivery'
                              ? ColorUtils.primaryColor
                              : Colors.grey[200],
                      foregroundColor: ColorUtils.secondaryColor,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor:
                          order.deliveryType != 'delivery'
                              ? ColorUtils.primaryColor
                              : Colors.grey[200],
                      disabledForegroundColor: ColorUtils.secondaryColor,
                    ),
                    child: Text("На вынос"),
                  ),
                ),
              ],
            ),
          ),

          // Order information
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorUtils.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Дата:',
                        style: TextStyle(
                          fontSize: Constants.fontSizeRegular,
                          color: ColorUtils.secondaryColor,
                        ),
                      ),
                      Text(
                        order.date,
                        style: TextStyle(
                          fontSize: Constants.fontSizeRegular,
                          fontWeight: FontWeight.bold,
                          color: ColorUtils.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (order.address != null && order.address!.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Адрес:',
                          style: TextStyle(
                            fontSize: Constants.fontSizeRegular,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.address!,
                            style: TextStyle(
                              fontSize: Constants.fontSizeRegular,
                              fontWeight: FontWeight.bold,
                              color: ColorUtils.secondaryColor,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (order.spotName != null && order.spotName!.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Точка самовывоза:',
                          style: TextStyle(
                            fontSize: Constants.fontSizeRegular,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                        Text(
                          order.spotName!,
                          style: TextStyle(
                            fontSize: Constants.fontSizeRegular,
                            fontWeight: FontWeight.bold,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Order items list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return _buildCartItemCard(context, item);
              },
            ),
          ),

          // Summary and checkout
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorUtils.primaryColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Товары",
                      style: TextStyle(
                        fontSize: Constants.fontSizeRegular,
                        color: ColorUtils.secondaryColor,
                      ),
                    ),
                    Text(
                      formatPrice(order.subtotal),
                      style: TextStyle(
                        fontSize: Constants.fontSizeRegular,
                        fontWeight: FontWeight.bold,
                        color: ColorUtils.secondaryColor,
                      ),
                    ),
                  ],
                ),

                // Delivery fee (if applicable)
                if (order.deliveryType == 'delivery' && order.deliveryFee > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Доставка",
                          style: TextStyle(
                            fontSize: Constants.fontSizeRegular,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                        Text(
                          formatPrice(order.deliveryFee),
                          style: TextStyle(
                            fontSize: Constants.fontSizeRegular,
                            fontWeight: FontWeight.bold,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                // if (order.appliedBonus != null && order.appliedBonus! > 0)
                if (order.subtotal + order.deliveryFee - order.total != 0)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Использовано бонусов",
                          style: TextStyle(
                            fontSize: Constants.fontSizeRegular,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          "- ${formatPrice(order.subtotal + order.deliveryFee - order.total)}",
                          style: TextStyle(
                            fontSize: Constants.fontSizeRegular,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Total
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Общая сумма",
                        style: TextStyle(
                          fontSize: Constants.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: ColorUtils.secondaryColor,
                        ),
                      ),
                      Text(
                        formatPrice(order.total),
                        style: TextStyle(
                          fontSize: Constants.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: ColorUtils.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Return button
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorUtils.buttonColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Вернуться",
                      style: TextStyle(
                        fontSize: Constants.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Updated _buildCartItemCard method for order_details_page.dart
  Widget _buildCartItemCard(BuildContext context, OrderItem item) {
    // Extract modification information
    String? modificationName;
    int? modificationPrice;
    dynamic modification = item.modification;
    List<Map<String, dynamic>> groupModifications = [];

    // Handle different types of modifications
    if (modification != null) {
      if (modification is Map<String, dynamic>) {
        // Regular modification
        modificationName = modification['name']?.toString();
        modificationPrice =
            modification['price'] is int
                ? modification['price']
                : (modification['price'] is String
                    ? int.tryParse(modification['price'])
                    : null);
      } else if (modification is String) {
        // Group modifications in JSON string
        try {
          final List<dynamic> mods = jsonDecode(modification);
          for (var mod in mods) {
            try {
              Map<String, dynamic> modMap = {};
              if (mod is Map<String, dynamic>) {
                modMap = mod;
                // Make sure we have name and price if available
                if (!modMap.containsKey("name") && mod.containsKey("name")) {
                  modMap["name"] = mod["name"];
                }
                if (!modMap.containsKey("price") && mod.containsKey("price")) {
                  modMap["price"] = mod["price"];
                }
              } else {
                // Extract the basic info
                modMap = {'m': mod['m'] ?? mod, 'a': mod['a'] ?? 1};

                // Add name if available (like in cart_page.dart)
                if (mod.containsKey("name")) {
                  modMap["name"] = mod["name"];
                }

                // Add price if available (like in cart_page.dart)
                if (mod.containsKey("price")) {
                  modMap["price"] = mod["price"];
                }
              }
              groupModifications.add(modMap);
            } catch (e) {
              debugPrint('Error parsing modification: $e');
            }
          }
        } catch (e) {
          debugPrint('Error parsing group modifications: $e');
        }
      }
    }

    // Prepare the display name with modification in parentheses
    String displayName = cleanProductName(item.name);
    if (modificationName != null) {
      // Add the modification name in parentheses
      displayName = "$displayName ($modificationName)";
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main item content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(
                    groupModifications.isEmpty ? 12 : 0,
                  ),
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/no_image.png',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),

              // Product info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name with modification in parentheses
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              // Using the combined name with modification
                              style: TextStyle(
                                fontSize: Constants.fontSizeRegular,
                                fontWeight: FontWeight.bold,
                                color: ColorUtils.secondaryColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Additions badge for group modifications
                          if (groupModifications.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(left: 6, top: 2),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorUtils.primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: ColorUtils.secondaryColor
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Добавки',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: ColorUtils.secondaryColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 4),

                      // We don't need to display the modification name separately anymore
                      // since it's now included in the product name

                      // Price display
                      Text(
                        formatPrice(item.price),
                        style: TextStyle(
                          color: ColorUtils.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: Constants.fontSizeMedium,
                        ),
                      ),

                      SizedBox(height: 12),

                      // Quantity row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Quantity label
                          Text(
                            'Кол-во:',
                            style: TextStyle(
                              fontSize: Constants.fontSizeSmall,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 8),
                          // Quantity display
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: ColorUtils.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.quantity.toString(),
                              style: TextStyle(
                                fontSize: Constants.fontSizeRegular,
                                fontWeight: FontWeight.bold,
                                color: ColorUtils.secondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Group Modifications section
          if (groupModifications.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: ColorUtils.primaryColor.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Добавки:',
                    style: TextStyle(
                      fontSize: Constants.fontSizeSmall,
                      fontWeight: FontWeight.bold,
                      color: ColorUtils.secondaryColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    // Show ALL group modifications
                    children:
                        groupModifications.map((mod) {
                          // Display name if available, otherwise show ID
                          String displayText =
                              mod.containsKey("name")
                                  ? mod["name"]
                                  : "ID: ${mod["m"]}";
                          int? price =
                              mod.containsKey("price") ? mod["price"] : null;

                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: ColorUtils.accentColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ColorUtils.secondaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Show price if available
                                if (price != null && price > 0)
                                  Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Text(
                                      '+${formatPrice(price)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: ColorUtils.accentColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
