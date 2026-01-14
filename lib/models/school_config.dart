// lib/models/screen_models.dart

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

  // Factory to create from Supabase JSON
  factory SchoolConfig.fromJson(Map<String, dynamic> json) {
    return SchoolConfig(
      id: json['id'] as String,
      name: json['school_name'] as String, // Note the column name mapping
      currency: json['currency'] as String? ?? 'USD',
      address: json['address'] as String?,
      logoUrl: json['logo_url'] as String?,
      ownerId: json['owner_id'] as String,
    );
  }

  // To JSON (if needed for local storage)
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
