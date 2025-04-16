import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import 'product_detail_page.dart';

class ProductPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const ProductPage({Key? key, required this.categoryId, required this.categoryName})
      : super(key: key);

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.loadProducts(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName), centerTitle: true),
      body: productProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : productProvider.products.isEmpty
          ? Center(child: Text("Нет доступных товаров"))
          : GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemCount: productProvider.products.length,
        itemBuilder: (context, index) {
          final product = productProvider.products[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProductDetailPage(
                      productId: product.id,
                    )),
              );
            },
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Expanded(
                    child: Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset("assets/images/no_image.png"),
                    ),
                  ),
                  Text(product.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "${product.price} UZS",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
