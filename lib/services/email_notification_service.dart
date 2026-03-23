import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/email_notification_model.dart';

class EmailNotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create email notification record
  Future<EmailNotificationModel> createEmailNotification({
    required int bookingId,
    required String userId, // Changed to String for UUID
    required String emailType,
    required DateTime scheduledDate,
  }) async {
    try {
      // Ensure scheduled_date is in UTC and not in the future for immediate emails
      final now = DateTime.now().toUtc();
      final scheduledDateUtc = scheduledDate.toUtc();
      
      // For confirmation emails, ensure they're scheduled for now or past (immediate)
      // This prevents timezone issues where scheduled_date ends up in the future
      final finalScheduledDate = (emailType == 'booking_confirmation' && scheduledDateUtc.isAfter(now))
          ? now
          : scheduledDateUtc;
      
      print('📧 Inserting email notification: bookingId=$bookingId, userId=$userId, type=$emailType');
      print('   Original scheduled: $scheduledDate');
      print('   Final scheduled (UTC): $finalScheduledDate');
      
      final response = await _supabase
          .from('email_notifications')
          .insert({
        'booking_id': bookingId,
        'user_id': userId,
        'email_type': emailType,
        'email_status': 'scheduled',
        'scheduled_date': finalScheduledDate.toIso8601String(),
      })
          .select()
          .single();

      print('✅ Email notification created successfully: ${response['id']}');
      return EmailNotificationModel.fromJson(response);
    } catch (e, stackTrace) {
      print('❌ ERROR creating email notification: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to create email notification: $e');
    }
  }

  // Schedule check-in reminder (X days before check-in)
  Future<EmailNotificationModel> scheduleCheckInReminder({
    required int bookingId,
    required String userId, // Changed to String for UUID
    required DateTime checkInDate,
    int daysBefore = 2, // Default: 48 hours (2 days) before check-in
  }) async {
    // Calculate the scheduled date (X days before check-in)
    final scheduledDate = checkInDate.subtract(Duration(days: daysBefore));
    final now = DateTime.now().toUtc();
    
    // If check-in is less than X days away, send reminder immediately
    // (e.g., if check-in is tomorrow and we want 2 days before, send now)
    final scheduledDateUtc = scheduledDate.toUtc();
    final finalScheduledDate = scheduledDateUtc.isBefore(now) ? now : scheduledDateUtc;
    
    if (scheduledDateUtc.isBefore(now)) {
      print('⚠️ Check-in is less than $daysBefore days away. Scheduling reminder for immediate send.');
    }

    return await createEmailNotification(
      bookingId: bookingId,
      userId: userId,
      emailType: 'check_in_reminder',
      scheduledDate: finalScheduledDate,
    );
  }

  // Get email notifications for a booking
  Future<List<EmailNotificationModel>> getBookingNotifications(int bookingId) async {
    try {
      final response = await _supabase
          .from('email_notifications')
          .select()
          .eq('booking_id', bookingId)
          .order('scheduled_date', ascending: true);

      return (response as List)
          .map((json) => EmailNotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch email notifications: $e');
    }
  }

  // Get pending email notifications (for scheduled job)
  Future<List<EmailNotificationModel>> getPendingNotifications() async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('email_notifications')
          .select()
          .eq('email_status', 'scheduled')
          .lte('scheduled_date', now)
          .order('scheduled_date', ascending: true);

      return (response as List)
          .map((json) => EmailNotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending notifications: $e');
    }
  }

  // Mark email as sent
  Future<EmailNotificationModel> markAsSent(int notificationId) async {
    try {
      final response = await _supabase
          .from('email_notifications')
          .update({
        'email_status': 'sent',
        'sent_at': DateTime.now().toIso8601String(),
      })
          .eq('id', notificationId)
          .select()
          .single();

      return EmailNotificationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to mark email as sent: $e');
    }
  }

  // Mark email as failed
  Future<EmailNotificationModel> markAsFailed({
    required int notificationId,
    required String errorMessage,
  }) async {
    try {
      final response = await _supabase
          .from('email_notifications')
          .update({
        'email_status': 'failed',
        'error_message': errorMessage,
      })
          .eq('id', notificationId)
          .select()
          .single();

      return EmailNotificationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to mark email as failed: $e');
    }
  }
}
