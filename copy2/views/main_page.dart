import 'package:flutter/material.dart';
import 'category_page.dart';
import 'cart_page.dart';

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FooDery"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
          ),
        ],
      ),
      body: CategoryPage(),
    );
  }
}
