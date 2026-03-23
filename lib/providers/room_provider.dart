import 'package:flutter/foundation.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';

class RoomProvider with ChangeNotifier{
  final RoomService _roomService = RoomService();
  List<RoomModel> _availableRooms = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _numberOfGuests = 1;

  List<RoomModel> get availableRooms => _availableRooms;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get checkInDate => _checkInDate;
DateTime? get checkOutDate => _checkOutDate;
int get numberOfGuests => _numberOfGuests;

//set date range
void setDateRange(DateTime checkIn , DateTime checkOut){
  _checkInDate = checkIn;
  _checkOutDate =checkOut;
  notifyListeners();
}
//set number of guests
void setNumberOfGuests(int guests){
  _numberOfGuests = guests;
  notifyListeners();
}
//fetch available rooms
Future<void> fetchAvailableRooms(int hotelId)async{
  if(_checkInDate == null || _checkOutDate == null){
    _error = "please select check-in and check-out dates";
    notifyListeners();
return;
  }
  _isLoading = true;
  _error = null;
  notifyListeners();
try{
  _availableRooms = await _roomService.getAvailableRooms(
      hotelId: hotelId,
      checkIn: _checkInDate!,
      checkOut: _checkOutDate!,
  );
  _isLoading = false;
  notifyListeners();

}
catch(e){
  _error = e.toString();
  _isLoading = false;
  notifyListeners();

}
}
//calculate price for room
Future<double> calculatePrice(int roomTypeId)async{
  if(_checkInDate == null || _checkOutDate == null){
    return 0.0;
  }
  return await _roomService.calculateTotalPrice(
      roomTypeId: roomTypeId,
      checkIn: _checkInDate!,
      checkOut: _checkOutDate!,
  );
}
void clearRoom(){
  _availableRooms = [];
  _checkOutDate = null;
  _checkInDate = null;
  _numberOfGuests = 1;
  notifyListeners();

}

}