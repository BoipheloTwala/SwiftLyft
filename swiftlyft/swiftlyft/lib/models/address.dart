/// User address model
class Address {
  final String id;
  final String userId;
  final String type; // 'home', 'work', 'other'
  final String label;
  final String address;
  final Map<String, dynamic> coordinates; // {lat: double, lng: double}
  final String? instructions;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Address({
    required this.id,
    required this.userId,
    required this.type,
    required this.label,
    required this.address,
    required this.coordinates,
    this.instructions,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? 'home',
      label: json['label'] ?? '',
      address: json['address'] ?? '',
      coordinates: json['coordinates'] ?? {},
      instructions: json['instructions'],
      isDefault: json['isDefault'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'label': label,
      'address': address,
      'coordinates': coordinates,
      'instructions': instructions,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Address copyWith({
    String? id,
    String? userId,
    String? type,
    String? label,
    String? address,
    Map<String, dynamic>? coordinates,
    String? instructions,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      label: label ?? this.label,
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
      instructions: instructions ?? this.instructions,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
