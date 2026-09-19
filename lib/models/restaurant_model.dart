class RestaurantModel {
  final int? id;
  final String name;
  final String category; // Pizza, Burger, Biryani, Desserts
  final double rating;
  final int deliveryMinLow;
  final int deliveryMinHigh;
  final bool freeDelivery;

  RestaurantModel({
    this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.deliveryMinLow,
    required this.deliveryMinHigh,
    required this.freeDelivery,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'rating': rating,
      'deliveryMinLow': deliveryMinLow,
      'deliveryMinHigh': deliveryMinHigh,
      'freeDelivery': freeDelivery ? 1 : 0,
    };
  }

  factory RestaurantModel.fromMap(Map<String, dynamic> map) {
    return RestaurantModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      rating: (map['rating'] as num).toDouble(),
      deliveryMinLow: map['deliveryMinLow'] as int,
      deliveryMinHigh: map['deliveryMinHigh'] as int,
      freeDelivery: (map['freeDelivery'] as int) == 1,
    );
  }
}