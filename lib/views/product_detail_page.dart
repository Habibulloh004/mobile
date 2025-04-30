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
import 'dart:convert';

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

  // Map to track selected modifications in group modifications
  Map<String, bool> _selectedGroupModifications = {};

  // Map to store modification details for retrieval later
  Map<String, ProductModification> _modificationDetailsMap = {};

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
    } else {
      // Initialize modification maps
      _initializeSelectedModifications(product);
    }
  }

  // Initialize selected modifications from group modifications
  void _initializeSelectedModifications(ProductModel product) {
    if (product.groupModifications != null &&
        product.groupModifications!.isNotEmpty) {
      for (var group in product.groupModifications!) {
        for (var mod in group.modifications) {
          // Initialize all to false (unselected)
          _selectedGroupModifications[mod.id] = false;

          // Store modification details for later use
          _modificationDetailsMap[mod.id] = mod;
        }
      }
    }
  }

  // Generate JSON format for selected group modifications
  String getSelectedModificationsJson() {
    List<Map<String, dynamic>> result = [];

    _selectedGroupModifications.forEach((id, isSelected) {
      if (isSelected) {
        // Try to parse ID to int if possible
        int? modId;
        try {
          modId = int.parse(id);
        } catch (e) {
          // If parsing fails, use the ID as is
          modId = int.tryParse(id);
        }

        result.add({"m": modId ?? id, "a": 1});
      }
    });

    return jsonEncode(result);
  }

  // In product_detail_page.dart, update the calculateTotalPrice method:

  // Calculate total price including all selected modifications
  int calculateTotalPrice(ProductModel product) {
    // Base price is already divided by 100 during product loading
    int totalPrice = product.price;
    debugPrint('💰 Base price: ${product.price}');

    // Add price for regular modifications (already divided by 100 during loading)
    if (product.selectedModification != null) {
      totalPrice += product.selectedModification!.price;
      debugPrint('💰 With regular mod: +${product.selectedModification!.price} = $totalPrice');
    }

    // Add prices for group modifications (now also divided by 100)
    int groupModTotal = 0;
    _selectedGroupModifications.forEach((id, isSelected) {
      if (isSelected && _modificationDetailsMap.containsKey(id)) {
        int modPrice = _modificationDetailsMap[id]!.price;
        groupModTotal += modPrice;
        debugPrint('💰 Group mod: $id = +$modPrice');
      }
    });

    totalPrice += groupModTotal;
    debugPrint('💰 Final total with group mods: $totalPrice');

    return totalPrice;
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

    // Initialize modification maps if not already done
    if (_modificationDetailsMap.isEmpty &&
        product.groupModifications != null &&
        product.groupModifications!.isNotEmpty) {
      _initializeSelectedModifications(product);
    }

    // Calculate the total price including all selected modifications
    final totalPrice = calculateTotalPrice(product);

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
                        formatPrice(totalPrice, subtract: false),
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

                  // Group Modifications (if available) - WITH CHECKBOXES ONLY
                  if (product.groupModifications != null &&
                      product.groupModifications!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Добавки:",
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
                                    child: Row(
                                      children: [
                                        Text(
                                          group.name,
                                          style: TextStyle(
                                            fontSize: Constants.fontSizeRegular,
                                            fontWeight: FontWeight.bold,
                                            color: ColorUtils.secondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Always use checkbox style (even for type 1)
                                Column(
                                  children:
                                      group.modifications.map((mod) {
                                        bool isSelected =
                                            _selectedGroupModifications[mod
                                                .id] ??
                                            false;

                                        return _buildCheckboxModificationTile(
                                          mod,
                                          isSelected,
                                          (selected) {
                                            setState(() {
                                              _selectedGroupModifications[mod
                                                      .id] =
                                                  selected;
                                            });
                                          },
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

                  // Regular Modifications (if available) - KEEP THE ORIGINAL RADIO BUTTONS
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
                                // Check for regular modifications - these are still required
                                bool hasRequiredSelections = true;
                                String errorMessage = "";

                                // Check for regular modifications
                                bool hasRegularModifications =
                                    (product.modifications != null &&
                                        product.modifications!.isNotEmpty);

                                if (hasRegularModifications &&
                                    product.selectedModification == null) {
                                  hasRequiredSelections = false;
                                  errorMessage = "Пожалуйста, выберите вариант";
                                }

                                if (!hasRequiredSelections) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(errorMessage),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                // Prepare cart item data
                                Map<String, dynamic> cartItem = {};

                                List<Map<String, dynamic>>
                                selectedModsWithNames = [];
                                _selectedGroupModifications.forEach((
                                  id,
                                  isSelected,
                                ) {
                                  if (isSelected &&
                                      _modificationDetailsMap.containsKey(id)) {
                                    int? modId;
                                    try {
                                      modId = int.parse(id);
                                    } catch (e) {
                                      modId = null;
                                    }

                                    selectedModsWithNames.add({
                                      "m": modId ?? id,
                                      "a": 1,
                                      "name": _modificationDetailsMap[id]!.name,
                                      "price":
                                          _modificationDetailsMap[id]!.price,
                                      // Don't divide, already correct
                                    });
                                  }
                                });

                                // Create selected modifications data with names for display
                                // List<Map<String, dynamic>>
                                // selectedModsWithNames = [];
                                _selectedGroupModifications.forEach((
                                  id,
                                  isSelected,
                                ) {
                                  if (isSelected &&
                                      _modificationDetailsMap.containsKey(id)) {
                                    int? modId;
                                    try {
                                      modId = int.parse(id);
                                    } catch (e) {
                                      modId = null;
                                    }

                                    selectedModsWithNames.add({
                                      "m": modId ?? id,
                                      "a": 1,
                                      "name": _modificationDetailsMap[id]!.name,
                                      "price":
                                          _modificationDetailsMap[id]!.price,
                                    });
                                  }
                                });

                                // Handle different scenarios
                                if (product.groupModifications != null &&
                                    product.groupModifications!.isNotEmpty) {
                                  // Get modifications in required format for API
                                  String modificationsJson =
                                      getSelectedModificationsJson();

                                  // Create cart item with group modifications
                                  cartItem = {
                                    'product_id': product.id,
                                    'name': product.name,
                                    'price': totalPrice,
                                    // This is already calculated correctly without division
                                    'base_price': product.price,
                                    'imageUrl': product.imageUrl,
                                    'quantity': _quantity,
                                    'modification': modificationsJson,
                                    'modification_details':
                                        selectedModsWithNames,
                                  };
                                } else if (hasRegularModifications &&
                                    product.selectedModification != null) {
                                  // Regular modification - use the existing structure
                                  cartItem = product.toCartItem();
                                  cartItem['quantity'] = _quantity;
                                } else {
                                  // Simple product without modifications
                                  cartItem = {
                                    'product_id': product.id,
                                    'name': product.name,
                                    'price': product.price,
                                    'imageUrl': product.imageUrl,
                                    'quantity': _quantity,
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // For group modifications with checkbox style (used for all types now)
  Widget _buildCheckboxModificationTile(
    ProductModification mod,
    bool isSelected,
    Function(bool) onChanged,
  ) {
    return InkWell(
      onTap: () {
        onChanged(!isSelected);
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
            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (value) => onChanged(value ?? false),
              activeColor: ColorUtils.accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Modification image if available
            if (mod.photoUrl != null && mod.photoUrl!.isNotEmpty)
              Container(
                width: 40,
                height: 40,
                margin: EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  image: DecorationImage(
                    image: NetworkImage(
                      "https://joinposter.com" + mod.photoUrl!,
                    ),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Fallback if image loading fails
                    },
                  ),
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
                "+${formatPrice(mod.price, subtract: false)}",
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

  // Keep the original tile for regular modifications (radio button style)
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
