// ==========================================
// FILE: ./models/school_config.dart
// ==========================================

class SchoolConfig {
  final String id;
  final String name;
  final String currency;
  final String? address;
  final String? logoUrl;
  final String ownerId;

  SchoolConfig({
    required this.id,
    required this.name,
    required this.currency,
    this.address,
    this.logoUrl,
    required this.ownerId,
  });

  factory SchoolConfig.fromJson(Map<String, dynamic> json) {
    return SchoolConfig(
      id: json['id'] as String,
      name: json['school_name'] as String,
      currency: json['currency'] as String? ?? 'USD',
      address: json['address'] as String?,
      logoUrl: json['logo_url'] as String?,
      ownerId: json['owner_id'] as String,
    );
  }

  // Used for PowerSync Local Saves
  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'school_name': name,
      'currency': currency,
      'address': address,
      'logo_url': logoUrl,
      'owner_id': ownerId,
    };
  }
  
  // Used for Supabase Remote Saves (Standard JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_name': name,
      'currency': currency,
      'address': address,
      'logo_url': logoUrl,
      'owner_id': ownerId,
    };
  }
}