import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poster_app/providers/cart_provider.dart';
import 'package:poster_app/providers/category_provider.dart';
import 'package:poster_app/providers/product_provider.dart';
import 'package:poster_app/views/main_page.dart';
import 'package:poster_app/core/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final CartProvider cartProvider = CartProvider();
  final ApiService apiService = ApiService();

  // Prefetch admin data if possible
  try {
    await apiService.fetchAdminData();
  } catch (e) {
    print("Initial admin data fetch failed: $e");
    // Continue app initialization even if initial fetch fails
  }

  final categoryProvider = CategoryProvider(apiService);
  final productProvider = ProductProvider(apiService);

  // Start loading data in background
  categoryProvider.loadCategories().catchError((e) =>
      print("Initial category data load failed: $e"));

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider.value(value: categoryProvider),
        ChangeNotifierProvider.value(value: productProvider),
        ChangeNotifierProvider.value(value: cartProvider),
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
      title: "FooDery",
      home: MainPage(),
    );
  }
}