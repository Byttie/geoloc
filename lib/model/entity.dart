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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lon': lon,
      'image': image,
    };
  }

  factory Entity.fromJson(Map<String, dynamic> json) {
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

  String? getFullImageUrl() {
    if (image == null || image!.isEmpty) return null;
    const String baseUrl = 'https://labs.anontech.info/cse489/t3/';
    return '$baseUrl$image';
  }

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