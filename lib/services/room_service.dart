import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_model.dart';
import '../models/pricing_model.dart';

class RoomService{

  final SupabaseClient _supabase = Supabase.instance.client;

// Get available rooms for a hotel with date range

Future<List<RoomModel>> getAvailableRooms({
    required int hotelId,
  required DateTime checkIn,
  required DateTime checkOut,
})async{
  try{
    print('[ROOM_SERVICE] Fetching rooms for hotel: $hotelId, checkIn: $checkIn, checkOut: $checkOut');

    final checkInStr = checkIn.toIso8601String().split('T')[0];
    final checkOutStr = checkOut.toIso8601String().split('T')[0];

    // Get all rooms for the hotel (regardless of status first, to debug)
    final response = await _supabase
        .from('rooms')
        .select('''
            *,
            room_types(*)
        ''')
        .eq('hotel_id', hotelId);

    print('[ROOM_SERVICE] Total rooms found: ${(response as List).length}');

    // Filter rooms by status
    final allRooms = (response as List)
        .map((json) => RoomModel.fromJson(json))
        .where((room) => room.status == 'available' || room.status == null) // Include null status too
        .toList();

    print('[ROOM_SERVICE] Available rooms (status=available): ${allRooms.length}');

    // Get booked room IDs for the date range
    // A booking overlaps if: check_in_date < check_out AND check_out_date > check_in
    // We need to get all confirmed bookings and filter in Dart for proper overlap logic
    final allBookingsResponse = await _supabase
        .from('bookings')
        .select('room_id, check_in_date, check_out_date')
        .eq('hotel_id', hotelId)
        .eq('status', 'confirmed');

    // Filter bookings that overlap with requested dates in Dart
    final bookedRoomIds = (allBookingsResponse as List)
        .where((booking) {
          if (booking['room_id'] == null) return false;
          final bookingCheckIn = DateTime.parse(booking['check_in_date'] as String);
          final bookingCheckOut = DateTime.parse(booking['check_out_date'] as String);
          // Overlap: booking starts before requested checkout AND booking ends after requested checkin
          return bookingCheckIn.isBefore(checkOut) && bookingCheckOut.isAfter(checkIn);
        })
        .map((booking) => booking['room_id'] as int)
        .toSet();


    // Filter out booked rooms
    final availableRooms = allRooms
        .where((room) => !bookedRoomIds.contains(room.id))
        .toList();

    print('[ROOM_SERVICE] Final available rooms: ${availableRooms.length}');

    return availableRooms;

  }
  catch(e)
  {
    print('[ROOM_SERVICE] Error: $e');
    throw Exception('Failed to fetch available rooms: $e');
  }

}

// Get pricing for a room type on a specific date

Future<double?> getPriceForDate({
    required int roomTypeId,
  required DateTime date,
})async{
  try{
    final dateStr = date.toIso8601String().split('T')[0];

    final response = await _supabase
        .from('pricing')
        .select('price')
        .eq('room_type_id', roomTypeId)
        .eq('date', dateStr)
        .single();

    return (response['price'] as num).toDouble();
  }
  catch(e){
    // If no specific pricing, return null (you can set a default price)
      return null;
  }
}
// Calculate total price for date range
  Future<double> calculateTotalPrice({
    required int roomTypeId,
    required DateTime checkIn,
    required DateTime checkOut,
})
  async{
  double total = 0.0;
  DateTime currentDate = checkIn;
  while (currentDate.isBefore(checkOut)){
    final price = await getPriceForDate(
        roomTypeId: roomTypeId,
        date: currentDate,
    );
    total += price ?? 0.0;
    currentDate = currentDate.add(const Duration(days : 1));
  }
  return total;
  }
}

