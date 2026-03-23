import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/booking_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/room_model.dart';
import '../payments/payment_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final RoomModel room;
  final int hotelId;

  const BookingFormScreen({
    super.key,
    required this.room,
    required this.hotelId,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with user data if available
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Get current user
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to continue')),
      );
      return;
    }

    // Calculate total price
    final totalPrice = await roomProvider.calculatePrice(widget.room.roomTypeId);

    // Use the auth user's UUID directly since bookings.user_id is UUID type
    // The bookings table expects a UUID, not an integer from user_profiles
    final userId = user.id; // This is already a UUID string from Supabase Auth

    // Create booking
    final success = await bookingProvider.createBooking(
      userId: userId,
      hotelId: widget.hotelId,
      roomId: widget.room.id,
      checkInDate: roomProvider.checkInDate!,
      checkOutDate: roomProvider.checkOutDate!,
      numberOfGuests: roomProvider.numberOfGuests,
      totalAmount: totalPrice,
      guestFirstName: _firstNameController.text.trim(),
      guestLastName: _lastNameController.text.trim(),
      guestEmail: _emailController.text.trim(),
      guestPhone: _phoneController.text.trim(),
      specialRequests: _specialRequestsController.text.trim().isEmpty
          ? null
          : _specialRequestsController.text.trim(),
    );

    if (!mounted) return;

    if (success && bookingProvider.currentBooking != null) {
      // Navigate to payment screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            booking: bookingProvider.currentBooking!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create booking: ${bookingProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomProvider = Provider.of<RoomProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: bookingProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Summary Card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.room.roomType?.name ?? 'Room',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (roomProvider.checkInDate != null &&
                          roomProvider.checkOutDate != null) ...[
                        Text(
                          'Check-in: ${DateFormat('MMM dd, yyyy').format(roomProvider.checkInDate!)}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        Text(
                          'Check-out: ${DateFormat('MMM dd, yyyy').format(roomProvider.checkOutDate!)}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        Text(
                          'Guests: ${roomProvider.numberOfGuests}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                      const SizedBox(height: 8),
                      FutureBuilder<double>(
                        future: roomProvider.calculatePrice(
                          widget.room.roomTypeId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              'Total: \$${snapshot.data!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            );
                          }
                          return const Text('Calculating...');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Guest Information
              const Text(
                'Guest Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              // Special Requests
              const Text(
                'Special Requests (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _specialRequestsController,
                decoration: const InputDecoration(
                  labelText: 'Any special requests?',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Continue to Payment',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}