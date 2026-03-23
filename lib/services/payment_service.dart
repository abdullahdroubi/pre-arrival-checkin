import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../models/payment_model.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mock payment processing
  // In a real app, this would integrate with payment gateways like Stripe, PayPal, etc.
  Future<PaymentModel> processPayment({
    required int bookingId,
    required double amount,
    required String paymentMethod,
    String currency = 'USD',
  }) async {
    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock payment - always succeeds for demo purposes
      // In real app, this would call payment gateway API
      final isSuccess = _mockPaymentGateway(amount, paymentMethod);

      if (!isSuccess) {
        throw Exception('Payment processing failed');
      }

      // Generate mock transaction ID
      final transactionId = _generateTransactionId();

      // Create payment record
      final response = await _supabase
          .from('payments')
          .insert({
        'booking_id': bookingId,
        'amount': amount,
        'currency': currency,
        'payment_method': paymentMethod,
        'payment_status': 'completed',
        'transaction_id': transactionId,
        'payment_date': DateTime.now().toIso8601String(),
      })
          .select()
          .single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  // Mock payment gateway - simulates payment processing
  bool _mockPaymentGateway(double amount, String paymentMethod) {
    // For demo purposes, always return true
    // In real app, this would make API call to payment provider
    return true;
  }

  // Generate mock transaction ID
  String _generateTransactionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(9999).toString().padLeft(4, '0');
    return 'TXN$timestamp$randomNum';
  }

  // Get payment by booking ID
  Future<PaymentModel?> getPaymentByBookingId(int bookingId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('booking_id', bookingId)
          .single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Get payment by ID
  Future<PaymentModel?> getPaymentById(int paymentId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('id', paymentId)
          .single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}