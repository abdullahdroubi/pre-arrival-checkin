import 'package:flutter/foundation.dart';
import '../models/email_notification_model.dart';
import '../services/email_notification_service.dart';

class EmailNotificationProvider with ChangeNotifier {
  final EmailNotificationService _emailService = EmailNotificationService();
  List<EmailNotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<EmailNotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Schedule check-in reminder
  Future<bool> scheduleCheckInReminder({
    required int bookingId,
    required String userId, // Changed to String for UUID
    required DateTime checkInDate,
    int daysBefore = 3,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _emailService.scheduleCheckInReminder(
        bookingId: bookingId,
        userId: userId,
        checkInDate: checkInDate,
        daysBefore: daysBefore,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get notifications for a booking
  Future<void> fetchBookingNotifications(int bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _emailService.getBookingNotifications(bookingId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
