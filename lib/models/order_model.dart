// Updated OrderModel class with appliedBonus field in order_model.dart
class OrderModel {
  final String id; // String ID to match API usage
  final String date;
  final String status;
  final String deliveryType; // 'delivery' or 'pickup'
  final List<OrderItem> items;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final int? appliedBonus; // Add this field to store applied bonus
  final String? address;
  final String? comment;
  final String? spotId;
  final String? spotName;

  OrderModel({
    required this.id,
    required this.date,
    required this.status,
    required this.deliveryType,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.appliedBonus, // Make this optional but include it
    this.address,
    this.comment,
    this.spotId,
    this.spotName,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse items
    List<OrderItem> orderItems = [];
    if (json['items'] != null) {
      orderItems =
          (json['items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList();
    }

    // Convert values to int
    int subtotal = _parseIntValue(json['subtotal']);
    int deliveryFee = _parseIntValue(json['delivery_fee']);
    int total = _parseIntValue(json['total']);
    int? appliedBonus =
        json['applied_bonus'] != null
            ? _parseIntValue(json['applied_bonus'])
            : null;

    return OrderModel(
      id: json['order_id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'В обработке',
      deliveryType:
          json['delivery_type']?.toString() ??
          (json['is_delivery'] == true ? 'delivery' : 'pickup'),
      items: orderItems,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      appliedBonus: appliedBonus,
      // Add applied bonus to the model
      address: json['address']?.toString(),
      comment: json['comment']?.toString(),
      spotId: json['spot_id']?.toString(),
      spotName: json['spot_name']?.toString(),
    );
  }

  // Helper method to parse numeric values to int
  // No division by 100 here as we assume order API returns correctly formatted prices
  static int _parseIntValue(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;
    if (value is double) return value.toInt();

    try {
      return int.parse(value.toString());
    } catch (e) {
      return 0;
    }
  }
}

// OrderItem class remains the same as before
class OrderItem {
  final String id;
  final String name;
  final int price;
  final int quantity;
  final String imageUrl;
  final dynamic modification;

  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    this.modification,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Convert values to int to maintain consistent types
    int price = _parseIntValue(json['price']);
    int quantity = _parseIntValue(json['quantity']);

    // Handle modification without type checking
    dynamic modificationData = json['modification'];

    return OrderItem(
      id: json['product_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: price,
      quantity: quantity,
      imageUrl: json['imageUrl']?.toString() ?? '',
      modification: modificationData,
    );
  }

  // Helper method to parse numeric values to int
  static int _parseIntValue(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;
    if (value is double) return value.toInt();

    try {
      return int.parse(value.toString());
    } catch (e) {
      return 0;
    }
  }
}
