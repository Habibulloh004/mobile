import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poster_app/providers/cart_provider.dart';
import 'package:poster_app/models/product_model.dart';

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
          ? Center(child: Text("Ваша корзина пуста"))
          : ListView.builder(
        itemCount: cartProvider.cartItems.length,
        itemBuilder: (context, index) {
          final product = cartProvider.cartItems[index];

          return ListTile(
            leading: Image.network(
              product['image_url'],
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            title: Text(product['product_name']),
            subtitle: Text("${product['price']} UZS"),
            trailing: IconButton(
              icon: Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () {
                cartProvider.removeItem(product);
              },
            ),
          );
        },
      ),
      bottomNavigationBar: cartProvider.cartItems.isEmpty
          ? null
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Оформление заказа пока не реализовано")),
            );
          },
          child: Text("Перейти к оплате"),
        ),
      ),
    );
  }
}
