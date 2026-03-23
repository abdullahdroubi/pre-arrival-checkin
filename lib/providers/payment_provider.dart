import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  PaymentModel? _currentPayment;
  bool _isProcessing = false;
  String? _error;

  PaymentModel? get currentPayment => _currentPayment;
  bool get isProcessing => _isProcessing;
  String? get error => _error;

  // Process payment
  Future<bool> processPayment({
    required int bookingId,
    required double amount,
    required String paymentMethod,
    String currency = 'USD',
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      _currentPayment = await _paymentService.processPayment(
        bookingId: bookingId,
        amount: amount,
        paymentMethod: paymentMethod,
        currency: currency,
      );
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  // Get payment by booking ID
  Future<PaymentModel?> getPaymentByBookingId(int bookingId) async {
    try {
      return await _paymentService.getPaymentByBookingId(bookingId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearPayment() {
    _currentPayment = null;
    _error = null;
    notifyListeners();
  }
}