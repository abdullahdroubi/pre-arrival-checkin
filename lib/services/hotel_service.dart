import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hotel_model.dart';

class HotelService
{
  final SupabaseClient _supabase = Supabase.instance.client;

  //GET ALL ACTIVE HOTELS
Future<List<HotelModel>> getAllHotels()async
{
  try
  {
    final response = await _supabase
        .from('hotels')
        .select()
        .eq('is_active', true)
        .order('name');
    return (response as List)
        .map((json) => HotelModel.fromJson(json)).toList();
  }
  catch(e)
  {
    throw Exception('Failed to fetch hotels: $e');
  }
}
//get hotel by id
Future<HotelModel?> getHotelById(int hotelId)async
{
  try {
    final response = await _supabase
        .from('hotels')
        .select()
        .eq('id', hotelId)
        .eq('is_active', true)
        .single();
    return HotelModel.fromJson(response);
  }
  catch(e)
  {
    throw Exception('Failed to fetch hotel: $e');
  }
}
}