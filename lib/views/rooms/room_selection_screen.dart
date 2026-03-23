import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/room_model.dart';
import '../../providers/room_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/reveal_on_scroll.dart';
import '../booking/booking_form_screen.dart';

class RoomSelectionScreen extends StatefulWidget {
  final int hotelId;

  const RoomSelectionScreen({super.key, required this.hotelId});

  @override
  State<RoomSelectionScreen> createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _numberOfGuests = 1;

  @override
  void initState() {
    super.initState();
    _checkInDate = DateTime.now();
    _checkOutDate = DateTime.now().add(const Duration(days: 1));
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchRooms());
  }

  Future<void> _selectCheckInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _checkInDate = picked;
        if (_checkOutDate != null &&
            _checkOutDate!.isBefore(picked.add(const Duration(days: 1)))) {
          _checkOutDate = picked.add(const Duration(days: 1));
        }
      });
      _searchRooms();
    }
  }

  Future<void> _selectCheckOutDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: _checkInDate?.add(const Duration(days: 1)) ??
          DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _checkOutDate = picked);
      _searchRooms();
    }
  }

  void _searchRooms() {
    if (_checkInDate != null && _checkOutDate != null) {
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      roomProvider.setDateRange(_checkInDate!, _checkOutDate!);
      roomProvider.setNumberOfGuests(_numberOfGuests);
      roomProvider.fetchAvailableRooms(widget.hotelId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomProvider = Provider.of<RoomProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Select Room')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterPanel(context),
          Expanded(
            child: roomProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : roomProvider.error != null
                    ? Center(child: Text('Error: ${roomProvider.error}'))
                    : roomProvider.availableRooms.isEmpty
                        ? Center(
                            child: Text(
                              'No rooms available for selected dates',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                            itemCount: roomProvider.availableRooms.length,
                            itemBuilder: (context, index) {
                              final room = roomProvider.availableRooms[index];
                              return RevealOnScroll(
                                delay: Duration(milliseconds: 80 * index),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildRoomCard(room),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _dateField(
                  label: 'Check-in',
                  date: _checkInDate,
                  onTap: _selectCheckInDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateField(
                  label: 'Check-out',
                  date: _checkOutDate,
                  onTap: _selectCheckOutDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Text('Guests', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(
                onPressed: _numberOfGuests > 1
                    ? () {
                        setState(() => _numberOfGuests--);
                        _searchRooms();
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              Text('$_numberOfGuests'),
              IconButton(
                onPressed: () {
                  setState(() => _numberOfGuests++);
                  _searchRooms();
                },
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _searchRooms,
              child: const Text('Search'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE6EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            Text(
              date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Select date',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    if (room.roomType == null) return const SizedBox();
    final roomType = room.roomType!;
    final roomImage = roomType.images.isNotEmpty ? roomType.images.first : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (roomImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    roomImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _roomFallback(),
                  ),
                ),
              )
            else
              _roomFallback(),
            const SizedBox(height: 12),
            Text(
              roomType.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
            ),
            if (roomType.description != null) ...[
              const SizedBox(height: 6),
              Text(roomType.description!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _miniFeature(Icons.people_outline_rounded, 'Max ${roomType.maxOccupancy} guests'),
                if (roomType.bedType != null) _miniFeature(Icons.bed_rounded, roomType.bedType!),
                if (roomType.sizeSqm != null) _miniFeature(Icons.square_foot_rounded, '${roomType.sizeSqm} sqm'),
              ],
            ),
            if (roomType.amenities.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: roomType.amenities.take(4).map((amenity) => Chip(label: Text(amenity))).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<double>(
                  future: Provider.of<RoomProvider>(context, listen: false)
                      .calculatePrice(room.roomTypeId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Calculating...');
                    }
                    return Text(
                      '\$${snapshot.data?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryNavy,
                      ),
                    );
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingFormScreen(
                          room: room,
                          hotelId: widget.hotelId,
                        ),
                      ),
                    );
                  },
                  child: const Text('Select Room'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniFeature(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _roomFallback() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFE8EEF3),
      ),
      height: 180,
      width: double.infinity,
      alignment: Alignment.center,
      child: const Icon(Icons.bed_rounded, size: 44, color: AppTheme.primaryNavy),
    );
  }
}
