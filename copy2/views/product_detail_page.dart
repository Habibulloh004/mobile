// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/product_provider.dart';
// import '../providers/cart_provider.dart'; // ✅ Добавлен импорт
// import '../models/product_model.dart';
//
// class ProductDetailPage extends StatelessWidget {
//   final int productId;
//
//   const ProductDetailPage({Key? key, required this.productId}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final productProvider = Provider.of<ProductProvider>(context, listen: false);
//     final cartProvider = Provider.of<CartProvider>(context, listen: false); // ✅ Получаем доступ к корзине
//
//     final product = productProvider.products.firstWhere(
//           (p) => p.id == productId,
//       orElse: () => ProductModel(
//         id: 0,
//         name: "Неизвестный товар",
//         price: 0,
//         imageUrl: "",
//         description: "Описание отсутствует",
//       ),
//     );
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(product.name),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.network(
//                   product.imageUrl,
//                   width: double.infinity,
//                   height: 250,
//                   fit: BoxFit.cover,
//                   errorBuilder: (_, __, ___) => Image.asset("assets/images/no_image.png"),
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//             Text(
//               product.name,
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 8),
//             Text(
//               "${product.price} UZS",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
//             ),
//             SizedBox(height: 16),
//             Text(
//               product.description,
//               style: TextStyle(fontSize: 16, color: Colors.grey[700]),
//             ),
//             SizedBox(height: 20),
//             Center(
//               child: ElevatedButton.icon(
//                 onPressed: () {
//                   Map<String, dynamic> productData = {
//                     "product_id": product.id,
//                     "name": product.name,
//                     "price": product.price,
//                     "imageUrl": product.imageUrl,
//                   };
//
//                   print("🛒 Добавляем товар в корзину: $productData"); // ✅ Проверка в логах
//                   cartProvider.addItem(productData); // ✅ Вызываем метод добавления товара
//
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text("${product.name} добавлен в корзину!")),
//                   );
//                 },
//                 icon: Icon(Icons.shopping_cart),
//                 label: Text("Добавить в корзину"),
//                 style: ElevatedButton.styleFrom(
//                   padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                   textStyle: TextStyle(fontSize: 18),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product_model.dart';

class ProductDetailPage extends StatelessWidget {
  final int productId;

  const ProductDetailPage({Key? key, required this.productId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context);

    final product = productProvider.products.firstWhere(
          (p) => p.id == productId,
      orElse: () => ProductModel(
        id: 0,
        name: "Неизвестный товар",
        price: 0,
        imageUrl: "",
        description: "Описание отсутствует",
      ),
    );

    // ✅ Проверяем, есть ли товар в корзине
    final cartItem = cartProvider.cartItems.firstWhere(
          (item) => item['product_id'] == product.id,
      orElse: () => {"quantity": 0}, // ✅ Теперь `quantity` никогда не `null`
    );

    final int quantity = cartItem["quantity"] ?? 0; // ✅ Безопасное приведение

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  product.imageUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset("assets/images/no_image.png"),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              product.name,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "${product.price} UZS",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 16),
            Text(
              product.description,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),
            Center(
              child: quantity > 0
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      cartProvider.updateQuantity(product.id, -1);
                    },
                  ),
                  Text("$quantity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      cartProvider.updateQuantity(product.id, 1);
                    },
                  ),
                ],
              )
                  : ElevatedButton.icon(
                onPressed: () {
                  cartProvider.addItem({
                    "product_id": product.id,
                    "name": product.name,
                    "price": product.price,
                    "imageUrl": product.imageUrl,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${product.name} добавлен в корзину!")),
                  );
                },
                icon: Icon(Icons.shopping_cart),
                label: Text("Добавить в корзину"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
