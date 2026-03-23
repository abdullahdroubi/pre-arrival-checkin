import 'room_type_model.dart';

class RoomModel{
  final int id;
  final int hotelId;
  final int roomTypeId;
  final String roomNumber;
  final int? floor;
  final String status;
  final RoomTypeModel? roomType;

  RoomModel({
    required this.id,
    required this.hotelId,
    required this.roomTypeId,
    required this.roomNumber,
    this.floor,
    required this.status,
    this.roomType,
});

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as int,
      hotelId: json['hotel_id'] as int,
      roomTypeId: json['room_type_id'] as int,
      roomNumber: json['room_number'] as String,
      floor: json['floor'] as int?,
      status: json['status'] as String,
      roomType: json['room_types'] != null
          ? RoomTypeModel.fromJson(json['room_types'] as Map<String, dynamic>)
          : null,
    );
  }
}