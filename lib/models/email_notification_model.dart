class EmailNotificationModel {
  final int id;
  final int bookingId;
  final String userId; // Changed to String for UUID
  final String emailType;
  final String emailStatus;
  final DateTime? scheduledDate;
  final DateTime? sentAt;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EmailNotificationModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.emailType,
    required this.emailStatus,
    this.scheduledDate,
    this.sentAt,
    this.errorMessage,
    required this.createdAt,
    this.updatedAt,
  });

  factory EmailNotificationModel.fromJson(Map<String, dynamic> json) {
    return EmailNotificationModel(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int,
      userId: json['user_id'].toString(), // Convert to String for UUID
      emailType: json['email_type'] as String,
      emailStatus: json['email_status'] as String,
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'] as String)
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      errorMessage: json['error_message'] as String?,
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
      'user_id': userId,
      'email_type': emailType,
      'email_status': emailStatus,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
