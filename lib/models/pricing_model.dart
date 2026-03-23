class PricingModel {
  final int id;
  final int roomTypeId;
  final DateTime date;
  final double price;
  final String currency;

  PricingModel({
    required this.id,
    required this.roomTypeId,
    required this.date,
    required this.price,
    this.currency = 'JD',
  });

  factory PricingModel.fromJson(Map<String, dynamic> json) {
    return PricingModel(
      id: json['id'] as int,
      roomTypeId: json['room_type_id'] as int,
      date: DateTime.parse(json['date'] as String),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'JD',
    );
  }
}