// lib/views/main_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/category_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/banner_provider.dart'; // Add this import
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../helpers/index.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/banner_slider.dart'; // Add this import
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
    CategoryPage(fromBottomNav: true),
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
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAnimatedNavItem(0, 'assets/images/home.svg'),
            _buildAnimatedNavItem(1, 'assets/images/menu.svg'),
            _buildAnimatedNavItem(2, 'assets/images/user.svg'),
            _buildAnimatedNavItem(3, 'assets/images/cart.svg'),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedNavItem(int index, String iconPath) {
    bool isSelected = _selectedIndex == index;

    // Special case for cart to show badge
    Widget navIcon =
        index == 3
            ? Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  iconPath,
                  color:
                      isSelected
                          ? ColorUtils.accentColor
                          : ColorUtils.secondaryColor,
                  width: 24,
                  height: 24,
                ),
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    if (cartProvider.cartItems.isEmpty)
                      return SizedBox.shrink();
                    return Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cartProvider.itemCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            )
            : SvgPicture.asset(
              iconPath,
              color:
                  isSelected
                      ? ColorUtils.accentColor
                      : ColorUtils.secondaryColor,
              width: 24,
              height: 24,
            );

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: MediaQuery.of(context).size.width / 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            navIcon,
            SizedBox(height: 6),
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 2,
              width: isSelected ? 30 : 0,
              decoration: BoxDecoration(
                color: ColorUtils.accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
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
          icon: SvgPicture.asset(
            'assets/images/hambur.svg',
            color: ColorUtils.secondaryColor, // Optional colorization
            width: 24,
            height: 24,
          ),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        title: SvgPicture.asset(
          'assets/images/appLogo.svg',
          width: 30,
          height: 30, // Optional colorization
          fit: BoxFit.cover,
        ),
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/images/cart.svg',
                      color: ColorUtils.secondaryColor, // Optional colorization
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
                      // In lib/views/main_page.dart
                      // Find the GridView.builder in the _buildCategoriesGrid method or in the HomeScreen class
                      // and update the crossAxisCount from 2 to 3
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          // Changed from 2 to 3
                          crossAxisSpacing: 12,
                          // Reduced spacing to accommodate more columns
                          mainAxisSpacing: 12,
                          // Reduced spacing to accommodate more columns
                          childAspectRatio:
                              0.7, // Adjusted aspect ratio for smaller tiles
                        ),
                        itemCount:
                            _searchQuery.isEmpty &&
                                    filteredCategories.length > 6
                                ? 6 // Increased from 4 to 6 to show two rows of categories
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
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Category Card
                                  Container(
                                    decoration: BoxDecoration(
                                      color: ColorUtils.primaryColor,
                                      borderRadius: BorderRadius.circular(12),
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
                                                    top: Radius.circular(12),
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
                                              horizontal: 8,
                                              // Reduced padding for smaller tiles
                                              vertical:
                                                  4, // Reduced padding for smaller tiles
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    bottom: Radius.circular(12),
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
                                                        Constants.fontSizeSmall,
                                                    // Smaller font for 3 columns
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
                                        borderRadius: BorderRadius.circular(12),
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
                    // This is a partial update focusing only on the "More categories" button
                    // in the HomeScreen class of MainPage.dart

                    // Find the "More categories" button in the GridView section and update it like this:
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
                                  builder:
                                      (context) =>
                                          CategoryPage(fromBottomNav: false),
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

                    // Banner Slider - Added here
                    Consumer<BannerProvider>(
                      builder: (context, bannerProvider, child) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: BannerSlider(),
                        );
                      },
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
