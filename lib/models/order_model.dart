class OrderItem {
  final int productId;
  final String name;
  final int price;
  final String imageUrl;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? 'Неизвестный товар',
      price: json['price'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }
}

class OrderModel {
  final int id;
  final String date;
  final List<OrderItem> items;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final String status;
  final String deliveryType; // 'delivery' or 'pickup'

  OrderModel({
    required this.id,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.deliveryType,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<OrderItem> orderItems = [];
    if (json['items'] != null) {
      orderItems = (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    }

    return OrderModel(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      items: orderItems,
      subtotal: json['subtotal'] ?? 0,
      deliveryFee: json['deliveryFee'] ?? 0,
      total: json['total'] ?? 0,
      status: json['status'] ?? 'В обработке',
      deliveryType: json['deliveryType'] ?? 'delivery',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'status': status,
      'deliveryType': deliveryType,
    };
  }
}