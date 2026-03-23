import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../home_screen.dart';
import 'booking_detail_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final BookingModel booking;

  const BookingConfirmationScreen({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 70,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            // Success Message
            const Text(
              'Booking Confirmed!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your booking reference is: ${booking.bookingReference}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 32),
            // Booking Details Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Booking Reference',
                      booking.bookingReference,
                      isHighlight: true,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Status',
                      booking.status.toUpperCase(),
                      statusColor: _getStatusColor(booking.status),
                    ),
                    const SizedBox(height: 12),
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
                      'Number of Guests',
                      booking.numberOfGuests.toString(),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Total Amount',
                      '\$${booking.totalAmount.toStringAsFixed(2)}',
                      isHighlight: true,
                      textColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Guest Information Card
            if (booking.guestFirstName != null || booking.guestEmail != null)
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
                          '${booking.guestFirstName ?? ''} ${booking.guestLastName ?? ''}'.trim(),
                        ),
                      if (booking.guestEmail != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Email',
                          booking.guestEmail!,
                        ),
                      ],
                      if (booking.guestPhone != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Phone',
                          booking.guestPhone!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Special Requests
            if (booking.specialRequests != null &&
                booking.specialRequests!.isNotEmpty)
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
            const SizedBox(height: 32),
            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingDetailScreen(booking: booking),
                  ),
                );
              },
              child: const Text('View Booking Details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
    Color? textColor,
    Color? statusColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: statusColor ?? textColor ?? Colors.black87,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
