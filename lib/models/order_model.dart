// Update your order_model.dart file with these class definitions to match how they're used in API service

class OrderModel {
  final String id; // Changed from int to String to match API usage
  final String date;
  final String status;
  final String deliveryType; // 'delivery' or 'pickup'
  final List<OrderItem> items;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final String? address;
  final String? comment;

  OrderModel({
    required this.id,
    required this.date,
    required this.status,
    required this.deliveryType,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.address,
    this.comment,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse items
    List<OrderItem> orderItems = [];
    if (json['items'] != null) {
      orderItems = (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    }

    // Convert values to int
    int subtotal = _parseIntValue(json['subtotal']);
    int deliveryFee = _parseIntValue(json['delivery_fee']);
    int total = _parseIntValue(json['total']);

    return OrderModel(
      id: json['order_id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'В обработке',
      deliveryType: json['delivery_type']?.toString() ?? 'delivery',
      items: orderItems,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      address: json['address']?.toString(),
      comment: json['comment']?.toString(),
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

class OrderItem {
  final String id; // Changed from productId to id to match constructor
  final String name;
  final int price;
  final int quantity;
  final String imageUrl;
  final Map<String, dynamic>? modification;

  OrderItem({
    required this.id, // Updated parameter name
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

    return OrderItem(
      id: json['product_id']?.toString() ?? '', // Parse product_id as id
      name: json['name']?.toString() ?? '',
      price: price,
      quantity: quantity,
      imageUrl: json['imageUrl']?.toString() ?? '',
      modification: json['modification'],
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