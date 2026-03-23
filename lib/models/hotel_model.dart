class HotelModel
{
  final int id;
  final String name;
  final String? description;
  final String? address;
  final String? city;
  final String? country;
  final String? phone;
  final String?email;
  final int? starRating;
  final List<String> amenities;
  final List<String> images;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HotelModel({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.city,
    this.country,
    this.phone,
    this.email,
    this.starRating,
    required this.amenities,
    required this.images,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory HotelModel.fromJson(Map<String , dynamic>json)
  {
    return HotelModel(
        id: json['id'] as int,
        name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      starRating: json['star_rating'] as int?,
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'] as List)
          : [],
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : [],
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
  Map<String , dynamic> toJson()
  {
    return{
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'country': country,
      'phone': phone,
      'email': email,
      'star_rating': starRating,
      'amenities': amenities,
      'images': images,
      'is_active': isActive,
    };
  }
}