import 'package:flutter/foundation.dart';
import '../helpers/index.dart';

class ProductModification {
  final String id;
  final String name;
  final int price;

  ProductModification({
    required this.id,
    required this.name,
    required this.price,
  });

  factory ProductModification.fromJson(Map<String, dynamic> json) {
    return ProductModification(
      id: json['modificator_id']?.toString() ?? '',
      name: json['modificator_name']?.toString() ?? '',
      price: int.tryParse(json['modificator_selfprice']?.toString() ?? '0') ?? 0,
    );
  }
}

class ProductModel {
  final int id;
  final String name;
  final int price;
  final String imageUrl;
  final String description;
  int quantity;
  final List<ProductModification>? modifications;
  final bool isAvailable;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    this.quantity = 1,
    this.modifications,
    this.isAvailable = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Log JSON product data for debugging
    debugPrint("📦 Parsing product data: ${json['product_id']} - ${json['product_name']}");

    // Clean product name (remove anything after $ if present)
    final cleanedName = cleanProductName(json['product_name'] ?? "Без названия");

    // Get image URL using the helper function
    final imageUrl = getImageUrl(json['photo'], json['photo_origin']);

    // Extract price using the helper function
    final price = extractPrice(json['price']);

    // Check if the product is out of stock
    final bool isAvailable = json['out'] == 0;

    // Parse modifications if available
    List<ProductModification>? modifications;
    if (json['modifications'] != null) {
      modifications = (json['modifications'] as List)
          .map((mod) => ProductModification.fromJson(mod))
          .toList();
      debugPrint("🧩 Found ${modifications.length} modifications for product ${json['product_id']}");
    }

    return ProductModel(
      id: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      name: cleanedName,
      price: price,
      imageUrl: imageUrl,
      description: json['description']?.toString().trim() ?? "Описание отсутствует",
      modifications: modifications,
      isAvailable: isAvailable,
    );
  }

  // Convert to a map for cart storage
  Map<String, dynamic> toCartItem() {
    return {
      'product_id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'isAvailable': isAvailable,
    };
  }
}