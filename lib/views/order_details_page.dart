import 'package:flutter/material.dart';
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order status and date
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Статус',
                          style: TextStyle(
                            fontSize: Constants.fontSizeMedium,
                            fontWeight: FontWeight.bold,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                order.status == 'Доставлен'
                                    ? Colors.green[100]
                                    : Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.status,
                            style: TextStyle(
                              fontSize: Constants.fontSizeSmall,
                              fontWeight: FontWeight.bold,
                              color:
                                  order.status == 'Доставлен'
                                      ? Colors.green[700]
                                      : Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Дата',
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
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Тип',
                          style: TextStyle(
                            fontSize: Constants.fontSizeRegular,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              order.deliveryType == 'delivery'
                                  ? Icons.delivery_dining
                                  : Icons.shopping_bag,
                              color: ColorUtils.secondaryColor,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              order.deliveryType == 'delivery'
                                  ? 'Доставка'
                                  : 'На вынос',
                              style: TextStyle(
                                fontSize: Constants.fontSizeRegular,
                                fontWeight: FontWeight.bold,
                                color: ColorUtils.secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Order items
              Text(
                'Товары',
                style: TextStyle(
                  fontSize: Constants.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: ColorUtils.secondaryColor,
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorUtils.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: order.items.length,
                      separatorBuilder: (context, index) => Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = order.items[index];
                        return Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
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
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cleanProductName(item.name),
                                    style: TextStyle(
                                      fontSize: Constants.fontSizeRegular,
                                      fontWeight: FontWeight.bold,
                                      color: ColorUtils.secondaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    formatPrice(item.price),
                                    style: TextStyle(
                                      fontSize: Constants.fontSizeSmall,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'x${item.quantity}',
                                style: TextStyle(
                                  fontSize: Constants.fontSizeRegular,
                                  fontWeight: FontWeight.bold,
                                  color: ColorUtils.secondaryColor,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),

                    // Order summary
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
                          formatPrice(order.subtotal.toDouble()),
                          style: TextStyle(
                            fontSize: Constants.fontSizeRegular,
                            fontWeight: FontWeight.bold,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                      ],
                    ),

                    if (order.deliveryType == 'delivery' &&
                        order.deliveryFee > 0)
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
                              formatPrice(order.deliveryFee.toDouble()),
                              style: TextStyle(
                                fontSize: Constants.fontSizeRegular,
                                fontWeight: FontWeight.bold,
                                color: ColorUtils.secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 8),
                    Divider(),
                    SizedBox(height: 8),

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
                          formatPrice(order.total.toDouble()),
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

              SizedBox(height: 24),

              // Return button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: ColorUtils.accentColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Вернуться',
                    style: TextStyle(
                      color: ColorUtils.accentColor,
                      fontSize: Constants.fontSizeRegular,
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
