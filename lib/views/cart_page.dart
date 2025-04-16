import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Корзина"),
        centerTitle: true,
      ),
      body: cartProvider.cartItems.isEmpty
          ? Center(child: Text("Корзина пуста"))
          : ListView.builder(
        itemCount: cartProvider.cartItems.length,
        itemBuilder: (context, index) {
          final item = cartProvider.cartItems[index];

          return CartItemWidget(
            product: item,
            onRemove: () {
              cartProvider.removeItem(item);
            },
          );
        },
      ),
      bottomNavigationBar: cartProvider.cartItems.isEmpty
          ? null
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Итого", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${cartProvider.totalPrice} UZS", style: TextStyle(fontSize: 18)),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Оформление заказа
              },
              child: Text("Перейти к оформлению"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartItemWidget extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onRemove;

  CartItemWidget({
    required this.product,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Image.network(
              product['imageUrl'] ?? "assets/images/no_image.png",
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset("assets/images/no_image.png"),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? "Без названия",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text("${product['price']} UZS", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          cartProvider.updateQuantity(product['product_id'], -1);
                        },
                      ),
                      Text(
                        product['quantity'].toString(),
                        style: TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          cartProvider.updateQuantity(product['product_id'], 1);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
