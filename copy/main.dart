import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poster_app/providers/cart_provider.dart';
import 'package:poster_app/providers/category_provider.dart';
import 'package:poster_app/providers/product_provider.dart';
import 'package:poster_app/views/main_page.dart';

final String posterApiToken = "967898:49355888e8e490af3bcca79c5e6b1abf";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final CartProvider cartProvider = CartProvider(); // ✅ Исправлено

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider(posterApiToken)..loadCategories()),
        ChangeNotifierProvider(create: (_) => ProductProvider(posterApiToken)),
        ChangeNotifierProvider(create: (_) => cartProvider),
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
