class RoomTypeModel{
  final int id;
  final int hotelId;
  final String name;
  final String? description;
  final int maxOccupancy;
  final String? bedType;
  final double? sizeSqm;
  final List<String> amenities;
  final List<String> images;

  RoomTypeModel({
    required this.id,
    required this.hotelId,
    required this.name,
    this.description,
    required this.maxOccupancy,
    this.bedType,
    this.sizeSqm,
    required this.amenities,
    required this.images,
  });

  factory RoomTypeModel.fromJson(Map<String, dynamic> json) {
    return RoomTypeModel(
      id: json['id'] as int,
      hotelId: json['hotel_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      maxOccupancy: json['max_occupancy'] as int,
      bedType: json['bed_type'] as String?,
      sizeSqm: json['size_sqm'] != null
          ? (json['size_sqm'] as num).toDouble()
          : null,
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'] as List)
          : [],
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : [],
    );
  }

}