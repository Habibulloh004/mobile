import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../helpers/index.dart';
import '../models/product_model.dart';
import '../widgets/search_bar_widget.dart';
import 'product_detail_page.dart';
import 'cart_page.dart';
import 'search_page.dart';

class ProductPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const ProductPage({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage>
    with SingleTickerProviderStateMixin {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchResults = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(
        context,
        listen: false,
      ).loadProducts(widget.categoryId);
    });
  }

  void _onSearchChanged() {
    final newQuery = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = newQuery;
      _showSearchResults = newQuery.isNotEmpty;
    });

    if (newQuery.isEmpty) {
      _animationController.reverse();
    } else if (!_animationController.isCompleted) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorUtils.bodyColor,
      appBar: AppBar(
        backgroundColor: ColorUtils.bodyColor,
        elevation: 0,
        title: Text(
          widget.categoryName,
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
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Stack(
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
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBarWidget(
              controller: _searchController,
              onChanged: (value) => _onSearchChanged(),
              hintText: "Поиск по ${widget.categoryName.toLowerCase()}...",
              onClear: () {
                setState(() {
                  _searchQuery = '';
                  _showSearchResults = false;
                });
              },
            ),
          ),

          // Optional search results label with animation
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _animation,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Результаты поиска",
                        style: TextStyle(
                          fontSize: Constants.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: ColorUtils.secondaryColor,
                        ),
                      ),
                      Consumer<ProductProvider>(
                        builder: (context, productProvider, child) {
                          final filteredProducts =
                              productProvider.products.where((product) {
                                return product.name.toLowerCase().contains(
                                  _searchQuery,
                                );
                              }).toList();

                          return Text(
                            "Найдено: ${filteredProducts.length}",
                            style: TextStyle(
                              fontSize: Constants.fontSizeRegular,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorUtils.accentColor,
                      ),
                    ),
                  );
                }

                if (productProvider.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          productProvider.errorMessage,
                          style: TextStyle(
                            color: ColorUtils.errorColor,
                            fontSize: Constants.fontSizeMedium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => productProvider.refreshProducts(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorUtils.accentColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text("Повторить"),
                        ),
                      ],
                    ),
                  );
                }

                // Filter products based on search query
                final products =
                    productProvider.products.where((product) {
                      if (_searchQuery.isEmpty) return true;
                      return product.name.toLowerCase().contains(_searchQuery);
                    }).toList();

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty
                              ? Icons.category_outlined
                              : Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? "Нет доступных товаров в этой категории"
                              : "Товары не найдены",
                          style: TextStyle(
                            color: ColorUtils.secondaryColor,
                            fontSize: Constants.fontSizeMedium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Попробуйте изменить параметры поиска',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: Constants.fontSizeRegular,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => productProvider.refreshProducts(),
                  color: ColorUtils.accentColor,
                  child: GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final cartProvider = Provider.of<CartProvider>(context);

                      // Check if this product is in the cart with the current selected modification
                      final String? modificationId =
                          product.selectedModification?.id;

                      // Look for this product with this modification in the cart
                      final cartItems =
                          cartProvider.cartItems.where((item) {
                            if (item['product_id'] != product.id) return false;

                            // Check modification match
                            final bool itemHasModification =
                                item.containsKey('modification') &&
                                item['modification'] != null;
                            final String? itemModificationId =
                                itemHasModification
                                    ? item['modification']['id']?.toString()
                                    : null;

                            return modificationId == itemModificationId;
                          }).toList();

                      final int quantity =
                          cartItems.isNotEmpty
                              ? cartItems.first['quantity'] ?? 0
                              : 0;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      ProductDetailPage(productId: product.id),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Hero(
                                      tag: 'product_image_${product.id}',
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                        child: Image.network(
                                          product.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Image.asset(
                                              "assets/images/no_image.png",
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    // Show modification tag if product has modifications
                                    if (product.selectedModification != null)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ColorUtils.accentColor
                                                .withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            product.selectedModification!.name,
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
                              ),
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cleanProductName(product.name),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: Constants.fontSizeRegular,
                                        color: ColorUtils.secondaryColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      formatPrice(product.effectivePrice),
                                      style: TextStyle(
                                        color: ColorUtils.accentColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: Constants.fontSizeMedium,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child:
                                          quantity > 0
                                              ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      if (product
                                                              .selectedModification !=
                                                          null) {
                                                        cartProvider.updateQuantity(
                                                          product.id,
                                                          -1,
                                                          modificationId:
                                                              product
                                                                  .selectedModification!
                                                                  .id,
                                                        );
                                                      } else {
                                                        cartProvider
                                                            .updateQuantity(
                                                              product.id,
                                                              -1,
                                                            );
                                                      }
                                                    },
                                                    child: Container(
                                                      padding: EdgeInsets.all(
                                                        6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            ColorUtils
                                                                .primaryColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons.remove,
                                                        size: 16,
                                                        color:
                                                            ColorUtils
                                                                .secondaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          ColorUtils
                                                              .primaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      quantity.toString(),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            Constants
                                                                .fontSizeMedium,
                                                      ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      if (product
                                                              .selectedModification !=
                                                          null) {
                                                        cartProvider.updateQuantity(
                                                          product.id,
                                                          1,
                                                          modificationId:
                                                              product
                                                                  .selectedModification!
                                                                  .id,
                                                        );
                                                      } else {
                                                        cartProvider
                                                            .updateQuantity(
                                                              product.id,
                                                              1,
                                                            );
                                                      }
                                                    },
                                                    child: Container(
                                                      padding: EdgeInsets.all(
                                                        6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            ColorUtils
                                                                .primaryColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons.add,
                                                        size: 16,
                                                        color:
                                                            ColorUtils
                                                                .secondaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                              : OutlinedButton(
                                                onPressed: () {
                                                  // Check if product has modifications
                                                  if ((product.modifications !=
                                                              null &&
                                                          product
                                                              .modifications!
                                                              .isNotEmpty) ||
                                                      (product.groupModifications !=
                                                              null &&
                                                          product
                                                              .groupModifications!
                                                              .isNotEmpty)) {
                                                    // Navigate to product detail for selection
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                                ProductDetailPage(
                                                                  productId:
                                                                      product
                                                                          .id,
                                                                ),
                                                      ),
                                                    );
                                                  } else {
                                                    // Add directly to cart
                                                    cartProvider.addItem(
                                                      product.toCartItem(),
                                                    );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          "Товар добавлен в корзину",
                                                        ),
                                                        duration: Duration(
                                                          seconds: 1,
                                                        ),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                      ),
                                                    );
                                                  }
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 6,
                                                  ),
                                                  side: BorderSide(
                                                    color:
                                                        ColorUtils.accentColor,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  (product.modifications !=
                                                                  null &&
                                                              product
                                                                  .modifications!
                                                                  .isNotEmpty) ||
                                                          (product.groupModifications !=
                                                                  null &&
                                                              product
                                                                  .groupModifications!
                                                                  .isNotEmpty)
                                                      ? "Выбрать"
                                                      : "В корзину",
                                                  style: TextStyle(
                                                    color:
                                                        ColorUtils.accentColor,
                                                    fontSize:
                                                        Constants.fontSizeSmall,
                                                  ),
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
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
