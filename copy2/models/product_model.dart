import 'package:flutter/foundation.dart';  // ✅ Импортируем для использования debugPrint


class ProductModel {
  final int id;
  final String name;
  final int price;
  final String imageUrl;
  final String description;
  int quantity;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    this.quantity = 1,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // ✅ Логируем JSON продукта
    debugPrint("📦 Данные продукта перед парсингом: $json");

    // ✅ Получаем фото товара (если `null`, используем заглушку)
    String imagePath = json['photo'] ?? json['photo_origin'] ?? "";
    if (imagePath.isNotEmpty && !imagePath.startsWith("http")) {
      imagePath = "https://joinposter.com" + imagePath;
    }

    // ✅ Исправляем парсинг цены (если это Map)
    int parsedPrice = 0;
    if (json['price'] is Map && json['price'].isNotEmpty) {
      var firstPrice = json['price'].values.first; // Берем первое значение
      parsedPrice = int.tryParse(firstPrice.toString()) ?? 0;
    } else if (json['price'] is String) {
      parsedPrice = int.tryParse(json['price']) ?? 0;
    } else if (json['price'] is int) {
      parsedPrice = json['price'];
    }

    // ✅ Выводим конечные значения перед возвратом
    debugPrint("✅ Итоговый объект ProductModel: id=${json['product_id']}, name=${json['product_name']}, price=$parsedPrice, imageUrl=$imagePath");

    return ProductModel(
      id: int.tryParse(json['product_id'].toString()) ?? 0,
      name: json['product_name']?.trim() ?? "Без названия",
      price: parsedPrice,
      imageUrl: imagePath.isNotEmpty ? imagePath : "assets/images/no_image.png", // ✅ Заглушка
      description: json['description']?.trim() ?? "Описание отсутствует",
    );
  }
}
