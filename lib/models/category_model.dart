import '../helpers/index.dart';

class CategoryModel {
  final int id;
  final String name;
  final String imageUrl;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    // Try to get the photo_origin first, fall back to category_photo
    final imageUrl = getImageUrl(json['category_photo'], json['category_photo_origin']);

    return CategoryModel(
      id: int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      name: json['category_name']?.toString() ?? "Без названия",
      imageUrl: imageUrl,
    );
  }
}