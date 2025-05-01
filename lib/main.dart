import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:poster_app/providers/cart_provider.dart';
import 'package:poster_app/providers/category_provider.dart';
import 'package:poster_app/providers/product_provider.dart';
import 'package:poster_app/providers/search_provider.dart';
import 'package:poster_app/providers/banner_provider.dart';
import 'package:poster_app/providers/spot_provider.dart'; // Add this import
import 'package:poster_app/views/main_page.dart';
import 'package:poster_app/core/api_service.dart';
import 'package:poster_app/utils/color_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final ApiService apiService = ApiService();

  // Prefetch admin data if possible
  try {
    await apiService.fetchAdminData();
  } catch (e) {
    print("Initial admin data fetch failed: $e");
    // Continue app initialization even if initial fetch fails
  }

  final CartProvider cartProvider = CartProvider(apiService: apiService);
  final categoryProvider = CategoryProvider(apiService);
  final productProvider = ProductProvider(apiService);
  final searchProvider = SearchProvider(
    categoryProvider,
    productProvider,
    apiService,
  );
  final bannerProvider = BannerProvider(apiService);
  final spotProvider = SpotProvider(apiService);

  // Start loading data in background
  categoryProvider.loadCategories().catchError(
    (e) => print("Initial category data load failed: $e"),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider.value(value: categoryProvider),
        ChangeNotifierProvider.value(value: productProvider),
        ChangeNotifierProvider.value(value: cartProvider),
        ChangeNotifierProvider.value(value: searchProvider),
        ChangeNotifierProvider.value(value: bannerProvider),
        ChangeNotifierProvider.value(value: spotProvider), // Add this line
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Foodery",
      theme: ThemeData(
        primaryColor: ColorUtils.accentColor,
        scaffoldBackgroundColor: ColorUtils.bodyColor,
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: ColorUtils.bodyColor,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: ColorUtils.secondaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          iconTheme: IconThemeData(color: ColorUtils.secondaryColor),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorUtils.buttonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorUtils.accentColor,
            side: BorderSide(color: ColorUtils.accentColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: ColorUtils.accentColor),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: ColorUtils.accentColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: ColorUtils.primaryColor,
          selectedColor: ColorUtils.accentColor.withOpacity(0.2),
          disabledColor: Colors.grey[300],
          labelStyle: TextStyle(color: ColorUtils.secondaryColor),
          secondaryLabelStyle: TextStyle(color: Colors.white),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: MainPage(),
    );
  }
}
