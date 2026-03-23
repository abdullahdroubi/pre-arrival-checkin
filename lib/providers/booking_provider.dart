import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingProvider with ChangeNotifier {
  final BookingService _bookingService = BookingService();
  BookingModel? _currentBooking;
  List<BookingModel> _userBookings = [];
  bool _isLoading = false;
  String? _error;

  BookingModel? get currentBooking => _currentBooking;
  List<BookingModel> get userBookings => _userBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create a new booking
  Future<bool> createBooking({
    required String userId, // Changed to String for UUID
    required int hotelId,
    required int roomId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int numberOfGuests,
    required double totalAmount,
    String? guestFirstName,
    String? guestLastName,
    String? guestEmail,
    String? guestPhone,
    String? specialRequests,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentBooking = await _bookingService.createBooking(
        userId: userId,
        hotelId: hotelId,
        roomId: roomId,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        numberOfGuests: numberOfGuests,
        totalAmount: totalAmount,
        guestFirstName: guestFirstName,
        guestLastName: guestLastName,
        guestEmail: guestEmail,
        guestPhone: guestPhone,
        specialRequests: specialRequests,
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

  // Confirm booking (after payment)
  Future<bool> confirmBooking(int bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentBooking = await _bookingService.updateBookingStatus(
        bookingId: bookingId,
        status: 'confirmed',
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

  // Get user bookings
  Future<void> fetchUserBookings(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userBookings = await _bookingService.getUserBookings(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel booking
  Future<bool> cancelBooking(int bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _bookingService.cancelBooking(bookingId);
      // Refresh user bookings
      if (_currentBooking?.userId != null) {
        await fetchUserBookings(_currentBooking!.userId);
      }
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

  void clearCurrentBooking() {
    _currentBooking = null;
    notifyListeners();
  }
}
