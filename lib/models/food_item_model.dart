class FoodItemModel {
  final int? id;
  final int restaurantId;
  final String name;
  final String section; // Pizza, Sides, Burgers, etc.
  final double price;

  FoodItemModel({
    this.id,
    required this.restaurantId,
    required this.name,
    required this.section,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'name': name,
      'section': section,
      'price': price,
    };
  }

  factory FoodItemModel.fromMap(Map<String, dynamic> map) {
    return FoodItemModel(
      id: map['id'] as int?,
      restaurantId: map['restaurantId'] as int,
      name: map['name'] as String,
      section: map['section'] as String,
      price: (map['price'] as num).toDouble(),
    );
  }
}