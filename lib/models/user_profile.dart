class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String userType;
  final String identificationNumber;
  final String? phone;
  final String? address;
  final String? libraryId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.userType,
    required this.identificationNumber,
    this.phone,
    this.address,
    this.libraryId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      userType: json['user_type'],
      identificationNumber: json['identification_number'],
      phone: json['phone'],
      address: json['address'],
      libraryId: json['library_id'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'user_type': userType,
      'identification_number': identificationNumber,
      'phone': phone,
      'address': address,
      'library_id': libraryId,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
