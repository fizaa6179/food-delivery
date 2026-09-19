class CartItemModel {
  final int? id;
  final int userId;
  final int foodItemId;
  final String foodName;
  final double price;
  final int quantity;
  final int restaurantId;

  CartItemModel({
    this.id,
    required this.userId,
    required this.foodItemId,
    required this.foodName,
    required this.price,
    required this.quantity,
    required this.restaurantId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'foodItemId': foodItemId,
      'foodName': foodName,
      'price': price,
      'quantity': quantity,
      'restaurantId': restaurantId,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      foodItemId: map['foodItemId'] as int,
      foodName: map['foodName'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      restaurantId: map['restaurantId'] as int,
    );
  }

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      id: id,
      userId: userId,
      foodItemId: foodItemId,
      foodName: foodName,
      price: price,
      quantity: quantity ?? this.quantity,
      restaurantId: restaurantId,
    );
  }
}