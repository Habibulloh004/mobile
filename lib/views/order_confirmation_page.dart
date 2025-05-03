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
  final int appliedBonus; // This is already divided by 100
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

              SizedBox(height: 8),

              // Status message
              // Text(
              //   isDelivery
              //       ? 'Ожидайте доставку в течение 60 минут'
              //       : 'Ваш заказ будет готов через 20 минут',
              //   textAlign: TextAlign.center,
              //   style: TextStyle(
              //     fontSize: Constants.fontSizeRegular,
              //     color: Colors.grey[600],
              //   ),
              // ),

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
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item['quantity']}x ${cleanProductName(item['name'])}',
                                style: TextStyle(
                                  fontSize: Constants.fontSizeRegular,
                                  color: ColorUtils.secondaryColor,
                                ),
                              ),
                              Text(
                                formatPrice(
                                  (item['price'] ?? 0) *
                                      (item['quantity'] ?? 1),
                                ),
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
                    if (isDelivery)
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

                    // Applied bonus (if any) - using formatPrice to handle division by 100
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

              // Rest of the UI remains unchanged

              // Bonus earned section - calculate earned bonus based on total (approx 5%)
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorUtils.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.savings, color: Colors.green[700], size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Начислено бонусов',
                          style: TextStyle(
                            fontSize: Constants.fontSizeMedium,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Calculate earned bonus (5% of subtotal)
                    // Already in raw format (divided by 100)
                    Text(
                      formatPrice(subtotal ~/ 20),
                      style: TextStyle(
                        fontSize: Constants.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Бонусы будут начислены на ваш счет после выполнения заказа',
                      style: TextStyle(
                        fontSize: Constants.fontSizeSmall,
                        color: Colors.grey[600],
                      ),
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
