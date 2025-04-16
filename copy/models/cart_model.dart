class CategoryModel {
  final int id;
  final String name;
  final String imageUrl;

  CategoryModel({required this.id, required this.name, required this.imageUrl});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: int.tryParse(json['category_id'].toString()) ?? 0, // ✅ Исправлен парсинг ID
      name: json['category_name'] ?? "Без названия",
      imageUrl: (json['category_photo'] != null && json['category_photo'].toString().isNotEmpty)
          ? "https://joinposter.com" + json['category_photo']
          : "assets/images/no_image.png",
    );
  }
}
