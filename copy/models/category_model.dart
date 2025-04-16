class CategoryModel {
  final int id;
  final String name;
  final String imageUrl;

  CategoryModel({required this.id, required this.name, required this.imageUrl});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    // ✅ Исправляем путь к фото
    String imagePath = json['category_photo'] ?? "";
    if (imagePath.isNotEmpty && !imagePath.startsWith("http")) {
      imagePath = "https://joinposter.com" + imagePath;
    }

    return CategoryModel(
      id: int.tryParse(json['category_id'].toString()) ?? 0,  // ✅ Исправлено
      name: json['category_name'] ?? "Без названия",
      imageUrl: imagePath.isNotEmpty ? imagePath : "assets/images/no_image.png", // ✅ Локальная заглушка
    );
  }
}
