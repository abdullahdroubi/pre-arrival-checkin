import 'package:flutter/foundation.dart';
import '../models/hotel_model.dart';
import '../services/hotel_service.dart';

class HotelProvider with ChangeNotifier
{
  final HotelService _hotelService = HotelService();
  List<HotelModel> _hotels = [];
  bool _isLoading = false;
  String? _error;

  List<HotelModel> get hotels => _hotels;
  bool get isLoading => _isLoading;
  String? get error => _error;

  //fetch all hotels
Future<void> fetchHotels()async
{
  _isLoading = true;
  _error = null;
  notifyListeners();

  try
  {
    _hotels = await _hotelService.getAllHotels();
    _isLoading = false;
    notifyListeners();
  }
  catch(e)
  {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
  }
}
//get hotel by id
Future<HotelModel?> getHotelById(int hotelId)async
{
  try
  {
    return await _hotelService.getHotelById(hotelId);
  }
  catch(e)
  {
    _error = e.toString();
    notifyListeners();
    return null;
  }
}
}