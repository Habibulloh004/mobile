// lib/models/product_model.dart - Updated with correct price extraction

import 'package:flutter/foundation.dart';
import 'package:poster_app/helpers/index.dart';

class GroupModification {
  final int id;
  final String name;
  final int minQuantity;
  final int maxQuantity;
  final int type;
  final List<ProductModification> modifications;

  GroupModification({
    required this.id,
    required this.name,
    required this.minQuantity,
    required this.maxQuantity,
    required this.type,
    required this.modifications,
  });

  factory GroupModification.fromJson(Map<String, dynamic> json) {
    List<ProductModification> mods = [];
    if (json['modifications'] != null) {
      mods =
          (json['modifications'] as List)
              .map((mod) => ProductModification.fromJson(mod))
              .toList();
    }

    return GroupModification(
      id:
          int.tryParse(json['dish_modification_group_id']?.toString() ?? '0') ??
          0,
      name: json['name'] ?? '',
      minQuantity: int.tryParse(json['num_min']?.toString() ?? '0') ?? 0,
      maxQuantity: int.tryParse(json['num_max']?.toString() ?? '0') ?? 0,
      type: int.tryParse(json['type']?.toString() ?? '0') ?? 0,
      modifications: mods,
    );
  }
}

class ProductModification {
  final String id;
  final String name;
  final int price;
  final String? photoUrl;

  ProductModification({
    required this.id,
    required this.name,
    required this.price,
    this.photoUrl,
  });

  factory ProductModification.fromJson(Map<String, dynamic> json) {
    // Determine if this is a group modification
    bool isGroupMod = isGroupModification(json);

    // Debug log
    debugPrint(
      '🔍 Parsing modification: ${json['name'] ?? json['modificator_name']}, isGroupMod: $isGroupMod',
    );

    // Check if using the old or new format
    if (json.containsKey('modificator_id')) {
      // Process price based on the value type
      final dynamic rawPrice = json['modificator_selfprice'];
      int price = parsePrice(rawPrice);

      return ProductModification(
        id: json['modificator_id']?.toString() ?? '',
        name: json['modificator_name']?.toString() ?? '',
        price: price,
        photoUrl: null,
      );
    } else {
      // New format from group_modifications
      String? photoUrl;

      // Handle both photo_large and photo_small fields
      if (json['photo_large'] != null &&
          json['photo_large'].toString().isNotEmpty) {
        photoUrl = json['photo_large'];
      } else if (json['photo_small'] != null &&
          json['photo_small'].toString().isNotEmpty) {
        photoUrl = json['photo_small'];
      }

      // Process price based on the value type
      int price = parsePrice(json['price']);

      return ProductModification(
        id: json['dish_modification_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        price: price,
        photoUrl: photoUrl,
      );
    }
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
  final List<GroupModification>? groupModifications;
  final bool isAvailable;
  ProductModification? selectedModification;

  // Map to track selected group modifications
  Map<String, bool> selectedGroupModifications = {};

  // Effective price that accounts for selected modification
  int get effectivePrice {
    int totalPrice = price;

    // Add price for regular modifications
    if (selectedModification != null) {
      totalPrice += selectedModification!.price;
      debugPrint(
        '💰 With regular mod: +${selectedModification!.price} = $totalPrice',
      );
    }

    return totalPrice;
  }

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    this.quantity = 1,
    this.modifications,
    this.groupModifications,
    this.isAvailable = true,
    this.selectedModification,
  }) {
    // Initialize selected group modifications map
    if (groupModifications != null) {
      for (var group in groupModifications!) {
        for (var mod in group.modifications) {
          selectedGroupModifications[mod.id] = false;
        }
      }
    }
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Clean product name (remove anything after $ if present)
    final cleanedName = cleanProductName(
      json['product_name'] ?? "Без названия",
    );

    // Get image URL using the helper function
    final imageUrl = getImageUrl(json['photo'], json['photo_origin']);

    // Log the original price before extraction for debugging
    debugPrint('📊 Product price before extraction: ${json['price']}');

    // Extract price using the parsePrice helper function
    final price = parsePrice(json['price']);

    // Log the extracted price
    debugPrint('📊 Product price after extraction: $price');

    // Check if the product is out of stock
    final bool isAvailable =
        json['out'] != 248; // 248 seems to indicate out of stock in your system

    // Parse old-style modifications if available
    List<ProductModification>? modifications;
    if (json['modifications'] != null) {
      modifications =
          (json['modifications'] as List)
              .map((mod) => ProductModification.fromJson(mod))
              .toList();
    }

    // Parse new group_modifications if available
    List<GroupModification>? groupModifications;
    if (json['group_modifications'] != null) {
      groupModifications =
          (json['group_modifications'] as List)
              .map((group) => GroupModification.fromJson(group))
              .toList();
    }

    // Create the product model
    final product = ProductModel(
      id: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      name: cleanedName,
      price: price,
      imageUrl: imageUrl,
      description:
          json['product_production_description']?.toString().trim() ??
          "Описание отсутствует",
      modifications: modifications,
      groupModifications: groupModifications,
      isAvailable: isAvailable,
    );

    // Pre-select the first modification for regular modifications only
    if (product.modifications != null && product.modifications!.isNotEmpty) {
      product.selectedModification = product.modifications!.first;
    }

    return product;
  }

  // Convert to a map for cart storage
  Map<String, dynamic> toCartItem() {
    // Create the base cart item
    Map<String, dynamic> cartItem = {
      'product_id': id,
      'name': name,
      'price': effectivePrice,
      'base_price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'isAvailable': isAvailable,
    };

    // Add the selected modification if available
    if (selectedModification != null) {
      cartItem['modification'] = {
        'id': selectedModification!.id,
        'name': selectedModification!.name,
        'price': selectedModification!.price,
        'photoUrl': selectedModification!.photoUrl,
      };
    }

    return cartItem;
  }

  // Create a unique key for this product + modification combination
  String get uniqueKey {
    if (selectedModification != null) {
      return '${id}_${selectedModification!.id}';
    }
    return id.toString();
  }

  // Helper method to get all available modifications from both sources
  List<ProductModification> getAllModifications() {
    List<ProductModification> allMods = [];

    // Add regular modifications if any
    if (modifications != null) {
      allMods.addAll(modifications!);
    }

    // Add modifications from group modifications if any
    if (groupModifications != null) {
      for (var group in groupModifications!) {
        allMods.addAll(group.modifications);
      }
    }

    return allMods;
  }
}
