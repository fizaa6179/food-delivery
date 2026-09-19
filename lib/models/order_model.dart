class OrderModel {
  final int? id;
  final int userId;
  final String itemsSummary; // e.g. "Margherita Pizza x1, Garlic Bread x2"
  final int itemCount;
  final double totalAmount;
  final String status; // Placed, Delivered, Cancelled
  final String paymentMethod;
  final String dateTime;

  OrderModel({
    this.id,
    required this.userId,
    required this.itemsSummary,
    required this.itemCount,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'itemsSummary': itemsSummary,
      'itemCount': itemCount,
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'dateTime': dateTime,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      itemsSummary: map['itemsSummary'] as String,
      itemCount: map['itemCount'] as int,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      status: map['status'] as String,
      paymentMethod: map['paymentMethod'] as String,
      dateTime: map['dateTime'] as String,
    );
  }
}