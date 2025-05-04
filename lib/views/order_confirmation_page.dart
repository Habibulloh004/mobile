// lib/views/order_confirmation_page.dart
import 'package:flutter/material.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../helpers/index.dart';
import 'main_page.dart';
import 'order_history_page.dart';

class OrderConfirmationPage extends StatelessWidget {
  final int orderId;
  final List<Map<String, dynamic>> items;
  final int total;
  final int subtotal;
  final int deliveryFee;
  final int appliedBonus; // This is already the raw value without division
  final String address;
  final bool isDelivery;
  final String paymentMethod;
  final String? spotId;
  final String? spotName;

  const OrderConfirmationPage({
    Key? key,
    required this.orderId,
    required this.items,
    required this.total,
    required this.subtotal,
    required this.deliveryFee,
    this.appliedBonus = 0, // Default to 0 if not provided
    required this.address,
    required this.isDelivery,
    required this.paymentMethod,
    this.spotId,
    this.spotName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Debug the items data received
    debugPrint(
      '🛒 OrderConfirmationPage received ${items.length} items: $items',
    );

    return Scaffold(
      backgroundColor: ColorUtils.bodyColor,
      appBar: AppBar(
        backgroundColor: ColorUtils.bodyColor,
        elevation: 0,
        title: Text(
          'Заказ №$orderId',
          style: TextStyle(
            color: ColorUtils.secondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 48, color: Colors.white),
              ),

              SizedBox(height: 16),

              // Success message
              Text(
                'Заказ успешно оформлен!',
                style: TextStyle(
                  fontSize: Constants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: ColorUtils.secondaryColor,
                ),
              ),

              SizedBox(height: 32),

              // Order details
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorUtils.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Детали заказа',
                      style: TextStyle(
                        fontSize: Constants.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: ColorUtils.secondaryColor,
                      ),
                    ),

                    SizedBox(height: 16),

                    // Order items
                    if (items.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];

                              // Ensure all properties are safely extracted with fallbacks
                              final String name =
                                  item['name'] ?? 'Неизвестный товар';
                              int quantity = 1;
                              int price = 0;

                              // Safely handle different types for quantity
                              if (item['quantity'] != null) {
                                if (item['quantity'] is int) {
                                  quantity = item['quantity'];
                                } else if (item['quantity'] is double) {
                                  quantity =
                                      (item['quantity'] as double).toInt();
                                } else {
                                  try {
                                    quantity = int.parse(
                                      item['quantity'].toString(),
                                    );
                                  } catch (e) {
                                    debugPrint('❌ Error parsing quantity: $e');
                                  }
                                }
                              }

                              // Safely handle different types for price
                              if (item['price'] != null) {
                                if (item['price'] is int) {
                                  price = item['price'];
                                } else if (item['price'] is double) {
                                  price = (item['price'] as double).toInt();
                                } else {
                                  try {
                                    price = int.parse(item['price'].toString());
                                  } catch (e) {
                                    debugPrint('❌ Error parsing price: $e');
                                  }
                                }
                              }

                              final int itemTotal = price * quantity;

                              return Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${quantity}x ${cleanProductName(name)}',
                                        style: TextStyle(
                                          fontSize: Constants.fontSizeRegular,
                                          color: ColorUtils.secondaryColor,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      formatPrice(itemTotal),
                                      style: TextStyle(
                                        fontSize: Constants.fontSizeRegular,
                                        fontWeight: FontWeight.bold,
                                        color: ColorUtils.secondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    else
                      // Fallback if no items are provided
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Информация о товарах недоступна',
                          style: TextStyle(
                            fontSize: Constants.fontSizeRegular,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                    Divider(color: Colors.grey[300]),

                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Товары',
                          style: TextStyle(
                            fontSize: Constants.fontSizeRegular,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                        Text(
                          formatPrice(subtotal),
                          style: TextStyle(
                            fontSize: Constants.fontSizeRegular,
                            fontWeight: FontWeight.bold,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                      ],
                    ),

                    // Delivery fee (if applicable)
                    if (isDelivery && deliveryFee > 0)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Доставка',
                              style: TextStyle(
                                fontSize: Constants.fontSizeRegular,
                                color: ColorUtils.secondaryColor,
                              ),
                            ),
                            Text(
                              formatPrice(deliveryFee),
                              style: TextStyle(
                                fontSize: Constants.fontSizeRegular,
                                fontWeight: FontWeight.bold,
                                color: ColorUtils.secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Applied bonus (if any)
                    if (appliedBonus > 0)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Использовано бонусов',
                              style: TextStyle(
                                fontSize: Constants.fontSizeRegular,
                                color: Colors.green[800],
                              ),
                            ),
                            Text(
                              '- ${formatPrice(appliedBonus)}',
                              style: TextStyle(
                                fontSize: Constants.fontSizeRegular,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                      ),

                    Divider(color: Colors.grey[300]),

                    // Delivery or pickup information
                    if (address.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDelivery
                                  ? 'Адрес доставки:'
                                  : 'Адрес самовывоза:',
                              style: TextStyle(
                                fontSize: Constants.fontSizeSmall,
                                fontWeight: FontWeight.bold,
                                color: ColorUtils.secondaryColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              address,
                              style: TextStyle(
                                fontSize: Constants.fontSizeSmall,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Payment method
                    Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            paymentMethod == 'card'
                                ? Icons.credit_card
                                : Icons.money,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Text(
                            paymentMethod == 'card'
                                ? 'Оплата картой'
                                : 'Оплата наличными',
                            style: TextStyle(
                              fontSize: Constants.fontSizeSmall,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(color: Colors.grey[300]),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Общая сумма',
                          style: TextStyle(
                            fontSize: Constants.fontSizeMedium,
                            fontWeight: FontWeight.bold,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                        Text(
                          formatPrice(total),
                          style: TextStyle(
                            fontSize: Constants.fontSizeMedium,
                            fontWeight: FontWeight.bold,
                            color: ColorUtils.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Buttons for actions
              Column(
                children: [
                  // View order history button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderHistoryPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorUtils.accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Перейти к истории заказов',
                        style: TextStyle(
                          fontSize: Constants.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Return to main page button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => MainPage()),
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: ColorUtils.accentColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Вернуться на главную',
                        style: TextStyle(
                          color: ColorUtils.accentColor,
                          fontSize: Constants.fontSizeRegular,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
