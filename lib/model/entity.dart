class Entity {
  final int? id;
  final String title;
  final double lat;
  final double lon;
  final String? image;

  Entity({
    this.id,
    required this.title,
    required this.lat,
    required this.lon,
    this.image,
  });

  // Convert Entity to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lon': lon,
      'image': image,
    };
  }

  // Create Entity from Map (database query result)
  factory Entity.fromMap(Map<String, dynamic> map) {
    return Entity(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      lat: map['lat']?.toDouble() ?? 0.0,
      lon: map['lon']?.toDouble() ?? 0.0,
      image: map['image'],
    );
  }

  // Convert Entity to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lon': lon,
      'image': image,
    };
  }

  // Create Entity from JSON (API response)
  factory Entity.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse coordinate values
    double parseCoordinate(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        if (value.isEmpty) return 0.0;
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return Entity(
      id: json['id']?.toInt(),
      title: json['title'] ?? '',
      lat: parseCoordinate(json['lat']),
      lon: parseCoordinate(json['lon']),
      image: json['image'],
    );
  }

  // Get full image URL with base URL
  String? getFullImageUrl() {
    if (image == null || image!.isEmpty) return null;
    const String baseUrl = 'https://labs.anontech.info/cse489/t3/';
    return '$baseUrl$image';
  }

  // Create a copy with updated fields
  Entity copyWith({
    int? id,
    String? title,
    double? lat,
    double? lon,
    String? image,
  }) {
    return Entity(
      id: id ?? this.id,
      title: title ?? this.title,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      image: image ?? this.image,
    );
  }

  @override
  String toString() {
    return 'Entity{id: $id, title: $title, lat: $lat, lon: $lon, image: $image}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          lat == other.lat &&
          lon == other.lon &&
          image == other.image;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      lat.hashCode ^
      lon.hashCode ^
      image.hashCode;
} 