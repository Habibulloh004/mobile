// lib/views/cart_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:poster_app/core/api_service.dart';
import 'package:poster_app/providers/spot_provider.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../helpers/index.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Removed _loadingDeliveryFee flag since we don't need it anymore

  @override
  void initState() {
    super.initState();
    // Force delivery fee loading on page open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureDeliveryFeeLoaded();
      _debugAdminData();
    });
  }

  Future<void> _debugAdminData() async {
    debugPrint('🔍 DEBUG: Starting admin data debug');

    try {
      // Access the API service through the cart provider
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final apiService = ApiService(); // Create a direct instance for debugging

      // Debug the admin data directly
      final adminData = await apiService.fetchAdminData();
      debugPrint('📋 DEBUG: Raw admin data: $adminData');

      // Check if delivery field exists and its value
      if (adminData.containsKey('delivery')) {
        debugPrint('💰 DEBUG: Raw delivery value from admin: ${adminData['delivery']} (${adminData['delivery'].runtimeType})');
      } else {
        debugPrint('❌ DEBUG: No delivery field found in admin data!');
      }

      // Debug the getDeliveryFee method
      final deliveryFee = await apiService.getDeliveryFee();
      debugPrint('🚚 DEBUG: getDeliveryFee result: $deliveryFee');

      // Debug the cart provider's delivery fee
      debugPrint('🛒 DEBUG: CartProvider delivery fee: ${cartProvider.deliveryFee}');

      // Force a refresh of the delivery fee and check again
      await cartProvider.refreshDeliveryFee();
      debugPrint('🔄 DEBUG: After refresh - CartProvider delivery fee: ${cartProvider.deliveryFee}');

      // Check if isDelivery is correctly set
      debugPrint('📦 DEBUG: isDelivery flag: ${cartProvider.isDelivery}');

      setState(() {
        // Force UI update
      });
    } catch (e) {
      debugPrint('❌ DEBUG ERROR: $e');
    }
  }

  // Simplified method to ensure delivery fee is loaded
  Future<void> _ensureDeliveryFeeLoaded() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    // Just refresh the delivery fee without any loading indicators
    await cartProvider.refreshDeliveryFee();
    // Debug log the delivery fee after loading
    debugPrint(
      '📦 Cart page: Delivery fee loaded: ${cartProvider.deliveryFee}',
    );
  }

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
    // When delivery type changes, load spots if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!cartProvider.isDelivery) {
        final spotProvider = Provider.of<SpotProvider>(context, listen: false);
        spotProvider.loadSpots();
      }
    });

    return Column(
      children: [
        // Delivery method selector
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (!cartProvider.isDelivery) {
                      Provider.of<SpotProvider>(
                        context,
                        listen: false,
                      ).resetSelection();
                      cartProvider.setDeliveryMethod(true);
                      // Force refresh delivery fee when switching to delivery
                      _ensureDeliveryFeeLoaded();
                    }
                  },
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
                  onPressed: () {
                    if (cartProvider.isDelivery) {
                      Provider.of<SpotProvider>(
                        context,
                        listen: false,
                      ).loadSpots();
                      cartProvider.setDeliveryMethod(false);
                    }
                  },
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

              // Delivery fee (if applicable) - Remove loading indicator
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
                      // Show delivery fee directly without loader
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
                  onPressed: () async {
                    // Ensure delivery fee is loaded before proceeding to checkout
                    if (cartProvider.isDelivery) {
                      await cartProvider.prepareForCheckout();
                    }
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
    // Determine modification type
    bool hasRegularModification =
        item.containsKey('modification') &&
        item['modification'] is Map &&
        item['modification'] != null;

    bool hasGroupModifications =
        item.containsKey('modification') &&
        item['modification'] is String &&
        item['modification'].toString().isNotEmpty;

    bool hasModificationDetails =
        item.containsKey('modification_details') &&
        item['modification_details'] is List;

    // Extract modification details
    final modificationName =
        hasRegularModification ? item['modification']['name'] : null;
    final modificationPrice =
        hasRegularModification ? (item['modification']['price'] ?? 0) : 0;
    final modificationId =
        hasRegularModification ? item['modification']['id'] : null;

    // Parse group modifications
    List<Map<String, dynamic>> groupModifications = [];
    if (hasModificationDetails) {
      groupModifications = List<Map<String, dynamic>>.from(
        item['modification_details'],
      );
    } else if (hasGroupModifications) {
      try {
        // Fallback for old format without names
        final List<dynamic> mods = jsonDecode(item['modification']);
        if (mods.isNotEmpty) {
          groupModifications = List<Map<String, dynamic>>.from(mods);
        }
      } catch (e) {
        debugPrint("Error parsing group modifications: $e");
      }
    }

    // Extract price and quantity
    final price = item['price'] ?? 0;
    final basePrice = item['base_price'] ?? price;
    final quantity = item['quantity'] ?? 1;
    final totalPrice = price * quantity;

    // Get clean product display name
    String displayName = cleanProductName(item['name'] ?? 'Unknown Product');

    // Helper method for quantity buttons
    Widget _buildQuantityButton({
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(8),
          child: Icon(icon, size: 16, color: ColorUtils.secondaryColor),
        ),
      );
    }

    // Helper method to remove a specific modification
    void _removeModification(String modId) {
      if (!hasGroupModifications || !hasModificationDetails) return;

      try {
        // Get the current modifications
        List<dynamic> currentMods = jsonDecode(item['modification']);
        List<Map<String, dynamic>> currentModDetails =
            List<Map<String, dynamic>>.from(item['modification_details']);

        // Filter out the modification to remove
        currentMods =
            currentMods
                .where((mod) => mod['m'].toString() != modId.toString())
                .toList();
        currentModDetails =
            currentModDetails
                .where((mod) => mod['m'].toString() != modId.toString())
                .toList();

        // Create updated cart item
        Map<String, dynamic> updatedItem = Map<String, dynamic>.from(item);
        updatedItem['modification'] = jsonEncode(currentMods);
        updatedItem['modification_details'] = currentModDetails;

        // Recalculate price (subtract the price of the removed modification)
        int modificationPrice = 0;
        for (var mod in groupModifications) {
          if (mod['m'].toString() == modId.toString()) {
            modificationPrice = mod['price'] ?? 0;
            break;
          }
        }

        updatedItem['price'] = (price - modificationPrice);

        // Remove old item and add updated one
        cartProvider.removeItem(item);
        if (currentMods.isNotEmpty) {
          cartProvider.addItem(updatedItem);
        } else {
          // If no modifications left, reset to base product
          updatedItem.remove('modification');
          updatedItem.remove('modification_details');
          updatedItem['price'] = updatedItem['base_price'];
          cartProvider.addItem(updatedItem);
        }
      } catch (e) {
        debugPrint("Error removing modification: $e");
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main item content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image - always use consistent corner radius
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(
                    groupModifications.isEmpty ? 12 : 0,
                  ),
                ),
                child: Container(
                  width: 100,
                  height: 100,
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
                      // Product name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontSize: Constants.fontSizeRegular,
                                fontWeight: FontWeight.bold,
                                color: ColorUtils.secondaryColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Additions badge for group modifications
                          if (hasGroupModifications || hasModificationDetails)
                            Padding(
                              padding: EdgeInsets.only(left: 6, top: 2),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorUtils.primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: ColorUtils.secondaryColor
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Добавки',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: ColorUtils.secondaryColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Price display with total if quantity > 1
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: Constants.fontSizeRegular,
                            color: ColorUtils.accentColor,
                          ),
                          children: [
                            TextSpan(
                              text: formatPrice(totalPrice),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (quantity > 1)
                              TextSpan(
                                text: '  (${formatPrice(price)} × $quantity)',
                                style: TextStyle(
                                  fontSize: Constants.fontSizeSmall,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: 12),

                      // Quantity controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Quantity label
                          Text(
                            'Кол-во:',
                            style: TextStyle(
                              fontSize: Constants.fontSizeSmall,
                              color: Colors.grey[600],
                            ),
                          ),

                          // Quantity control buttons
                          Container(
                            decoration: BoxDecoration(
                              color: ColorUtils.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                _buildQuantityButton(
                                  icon: Icons.remove,
                                  onTap: () {
                                    if (hasRegularModification) {
                                      cartProvider.updateQuantity(
                                        item['product_id'],
                                        -1,
                                        modificationId: modificationId,
                                      );
                                    } else if (hasGroupModifications) {
                                      cartProvider.updateQuantity(
                                        item['product_id'],
                                        -1,
                                        groupModifications:
                                            item['modification'],
                                      );
                                    } else {
                                      cartProvider.updateQuantity(
                                        item['product_id'],
                                        -1,
                                      );
                                    }
                                  },
                                ),
                                Container(
                                  width: 36,
                                  alignment: Alignment.center,
                                  child: Text(
                                    quantity.toString(),
                                    style: TextStyle(
                                      fontSize: Constants.fontSizeMedium,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _buildQuantityButton(
                                  icon: Icons.add,
                                  onTap: () {
                                    if (hasRegularModification) {
                                      cartProvider.updateQuantity(
                                        item['product_id'],
                                        1,
                                        modificationId: modificationId,
                                      );
                                    } else if (hasGroupModifications) {
                                      cartProvider.updateQuantity(
                                        item['product_id'],
                                        1,
                                        groupModifications:
                                            item['modification'],
                                      );
                                    } else {
                                      cartProvider.updateQuantity(
                                        item['product_id'],
                                        1,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Remove button
              InkWell(
                onTap: () {
                  cartProvider.removeItem(item);
                },
                borderRadius: BorderRadius.only(topRight: Radius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.close, color: Colors.grey[400], size: 20),
                ),
              ),
            ],
          ),

          // Group Modifications info section (if available)
          if (groupModifications.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: ColorUtils.primaryColor.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Добавки:',
                    style: TextStyle(
                      fontSize: Constants.fontSizeSmall,
                      fontWeight: FontWeight.bold,
                      color: ColorUtils.secondaryColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    // Show ALL group modifications
                    children:
                        groupModifications.map((mod) {
                          // Display name if available, otherwise show ID
                          String displayText =
                              mod.containsKey("name")
                                  ? mod["name"]
                                  : "ID: ${mod["m"]}";
                          int? price =
                              mod.containsKey("price") ? mod["price"] : null;
                          String modId = mod["m"].toString();

                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: ColorUtils.accentColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ColorUtils.secondaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Show price if available
                                if (price != null && price > 0)
                                  Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Text(
                                      '+${formatPrice(price)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: ColorUtils.accentColor,
                                      ),
                                    ),
                                  ),
                                // Remove modification button
                                InkWell(
                                  onTap: () => _removeModification(modId),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.red[300],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
