import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';
import 'email_notification_service.dart';
import '../config/supabase_config.dart';

class BookingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create a new booking
  Future<BookingModel> createBooking({
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
    try {
      // Generate booking reference (format: BK + last 8 digits of timestamp)
      // This ensures uniqueness. The reference can be updated after we get the booking ID if needed
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final lastDigits = timestamp.length >= 8 
          ? timestamp.substring(timestamp.length - 8)
          : timestamp.padLeft(8, '0');
      final bookingReference = 'BK$lastDigits';
      print('🔖 Generated booking reference: $bookingReference');
      
      // Prepare insert data
      final insertData = {
        'user_id': userId,
        'hotel_id': hotelId,
        'room_id': roomId,
        'check_in_date': checkInDate.toIso8601String().split('T')[0],
        'check_out_date': checkOutDate.toIso8601String().split('T')[0],
        'number_of_guests': numberOfGuests,
        'total_amount': totalAmount,
        'status': 'pending', // Will be 'confirmed' after payment
        'booking_reference': bookingReference, // Required field
        'created_at': DateTime.now().toIso8601String(), // Add created_at explicitly
        'updated_at': DateTime.now().toIso8601String(), // Add updated_at explicitly
      };

      // Add guest information if provided
      if (guestFirstName != null && guestFirstName.isNotEmpty) {
        insertData['guest_first_name'] = guestFirstName;
      }
      if (guestLastName != null && guestLastName.isNotEmpty) {
        insertData['guest_last_name'] = guestLastName;
      }
      if (guestEmail != null && guestEmail.isNotEmpty) {
        insertData['guest_email'] = guestEmail;
      }
      if (guestPhone != null && guestPhone.isNotEmpty) {
        insertData['guest_phone'] = guestPhone;
      }
      if (specialRequests != null && specialRequests.isNotEmpty) {
        insertData['special_requests'] = specialRequests;
      }

      print('📝 Creating booking with data: ${insertData.keys.toList()}');
      print('📝 Booking reference in data: ${insertData['booking_reference']}');
      
      final response = await _supabase
          .from('bookings')
          .insert(insertData)
          .select()
          .single();

      print('✅ Booking created successfully: ${response['id']}');
      return BookingModel.fromJson(response);
    } catch (e) {
      print('❌ ERROR creating booking: $e');
      // Provide more detailed error message
      if (e.toString().contains('null value')) {
        throw Exception('Failed to create booking: A required field is missing. Error: $e');
      }
      throw Exception('Failed to create booking: $e');
    }
  }

  // Update booking status (e.g., after payment)
  Future<BookingModel> updateBookingStatus({
    required int bookingId,
    required String status,
  }) async {
    try {
      final response = await _supabase
          .from('bookings')
          .update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', bookingId)
          .select()
          .single();

      final booking = BookingModel.fromJson(response);

      // Send confirmation email and schedule check-in reminder when booking is confirmed
      if (status == 'confirmed') {
        try {
          print('📧 Creating email notifications for booking ${booking.id}...');
          final emailService = EmailNotificationService();

          // 1. Send confirmation email immediately
          print('📧 Creating confirmation email notification...');
          // Use UTC time to avoid timezone issues
          final confirmationNotification = await emailService.createEmailNotification(
            bookingId: booking.id,
            userId: booking.userId, // userId is String (UUID)
            emailType: 'booking_confirmation',
            scheduledDate: DateTime.now().toUtc(), // Send immediately (UTC to avoid timezone issues)
          );
          print('✅ Confirmation email notification created: ${confirmationNotification.id}');
          print('   Scheduled for: ${confirmationNotification.scheduledDate}');

          // 2. Schedule check-in reminder email (48 hours before check-in)
          print('📧 Scheduling check-in reminder email...');
          final reminderNotification = await emailService.scheduleCheckInReminder(
            bookingId: booking.id,
            userId: booking.userId, // userId is String (UUID)
            checkInDate: booking.checkInDate,
            daysBefore: 2, // Send reminder 48 hours (2 days) before check-in
          );
          print('✅ Check-in reminder scheduled: ${reminderNotification.id} (scheduled for ${reminderNotification.scheduledDate})');

          // 3. Verify notification exists in database before invoking Edge Function
          print('🔍 Verifying email notification exists in database...');
          await Future.delayed(Duration(seconds: 1));
          
          try {
            final verifyResponse = await _supabase
                .from('email_notifications')
                .select('id, email_type, email_status, scheduled_date')
                .eq('booking_id', booking.id)
                .eq('email_type', 'booking_confirmation')
                .eq('email_status', 'scheduled')
                .single();
            
            print('✅ Email notification verified in database:');
            print('   ID: ${verifyResponse['id']}');
            print('   Status: ${verifyResponse['email_status']}');
            print('   Scheduled: ${verifyResponse['scheduled_date']}');
          } catch (verifyError) {
            print('⚠️ WARNING: Could not verify email notification: $verifyError');
            print('   Continuing anyway - Edge Function will check...');
          }

          // 4. Trigger Edge Function immediately to send confirmation email
          // Wait a bit more to ensure database transaction is fully committed
          print('⏳ Waiting for database transaction to fully commit...');
          await Future.delayed(Duration(seconds: 1));
          
          print('🚀 Triggering Edge Function to send confirmation email immediately...');
          print('   Booking ID: ${booking.id}');
          print('   Guest Email: ${booking.guestEmail ?? "NOT SET"}');
          
          try {
            // Invoke Edge Function using HTTP package with proper authentication
            // This ensures the function can be called with the anon key
            final functionUrl = '${SupabaseConfig.supabaseUrl}/functions/v1/checkin-reminder';
            
            print('🌐 Calling Edge Function: $functionUrl');
            
            final response = await http.post(
              Uri.parse(functionUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
                'apikey': SupabaseConfig.supabaseAnonKey,
              },
              body: jsonEncode({}),
            );
            
            // Log the response for debugging
            print('📧 Edge Function response status: ${response.statusCode}');
            
            // Parse response
            Map<String, dynamic>? responseData;
            if (response.body.isNotEmpty) {
              try {
                responseData = jsonDecode(response.body) as Map<String, dynamic>?;
                print('📧 Edge Function response data: $responseData');
              } catch (e) {
                print('📧 Edge Function response (raw): ${response.body}');
              }
            }
            
            // Check if response indicates success
            if (response.statusCode == 200) {
              print('✅ Edge Function invoked successfully - confirmation email should be sent immediately');
              
              // Parse response to see what was processed
              if (responseData != null) {
                final count = responseData['count'] ?? 0;
                final results = responseData['results'] as List?;
                print('📊 Processed $count notification(s)');
                if (results != null && results.isNotEmpty) {
                  for (var result in results) {
                    print('   - ${result['emailType']}: ${result['status']}');
                    if (result['error'] != null) {
                      print('     ERROR: ${result['error']}');
                    }
                  }
                } else {
                  print('⚠️ WARNING: No notifications were processed!');
                  print('   This might mean:');
                  print('   1. Email notification was not created in database');
                  print('   2. scheduled_date is in the future');
                  print('   3. email_status is not "scheduled"');
                  print('   Check the database to verify the email notification exists.');
                }
              }
            } else {
              print('⚠️ Edge Function returned status: ${response.statusCode}');
              if (response.body.isNotEmpty) {
                print('   Response: ${response.body}');
              }
            }
          } catch (functionError) {
            print('❌ ERROR: Could not invoke Edge Function immediately: $functionError');
            print('   Full error: ${functionError.toString()}');
            print('   Email will be sent by cron job within 1 hour');
            // Don't throw - let the booking confirmation succeed even if email fails
          }
        } catch (e, stackTrace) {
          // Log error but don't fail the booking confirmation
          print('❌ ERROR: Failed to schedule emails: $e');
          print('Stack trace: $stackTrace');
        }
      }

      return booking;
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Get booking by ID
  Future<BookingModel?> getBookingById(int bookingId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .single();

      return BookingModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Get all bookings for a user
  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user bookings: $e');
    }
  }

  // Cancel a booking
  Future<BookingModel> cancelBooking(int bookingId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', bookingId)
          .select()
          .single();

      return BookingModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }
}