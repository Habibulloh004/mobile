import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/category_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../helpers/index.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/app_sidebar.dart';
import 'cart_page.dart';
import 'product_page.dart';
import 'category_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'search_page.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Widget> _pages = [
    HomeScreen(),
    CategoryPage(),
    Container(), // Profile (will be handled in onItemTapped)
    Container(), // Cart (will be handled in onItemTapped)
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Ensure categories are loaded when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _onItemTapped(int index) async {
    if (index == 2) {
      // Profile
      final prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => isLoggedIn ? ProfilePage() : LoginPage(),
        ),
      );
    } else if (index == 3) {
      // Cart
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CartPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ColorUtils.bodyColor,
      drawer: AppSidebar(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex < 2 ? _selectedIndex : 0,
        // Keep active index within visible items
        onTap: _onItemTapped,
        selectedItemColor: ColorUtils.accentColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Главная",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: "Категории",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Профиль",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.shopping_cart_outlined),
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    if (cartProvider.cartItems.isEmpty)
                      return SizedBox.shrink();
                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          cartProvider.itemCount.toString(),
                          style: TextStyle(color: Colors.white, fontSize: 8),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            activeIcon: Stack(
              children: [
                Icon(Icons.shopping_cart),
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    if (cartProvider.cartItems.isEmpty)
                      return SizedBox.shrink();
                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          cartProvider.itemCount.toString(),
                          style: TextStyle(color: Colors.white, fontSize: 8),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            label: "Корзина",
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorUtils.bodyColor,
      appBar: AppBar(
        backgroundColor: ColorUtils.bodyColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: ColorUtils.secondaryColor),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: "Foo",
                style: TextStyle(
                  color: ColorUtils.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: Constants.fontSizeXLarge,
                ),
              ),
              TextSpan(
                text: "dery",
                style: TextStyle(
                  color: ColorUtils.secondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: Constants.fontSizeXLarge,
                ),
              ),
            ],
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
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          if (categoryProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  ColorUtils.accentColor,
                ),
              ),
            );
          }

          if (categoryProvider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: ColorUtils.errorColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Ошибка загрузки категорий",
                    style: TextStyle(
                      color: ColorUtils.errorColor,
                      fontSize: Constants.fontSizeMedium,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => categoryProvider.loadCategories(),
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

          if (categoryProvider.categories.isEmpty) {
            return Center(
              child: Text(
                "Нет доступных категорий",
                style: TextStyle(
                  color: ColorUtils.secondaryColor,
                  fontSize: Constants.fontSizeMedium,
                ),
              ),
            );
          }

          // Filter categories based on search query
          final filteredCategories =
              categoryProvider.categories.where((category) {
                if (_searchQuery.isEmpty) return true;
                return category.name.toLowerCase().contains(_searchQuery);
              }).toList();

          return RefreshIndicator(
            onRefresh: () => categoryProvider.refreshCategories(),
            color: ColorUtils.accentColor,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchPage(),
                            ),
                          );
                        },
                        child: AbsorbPointer(
                          child: SearchBarWidget(
                            controller: _searchController,
                            onChanged: (query) => _onSearchChanged(),
                            hintText: "Поиск...",
                            onClear: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    // Search results or categories title
                    Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _searchQuery.isEmpty
                                ? "Категории"
                                : "Результаты поиска",
                            style: TextStyle(
                              fontSize: Constants.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: ColorUtils.secondaryColor,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            Text(
                              "Найдено: ${filteredCategories.length}",
                              style: TextStyle(
                                fontSize: Constants.fontSizeRegular,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // No results message
                    if (_searchQuery.isNotEmpty && filteredCategories.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
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
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Categories grid
                    if (filteredCategories.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount:
                            _searchQuery.isEmpty &&
                                    filteredCategories.length > 4
                                ? 4 // Show only top 4 categories if not searching
                                : filteredCategories.length,
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
                                            tag:
                                                'category_image_${category.id}',
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(16),
                                                  ),
                                              child: Container(
                                                width: double.infinity,
                                                height: double.infinity,
                                                child: Image.network(
                                                  category.imageUrl,
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
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    bottom: Radius.circular(16),
                                                  ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  category.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        Constants
                                                            .fontSizeRegular,
                                                    color:
                                                        ColorUtils
                                                            .secondaryColor,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                        splashColor: ColorUtils.accentColor
                                            .withOpacity(0.3),
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

                    // "More categories" button when not searching
                    if (_searchQuery.isEmpty &&
                        categoryProvider.categories.length > 4)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorUtils.accentColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Больше категорий",
                              style: TextStyle(
                                fontSize: Constants.fontSizeRegular,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Banner
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 20),
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          "assets/images/banner.png",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                "POSSIBLE GROUP",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: Constants.fontSizeLarge,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
