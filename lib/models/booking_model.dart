class BookingModel {
  final int id;
  final String userId; // Changed to String for UUID
  final int hotelId;
  final int roomId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numberOfGuests;
  final double totalAmount;
  final String status;
  final String? _bookingReference; // From database - private field
  final String? guestFirstName;
  final String? guestLastName;
  final String? guestEmail;
  final String? guestPhone;
  final String? specialRequests;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.hotelId,
    required this.roomId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfGuests,
    required this.totalAmount,
    required this.status,
    String? bookingReference,
    this.guestFirstName,
    this.guestLastName,
    this.guestEmail,
    this.guestPhone,
    this.specialRequests,
    required this.createdAt,
    this.updatedAt,
  }) : _bookingReference = bookingReference;

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as int,
      userId: json['user_id'].toString(), // Convert to String for UUID
      hotelId: json['hotel_id'] as int,
      roomId: json['room_id'] as int,
      checkInDate: DateTime.parse(json['check_in_date'] as String),
      checkOutDate: DateTime.parse(json['check_out_date'] as String),
      numberOfGuests: json['number_of_guests'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      bookingReference: json['booking_reference'] as String?,
      guestFirstName: json['guest_first_name'] as String?,
      guestLastName: json['guest_last_name'] as String?,
      guestEmail: json['guest_email'] as String?,
      guestPhone: json['guest_phone'] as String?,
      specialRequests: json['special_requests'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'hotel_id': hotelId,
      'room_id': roomId,
      'check_in_date': checkInDate.toIso8601String().split('T')[0],
      'check_out_date': checkOutDate.toIso8601String().split('T')[0],
      'number_of_guests': numberOfGuests,
      'total_amount': totalAmount,
      'status': status,
      'guest_first_name': guestFirstName,
      'guest_last_name': guestLastName,
      'guest_email': guestEmail,
      'guest_phone': guestPhone,
      'special_requests': specialRequests,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Getter for booking reference - uses stored value or generates from ID
  String get bookingReference => 
      _bookingReference ?? 'BK${id.toString().padLeft(6, '0')}';
}