// lib/models/restaurant_info_model.dart
class RestaurantInfoModel {
  final int id;
  final int adminId;
  final String text;
  final ContactsModel? contacts;
  final SocialMediaModel? socialMedia;
  final String createdAt;
  final String updatedAt;

  RestaurantInfoModel({
    required this.id,
    required this.adminId,
    required this.text,
    this.contacts,
    this.socialMedia,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RestaurantInfoModel.fromJson(Map<String, dynamic> json) {
    return RestaurantInfoModel(
      id: json['id'] ?? 0,
      adminId: json['admin_id'] ?? 0,
      text: json['text'] ?? '',
      contacts:
          json['contacts'] != null
              ? ContactsModel.fromJson(json['contacts'])
              : null,
      socialMedia:
          json['social_media'] != null
              ? SocialMediaModel.fromJson(json['social_media'])
              : null,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'text': text,
      'contacts': contacts?.toJson(),
      'social_media': socialMedia?.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class ContactsModel {
  final String? phone;
  final String? gmail;
  final String? location;

  ContactsModel({this.phone, this.gmail, this.location});

  factory ContactsModel.fromJson(Map<String, dynamic> json) {
    return ContactsModel(
      phone: json['phone'],
      gmail: json['gmail'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'gmail': gmail, 'location': location};
  }

  // Helper method to check if any contact information is available
  bool get hasAnyContact {
    return (phone != null && phone!.isNotEmpty) ||
        (gmail != null && gmail!.isNotEmpty) ||
        (location != null && location!.isNotEmpty);
  }
}

class SocialMediaModel {
  final String? instagram;
  final String? telegram;
  final String? facebook;

  SocialMediaModel({this.instagram, this.telegram, this.facebook});

  factory SocialMediaModel.fromJson(Map<String, dynamic> json) {
    return SocialMediaModel(
      instagram: json['instagram'],
      telegram: json['telegram'],
      facebook: json['facebook'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'instagram': instagram, 'telegram': telegram, 'facebook': facebook};
  }

  // Helper method to check if any social media information is available
  bool get hasAnySocialMedia {
    return (instagram != null && instagram!.isNotEmpty) ||
        (telegram != null && telegram!.isNotEmpty) ||
        (facebook != null && facebook!.isNotEmpty);
  }
}
