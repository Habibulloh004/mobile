import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../widgets/search_bar_widget.dart';
import 'product_page.dart';
import 'cart_page.dart';

class CategoryPage extends StatefulWidget {
  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage>
    with SingleTickerProviderStateMixin {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
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

    _loadCategories();
  }

  void _onSearchChanged() {
    final newQuery = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = newQuery;
    });

    if (newQuery.isEmpty) {
      _animationController.reverse();
    } else if (!_animationController.isCompleted) {
      _animationController.forward();
    }
  }

  Future<void> _loadCategories() async {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    if (!categoryProvider.isLoading && categoryProvider.categories.isNotEmpty) {
      // Categories are already loaded
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await categoryProvider.loadCategories();

      // Ensure widget is still mounted before updating state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Ensure widget is still mounted before updating state
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load categories: $e';
        });
        print("Error loading categories: $e");
      }
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
          "Категории",
          style: TextStyle(
            color: ColorUtils.secondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shopping_cart,
                      size: 28,
                      color: ColorUtils.secondaryColor,
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
              hintText: "Поиск категорий...",
              onClear: () {
                setState(() {
                  _searchQuery = '';
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
                child: Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    final filteredCategories =
                        categoryProvider.categories.where((category) {
                          return category.name.toLowerCase().contains(
                            _searchQuery,
                          );
                        }).toList();

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                          Text(
                            "Найдено: ${filteredCategories.length}",
                            style: TextStyle(
                              fontSize: Constants.fontSizeRegular,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),

          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ColorUtils.accentColor,
                        ),
                      ),
                    )
                    : _hasError
                    ? _buildErrorView()
                    : _buildCategoriesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: ColorUtils.errorColor),
          SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(color: ColorUtils.errorColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCategories,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorUtils.accentColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (categoryProvider.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              "Нет доступных категорий",
              style: TextStyle(
                fontSize: Constants.fontSizeMedium,
                color: ColorUtils.secondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    // Filter categories based on search query
    final filteredCategories =
        categoryProvider.categories.where((category) {
          if (_searchQuery.isEmpty) return true;
          return category.name.toLowerCase().contains(_searchQuery);
        }).toList();

    if (filteredCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              "Категории не найдены",
              style: TextStyle(
                fontSize: Constants.fontSizeMedium,
                color: ColorUtils.secondaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Попробуйте изменить параметры поиска",
              style: TextStyle(
                fontSize: Constants.fontSizeRegular,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      color: ColorUtils.accentColor,
      child: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: filteredCategories.length,
        itemBuilder: (context, index) {
          final category = filteredCategories[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ProductPage(
                        categoryId: category.id,
                        categoryName: category.name,
                      ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Category Card
                  Container(
                    decoration: BoxDecoration(
                      color: ColorUtils.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Hero(
                            tag: 'category_image_${category.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                child: Image.network(
                                  category.imageUrl,
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
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: Constants.fontSizeRegular,
                                    color: ColorUtils.secondaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Overlay for tappable effect
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ProductPage(
                                    categoryId: category.id,
                                    categoryName: category.name,
                                  ),
                            ),
                          );
                        },
                        splashColor: ColorUtils.accentColor.withOpacity(0.3),
                        highlightColor: Colors.transparent,
                      ),
                    ),
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
