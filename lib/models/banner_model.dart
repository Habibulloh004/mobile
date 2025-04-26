// lib/models/banner_model.dart
class BannerModel {
  final int id;
  final int adminId;
  final String image;
  final String title;
  final String body;
  final String createdAt;
  final String updatedAt;

  BannerModel({
    required this.id,
    required this.adminId,
    required this.image,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      adminId: json['admin_id'],
      image: json['image'],
      title: json['title'],
      body: json['body'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'image': image,
      'title': title,
      'body': body,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
