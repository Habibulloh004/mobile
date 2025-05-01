// lib/models/spot_model.dart
import 'package:flutter/foundation.dart';

class SpotModel {
  final String id;
  final String name;
  final String address;
  final String? latitude;
  final String? longitude;
  final List<SpotStorage>? storages;

  SpotModel({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.storages,
  });

  factory SpotModel.fromJson(Map<String, dynamic> json) {
    List<SpotStorage>? storages;

    if (json['storages'] != null) {
      storages = List<SpotStorage>.from(
        (json['storages'] as List).map(
          (storage) => SpotStorage.fromJson(storage),
        ),
      );
    }

    return SpotModel(
      id: json['spot_id']?.toString() ?? '',
      name: json['spot_name']?.toString() ?? 'Неизвестная точка',
      address: json['spot_adress']?.toString() ?? '',
      latitude: json['lat']?.toString(),
      longitude: json['lng']?.toString(),
      storages: storages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spot_id': id,
      'spot_name': name,
      'spot_adress': address,
      'lat': latitude,
      'lng': longitude,
      'storages': storages?.map((storage) => storage.toJson()).toList(),
    };
  }
}

class SpotStorage {
  final int id;
  final String name;
  final String address;

  SpotStorage({required this.id, required this.name, required this.address});

  factory SpotStorage.fromJson(Map<String, dynamic> json) {
    return SpotStorage(
      id: int.tryParse(json['storage_id']?.toString() ?? '0') ?? 0,
      name: json['storage_name']?.toString() ?? '',
      address: json['storage_adress']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'storage_id': id, 'storage_name': name, 'storage_adress': address};
  }
}
