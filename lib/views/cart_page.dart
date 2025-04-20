import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../helpers/index.dart';
import 'checkout_page.dart';

class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: ColorUtils.bodyColor,
      appBar: AppBar(
        backgroundColor: ColorUtils.bodyColor,
        elevation: 0,
        title: Text(
          "Корзина",
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
        actions: [
          if (cartProvider.cartItems.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: ColorUtils.secondaryColor,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text("Очистить корзину?"),
                        content: Text(
                          "Вы уверены, что хотите удалить все товары из корзины?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text("Отмена"),
                          ),
                          TextButton(
                            onPressed: () {
                              cartProvider.clearCart();
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "Очистить",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
            ),
        ],
      ),
      body:
          cartProvider.cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCartItems(context, cartProvider),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            "Ваша корзина пуста",
            style: TextStyle(
              fontSize: Constants.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: ColorUtils.secondaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Добавьте товары, чтобы сделать заказ",
            style: TextStyle(
              fontSize: Constants.fontSizeRegular,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(BuildContext context, CartProvider cartProvider) {
    return Column(
      children: [
        // Delivery method selector
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => cartProvider.setDeliveryMethod(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        cartProvider.isDelivery
                            ? ColorUtils.primaryColor
                            : Colors.grey[200],
                    foregroundColor: ColorUtils.secondaryColor,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Доставка"),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => cartProvider.setDeliveryMethod(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        !cartProvider.isDelivery
                            ? ColorUtils.primaryColor
                            : Colors.grey[200],
                    foregroundColor: ColorUtils.secondaryColor,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("На вынос"),
                ),
              ),
            ],
          ),
        ),

        // Cart items list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: cartProvider.cartItems.length,
            itemBuilder: (context, index) {
              final item = cartProvider.cartItems[index];
              return _buildCartItemCard(context, item, cartProvider);
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
                    formatPrice(cartProvider.subtotal),
                    style: TextStyle(
                      fontSize: Constants.fontSizeRegular,
                      fontWeight: FontWeight.bold,
                      color: ColorUtils.secondaryColor,
                    ),
                  ),
                ],
              ),

              // Delivery fee (if applicable)
              if (cartProvider.isDelivery)
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
                        formatPrice(cartProvider.deliveryFee),
                        style: TextStyle(
                          fontSize: Constants.fontSizeRegular,
                          fontWeight: FontWeight.bold,
                          color: ColorUtils.secondaryColor,
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
                      formatPrice(cartProvider.total),
                      style: TextStyle(
                        fontSize: Constants.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: ColorUtils.accentColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Checkout button
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CheckoutPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorUtils.buttonColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Оплатить заказ",
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
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    Map<String, dynamic> item,
    CartProvider cartProvider,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Image.network(
                item['imageUrl'] ?? 'assets/images/no_image.png',
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
                  Text(
                    cleanProductName(item['name'] ?? 'Unknown Product'),
                    style: TextStyle(
                      fontSize: Constants.fontSizeRegular,
                      fontWeight: FontWeight.bold,
                      color: ColorUtils.secondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),

                  // Show modification if present
                  if (item.containsKey('modification'))
                    Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        item['modification']['name'],
                        style: TextStyle(
                          fontSize: Constants.fontSizeSmall,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),

                  // Price and quantity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatPrice(item['price'] ?? 0),
                        style: TextStyle(
                          fontSize: Constants.fontSizeRegular,
                          fontWeight: FontWeight.bold,
                          color: ColorUtils.accentColor,
                        ),
                      ),

                      // Quantity controls
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              cartProvider.updateQuantity(
                                item['product_id'],
                                -1,
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: ColorUtils.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.remove,
                                size: 16,
                                color: ColorUtils.secondaryColor,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: Text(
                              (item['quantity'] ?? 1).toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: Constants.fontSizeMedium,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              cartProvider.updateQuantity(
                                item['product_id'],
                                1,
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: ColorUtils.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: ColorUtils.secondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Remove button
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[400]),
            onPressed: () {
              cartProvider.removeItem(item);
            },
          ),
        ],
      ),
    );
  }
}
