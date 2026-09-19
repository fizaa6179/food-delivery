class FavoriteModel {
  final int? id;
  final int userId;
  final int foodItemId;
  final String foodName;
  final String restaurantName;
  final double price;

  FavoriteModel({
    this.id,
    required this.userId,
    required this.foodItemId,
    required this.foodName,
    required this.restaurantName,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'foodItemId': foodItemId,
      'foodName': foodName,
      'restaurantName': restaurantName,
      'price': price,
    };
  }

  factory FavoriteModel.fromMap(Map<String, dynamic> map) {
    return FavoriteModel(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      foodItemId: map['foodItemId'] as int,
      foodName: map['foodName'] as String,
      restaurantName: map['restaurantName'] as String,
      price: (map['price'] as num).toDouble(),
    );
  }
}