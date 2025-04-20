import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../helpers/index.dart';
import '../models/product_model.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({Key? key, required this.productId})
    : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  ProductModification? _selectedModification;

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final cartProvider = Provider.of<CartProvider>(context);

    // Find the product in the products list
    ProductModel? product = productProvider.getProductById(widget.productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Товар не найден"),
          backgroundColor: ColorUtils.bodyColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: ColorUtils.secondaryColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text(
            "Товар не найден",
            style: TextStyle(
              color: ColorUtils.secondaryColor,
              fontSize: Constants.fontSizeMedium,
            ),
          ),
        ),
      );
    }

    // Check if this product is in the cart
    final cartItem = cartProvider.cartItems.firstWhere(
      (item) => item['product_id'] == product.id,
      orElse: () => {"quantity": 0},
    );

    final cartQuantity = cartItem["quantity"] ?? 0;

    // Update the quantity if the product is already in the cart
    if (cartQuantity > 0 && _quantity == 1) {
      _quantity = cartQuantity;
    }

    return Scaffold(
      backgroundColor: ColorUtils.bodyColor,
      appBar: AppBar(
        backgroundColor: ColorUtils.bodyColor,
        elevation: 0,
        title: Text(
          cleanProductName(product.name),
          style: TextStyle(
            color: ColorUtils.secondaryColor,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorUtils.secondaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shopping_cart,
                  color: ColorUtils.secondaryColor,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              if (cartProvider.cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      cartProvider.cartItems.length.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: double.infinity,
              height: 250,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    "assets/images/no_image.png",
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),

            // Product Info
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          cleanProductName(product.name),
                          style: TextStyle(
                            fontSize: Constants.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        formatPrice(product.price),
                        style: TextStyle(
                          fontSize: Constants.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: ColorUtils.accentColor,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Product Description
                  if (product.description.isNotEmpty &&
                      product.description != "Описание отсутствует")
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Описание:",
                          style: TextStyle(
                            fontSize: Constants.fontSizeMedium,
                            fontWeight: FontWeight.bold,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          product.description,
                          style: TextStyle(
                            fontSize: Constants.fontSizeRegular,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),

                  // Modifications (if available)
                  if (product.modifications != null &&
                      product.modifications!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Модификации:",
                          style: TextStyle(
                            fontSize: Constants.fontSizeMedium,
                            fontWeight: FontWeight.bold,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children:
                              product.modifications!.map((mod) {
                                bool isSelected =
                                    _selectedModification?.id == mod.id;
                                return ChoiceChip(
                                  label: Text(mod.name),
                                  selected: isSelected,
                                  selectedColor: ColorUtils.accentColor
                                      .withOpacity(0.2),
                                  backgroundColor: ColorUtils.primaryColor,
                                  labelStyle: TextStyle(
                                    color:
                                        isSelected
                                            ? ColorUtils.accentColor
                                            : ColorUtils.secondaryColor,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedModification =
                                          selected ? mod : null;
                                    });
                                  },
                                );
                              }).toList(),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),

                  // Quantity selector
                  if (product.isAvailable)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Количество:",
                          style: TextStyle(
                            fontSize: Constants.fontSizeMedium,
                            fontWeight: FontWeight.bold,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: ColorUtils.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove),
                                    onPressed:
                                        _quantity > 1
                                            ? () {
                                              setState(() {
                                                _quantity--;
                                              });
                                            }
                                            : null,
                                    color: ColorUtils.secondaryColor,
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      _quantity.toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: Constants.fontSizeLarge,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: () {
                                      setState(() {
                                        _quantity++;
                                      });
                                    },
                                    color: ColorUtils.secondaryColor,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Prepare cart item data
                                  Map<String, dynamic> cartItem =
                                      product.toCartItem();
                                  cartItem['quantity'] = _quantity;

                                  // Add modification info if selected
                                  if (_selectedModification != null) {
                                    cartItem['modification'] = {
                                      'id': _selectedModification!.id,
                                      'name': _selectedModification!.name,
                                      'price': _selectedModification!.price,
                                    };
                                  }

                                  // Add to cart
                                  cartProvider.addItem(cartItem);

                                  // Show confirmation
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Товар добавлен в корзину"),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );

                                  // Go back to previous page
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorUtils.accentColor,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "Добавить в корзину",
                                  style: TextStyle(
                                    fontSize: Constants.fontSizeRegular,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Нет в наличии",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: Constants.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
