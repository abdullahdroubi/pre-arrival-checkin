class PaymentModel {
  final int id;
  final int bookingId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final String? transactionId;
  final DateTime paymentDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    this.currency = 'USD',
    required this.paymentMethod,
    required this.paymentStatus,
    this.transactionId,
    required this.paymentDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String,
      transactionId: json['transaction_id'] as String?,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'transaction_id': transactionId,
      'payment_date': paymentDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}