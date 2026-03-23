import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import 'my_bookings_screen.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingModel booking;

  const BookingDetailScreen({
    super.key,
    required this.booking,
  });

  // Check if cancellation is allowed (more than 48 hours before check-in)
  bool _canCancelBooking() {
    final now = DateTime.now();
    final checkIn = booking.checkInDate;
    final hoursUntilCheckIn = checkIn.difference(now).inHours;
    return hoursUntilCheckIn > 48;
  }

  String _getCancellationMessage() {
    final now = DateTime.now();
    final checkIn = booking.checkInDate;
    final hoursUntilCheckIn = checkIn.difference(now).inHours;
    
    if (hoursUntilCheckIn <= 0) {
      return 'Check-in has passed. This booking cannot be cancelled.';
    } else if (hoursUntilCheckIn <= 48) {
      final hours = hoursUntilCheckIn;
      return 'Cancellation is not allowed. Check-in is in $hours hour${hours == 1 ? '' : 's'}. '
          'Bookings can only be cancelled more than 48 hours before check-in.';
    }
    return '';
  }

  Future<void> _cancelBooking(BuildContext context) async {
    // Check if cancellation is allowed
    if (!_canCancelBooking()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getCancellationMessage()),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Cancel booking
    final success = await bookingProvider.cancelBooking(booking.id);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh bookings list
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.user;
        if (user != null) {
          // Use auth UUID directly since bookings.user_id is UUID type
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            await bookingProvider.fetchUserBookings(userId);
          }
        }
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: ${bookingProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (booking.status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 24, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Booking Reference
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildDetailRow('Booking Reference', booking.bookingReference),
                    const SizedBox(height: 12),
                    _buildDetailRow('Booking ID', '#${booking.id}'),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Booking Date',
                      DateFormat('MMM dd, yyyy HH:mm').format(booking.createdAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Dates
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stay Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Check-in',
                      DateFormat('MMM dd, yyyy').format(booking.checkInDate),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Check-out',
                      DateFormat('MMM dd, yyyy').format(booking.checkOutDate),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Number of Nights',
                      '${booking.checkOutDate.difference(booking.checkInDate).inDays}',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Number of Guests',
                      booking.numberOfGuests.toString(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Payment
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Total Amount',
                      '\$${booking.totalAmount.toStringAsFixed(2)}',
                      valueColor: Colors.green,
                      valueStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Guest Information
            if (booking.guestFirstName != null ||
                booking.guestLastName != null ||
                booking.guestEmail != null ||
                booking.guestPhone != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Guest Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      if (booking.guestFirstName != null ||
                          booking.guestLastName != null)
                        _buildDetailRow(
                          'Name',
                          '${booking.guestFirstName ?? ''} ${booking.guestLastName ?? ''}',
                        ),
                      if (booking.guestEmail != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow('Email', booking.guestEmail!),
                      ],
                      if (booking.guestPhone != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow('Phone', booking.guestPhone!),
                      ],
                    ],
                  ),
                ),
              ),
            if (booking.specialRequests != null) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Special Requests',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        booking.specialRequests!,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Cancel Button (only if not cancelled and more than 48 hours before check-in)
            if (booking.status.toLowerCase() != 'cancelled') ...[
              if (!_canCancelBooking()) ...[
                // Show message if cancellation is not allowed
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getCancellationMessage(),
                          style: TextStyle(color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canCancelBooking() ? () => _cancelBooking(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                  ),
                  child: const Text(
                    'Cancel Booking',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      String label,
      String value, {
        Color? valueColor,
        TextStyle? valueStyle,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: valueStyle ??
                TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
          ),
        ),
      ],
    );
  }
}