// lib/views/order_confirmation_page.dart
import 'package:flutter/material.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../helpers/index.dart';
import 'main_page.dart';

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

                    // Order items - Fixed to ensure items display correctly
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

                              // Extra logging to diagnose the item structure
                              debugPrint(
                                '📦 Processing item $index: ${item.toString()}',
                              );

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

                              // Debug print to help diagnose issues
                              debugPrint(
                                '📦 Item $index: $name, qty: $quantity, price: $price, total: $itemTotal',
                              );

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

                    // Subtotal - Make sure to display the correct subtotal
                    // If subtotal is 0 but items exist, recalculate the subtotal from items
                    Builder(
                      builder: (context) {
                        int calculatedSubtotal = subtotal;

                        // If subtotal is 0 but we have items, recalculate from items
                        if (subtotal == 0 && items.isNotEmpty) {
                          calculatedSubtotal = items.fold(0, (sum, item) {
                            int itemPrice = 0;
                            int itemQuantity = 1;

                            // Safe extraction of price
                            if (item['price'] != null) {
                              if (item['price'] is int) {
                                itemPrice = item['price'];
                              } else if (item['price'] is double) {
                                itemPrice = (item['price'] as double).toInt();
                              } else {
                                try {
                                  itemPrice = int.parse(
                                    item['price'].toString(),
                                  );
                                } catch (e) {
                                  debugPrint(
                                    '❌ Error parsing price for subtotal: $e',
                                  );
                                }
                              }
                            }

                            // Safe extraction of quantity
                            if (item['quantity'] != null) {
                              if (item['quantity'] is int) {
                                itemQuantity = item['quantity'];
                              } else if (item['quantity'] is double) {
                                itemQuantity =
                                    (item['quantity'] as double).toInt();
                              } else {
                                try {
                                  itemQuantity = int.parse(
                                    item['quantity'].toString(),
                                  );
                                } catch (e) {
                                  debugPrint(
                                    '❌ Error parsing quantity for subtotal: $e',
                                  );
                                }
                              }
                            }

                            return sum + (itemPrice * itemQuantity);
                          });

                          debugPrint(
                            '📊 Recalculated subtotal from items: $calculatedSubtotal',
                          );
                        }

                        return Row(
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
                              formatPrice(calculatedSubtotal),
                              style: TextStyle(
                                fontSize: Constants.fontSizeRegular,
                                fontWeight: FontWeight.bold,
                                color: ColorUtils.secondaryColor,
                              ),
                            ),
                          ],
                        );
                      },
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
                              '- ${formatPrice(appliedBonus.toInt() / 100)}',
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

                    // Total - Make sure to display the correct total
                    Builder(
                      builder: (context) {
                        int calculatedTotal = total;

                        // If total is 0 but we have items or subtotal, recalculate
                        if (total == 0) {
                          // Calculate from items if items exist
                          if (items.isNotEmpty) {
                            int itemsTotal = items.fold(0, (sum, item) {
                              int itemPrice = 0;
                              int itemQuantity = 1;

                              // Safe extraction of price
                              if (item['price'] != null) {
                                if (item['price'] is int) {
                                  itemPrice = item['price'];
                                } else if (item['price'] is double) {
                                  itemPrice = (item['price'] as double).toInt();
                                } else {
                                  try {
                                    itemPrice = int.parse(
                                      item['price'].toString(),
                                    );
                                  } catch (e) {
                                    debugPrint(
                                      '❌ Error parsing price for total: $e',
                                    );
                                  }
                                }
                              }

                              // Safe extraction of quantity
                              if (item['quantity'] != null) {
                                if (item['quantity'] is int) {
                                  itemQuantity = item['quantity'];
                                } else if (item['quantity'] is double) {
                                  itemQuantity =
                                      (item['quantity'] as double).toInt();
                                } else {
                                  try {
                                    itemQuantity = int.parse(
                                      item['quantity'].toString(),
                                    );
                                  } catch (e) {
                                    debugPrint(
                                      '❌ Error parsing quantity for total: $e',
                                    );
                                  }
                                }
                              }

                              return sum + (itemPrice * itemQuantity);
                            });

                            // Add delivery fee and subtract bonus
                            calculatedTotal =
                                itemsTotal + deliveryFee - appliedBonus;

                            // Use 31000 as fallback (from your screenshot) if calculation fails
                            if (calculatedTotal <= 0) {
                              calculatedTotal = 0;
                            }

                            debugPrint(
                              '📊 Recalculated total: $calculatedTotal (items: $itemsTotal, delivery: $deliveryFee, bonus: $appliedBonus)',
                            );
                          } else if (subtotal > 0) {
                            // Or use subtotal if it's available
                            calculatedTotal =
                                subtotal + deliveryFee - appliedBonus;
                            debugPrint(
                              '📊 Recalculated total from subtotal: $calculatedTotal',
                            );
                          } else {
                            // Last resort fallback - use 31000 from screenshot
                            calculatedTotal = 0;
                            debugPrint(
                              '📊 Using fallback total: $calculatedTotal',
                            );
                          }
                        }

                        return Row(
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
                              formatPrice(calculatedTotal),
                              style: TextStyle(
                                fontSize: Constants.fontSizeMedium,
                                fontWeight: FontWeight.bold,
                                color: ColorUtils.accentColor,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Return to main page button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => MainPage()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorUtils.buttonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Вернуться на главную',
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
      ),
    );
  }
}
