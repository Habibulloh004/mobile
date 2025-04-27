import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../helpers/index.dart';
import '../models/product_model.dart';
import 'search_page.dart';
import 'cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({Key? key, required this.productId})
    : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  bool _productLoading = false;

  @override
  void initState() {
    super.initState();
    // Attempt to pre-load product if needed
    _checkAndLoadProduct();
  }

  Future<void> _checkAndLoadProduct() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    ProductModel? product = productProvider.getProductById(widget.productId);

    if (product == null) {
      setState(() {
        _productLoading = true;
      });

      // Try to fetch this specific product
      await productProvider.fetchProductById(widget.productId);

      setState(() {
        _productLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    // Find the product in the products list
    ProductModel? product = productProvider.getProductById(widget.productId);

    if (_productLoading) {
      return Scaffold(
        backgroundColor: ColorUtils.bodyColor,
        appBar: AppBar(
          backgroundColor: ColorUtils.bodyColor,
          elevation: 0,
          title: Text(
            "Загрузка...",
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
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorUtils.accentColor),
          ),
        ),
      );
    }

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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                "Товар не найден",
                style: TextStyle(
                  color: ColorUtils.secondaryColor,
                  fontSize: Constants.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "ID товара: ${widget.productId}",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Constants.fontSizeRegular,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorUtils.accentColor,
                  foregroundColor: Colors.white,
                ),
                child: Text("Вернуться назад"),
              ),
            ],
          ),
        ),
      );
    }

    // Check if this product+modification combination is in the cart
    final cartItems =
        cartProvider.cartItems.where((item) {
          if (item['product_id'] != product.id) return false;

          // Check if both have matching modifications
          final bool itemHasModification =
              item.containsKey('modification') && item['modification'] != null;
          final String? itemModificationId =
              itemHasModification
                  ? item['modification']['id']?.toString()
                  : null;

          final bool productHasModification =
              product.selectedModification != null;
          final String? productModificationId =
              productHasModification ? product.selectedModification!.id : null;

          return itemModificationId == productModificationId;
        }).toList();

    final int cartQuantity =
        cartItems.isNotEmpty ? cartItems.first['quantity'] : 0;

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
          IconButton(
            icon: SvgPicture.asset(
              'assets/images/search.svg',
              width: 24,
              height: 24,
              color: ColorUtils.secondaryColor,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  'assets/images/cart.svg',
                  color: ColorUtils.secondaryColor,
                  width: 24,
                  height: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartPage()),
                  );
                },
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
              child: Hero(
                tag: 'product_image_${product.id}',
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
                        formatPrice(product.effectivePrice),
                        style: TextStyle(
                          fontSize: Constants.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: ColorUtils.accentColor,
                        ),
                      ),
                    ],
                  ),

                  // Current selected modification
                  if (product.selectedModification != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ColorUtils.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: ColorUtils.accentColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              product.selectedModification!.name,
                              style: TextStyle(
                                color: ColorUtils.accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: Constants.fontSizeSmall,
                              ),
                            ),
                          ),
                          if (product.selectedModification!.price > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                "(+${formatPrice(product.selectedModification!.price)})",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: Constants.fontSizeSmall,
                                ),
                              ),
                            ),
                        ],
                      ),
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

                  // Group Modifications (if available)
                  if (product.groupModifications != null &&
                      product.groupModifications!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Варианты:",
                          style: TextStyle(
                            fontSize: Constants.fontSizeMedium,
                            fontWeight: FontWeight.bold,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: product.groupModifications!.length,
                          itemBuilder: (context, groupIndex) {
                            final group =
                                product.groupModifications![groupIndex];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (group.name.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 12,
                                      bottom: 8,
                                    ),
                                    child: Text(
                                      group.name,
                                      style: TextStyle(
                                        fontSize: Constants.fontSizeRegular,
                                        fontWeight: FontWeight.bold,
                                        color: ColorUtils.secondaryColor,
                                      ),
                                    ),
                                  ),
                                Column(
                                  children:
                                      group.modifications.map((mod) {
                                        bool isSelected =
                                            product.selectedModification?.id ==
                                            mod.id;
                                        return _buildModificationTile(
                                          product,
                                          mod,
                                          isSelected,
                                        );
                                      }).toList(),
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 16),
                      ],
                    ),

                  // Regular Modifications (if available)
                  if (product.modifications != null &&
                      product.modifications!.isNotEmpty &&
                      (product.groupModifications == null ||
                          product.groupModifications!.isEmpty))
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
                        Column(
                          children:
                              product.modifications!.map((mod) {
                                bool isSelected =
                                    product.selectedModification?.id == mod.id;
                                return _buildModificationTile(
                                  product,
                                  mod,
                                  isSelected,
                                );
                              }).toList(),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),

                  // Quantity selector
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
                                // Ensure a product has a selected modification if modifications are available
                                if ((product.modifications != null &&
                                        product.modifications!.isNotEmpty) ||
                                    (product.groupModifications != null &&
                                        product
                                            .groupModifications!
                                            .isNotEmpty)) {
                                  if (product.selectedModification == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Пожалуйста, выберите вариант",
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }
                                }

                                // Prepare cart item data
                                Map<String, dynamic> cartItem =
                                    product.toCartItem();
                                cartItem['quantity'] = _quantity;

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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Create a custom tile for showing modification options
  Widget _buildModificationTile(
    ProductModel product,
    ProductModification mod,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          product.selectedModification = mod;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? ColorUtils.accentColor.withOpacity(0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected
                    ? ColorUtils.accentColor
                    : Colors.grey.withOpacity(0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selected indicator
            if (isSelected)
              Container(
                width: 18,
                height: 18,
                margin: EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: ColorUtils.accentColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 14),
              )
            else
              Container(
                width: 18,
                height: 18,
                margin: EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withOpacity(0.5)),
                ),
              ),

            // Modification name
            Expanded(
              child: Text(
                mod.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: ColorUtils.secondaryColor,
                  fontSize: Constants.fontSizeRegular,
                ),
              ),
            ),

            // Price
            if (mod.price > 0)
              Text(
                "+${formatPrice(mod.price)}",
                style: TextStyle(
                  color: isSelected ? ColorUtils.accentColor : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: Constants.fontSizeRegular,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
