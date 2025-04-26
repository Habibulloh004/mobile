// In product_model.dart, first add new classes for group modifications

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

// Then update the ProductModification class to work with the new format
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
    // Check if using the old or new format
    if (json.containsKey('modificator_id')) {
      // Old format
      return ProductModification(
        id: json['modificator_id']?.toString() ?? '',
        name: json['modificator_name']?.toString() ?? '',
        price:
            int.tryParse(json['modificator_selfprice']?.toString() ?? '0') ?? 0,
        photoUrl: null,
      );
    } else {
      // New format from group_modifications
      return ProductModification(
        id: json['dish_modification_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        price: int.tryParse(json['price']?.toString() ?? '0') ?? 0,
        photoUrl: json['photo_large'],
      );
    }
  }
}

// Update the ProductModel class to include group modifications
class ProductModel {
  final int id;
  final String name;
  final int price;
  final String imageUrl;
  final String description;
  int quantity;
  final List<ProductModification>?
  modifications; // Kept for backward compatibility
  final List<GroupModification>? groupModifications; // Added for new format
  final bool isAvailable;
  ProductModification? selectedModification;

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
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Log JSON product data for debugging
    // debugPrint(
    //   "📦 Parsing product data: ${json['product_id']} - ${json['product_name']}",
    // );

    // Clean product name (remove anything after $ if present)
    final cleanedName = cleanProductName(
      json['product_name'] ?? "Без названия",
    );

    // Get image URL using the helper function
    final imageUrl = getImageUrl(json['photo'], json['photo_origin']);

    // Extract price using the helper function
    final price = extractPrice(json['price']);

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
      // debugPrint(
      //   "🧩 Found ${modifications.length} modifications for product ${json['product_id']}",
      // );
    }

    // Parse new group_modifications if available
    List<GroupModification>? groupModifications;
    if (json['group_modifications'] != null) {
      groupModifications =
          (json['group_modifications'] as List)
              .map((group) => GroupModification.fromJson(group))
              .toList();
      // debugPrint(
      //   "🧩 Found ${groupModifications.length} group modifications for product ${json['product_id']}",
      // );
    }

    return ProductModel(
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
  }

  // Convert to a map for cart storage
  Map<String, dynamic> toCartItem() {
    // Create the base cart item
    Map<String, dynamic> cartItem = {
      'product_id': id,
      'name': name,
      'price': price,
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

      // If the modification has a price, add it to the product price
      if (selectedModification!.price > 0) {
        cartItem['original_price'] =
            price; // Store original price for reference
        cartItem['price'] =
            price +
            selectedModification!.price; // Update price with modification
      }
    }

    return cartItem;
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
