// lib/models/screen_models.dart

/// Sir Legend's Profile (Logged In User).
class LegendProfile {
  final String id;
  final String fullName;
  final String role; // OWNER, ADMIN
  final bool isBanned;

  LegendProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.isBanned = false,
  });

  factory LegendProfile.fromRow(Map<String, dynamic> row) {
    return LegendProfile(
      id: (row['id'] as String?) ?? '',
      fullName: (row['full_name'] as String?) ?? 'Unknown User',
      role: (row['role'] as String?) ?? 'USER',
      isBanned: (row['is_banned'] == 1) || (row['is_banned'] == true),
    );
  }
}

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

/// Dashboard Statistics (Aggregated).
class DashboardStats {
  final int totalStudents;
  final double totalOwed;
  final double collectedToday;
  final int pendingInvoices;

  DashboardStats({
    this.totalStudents = 0,
    this.totalOwed = 0.0,
    this.collectedToday = 0.0,
    this.pendingInvoices = 0,
  });
}

/// Menu Items for the Drawer/Nav.
class MenuItem {
  final String title;
  final String route;
  final dynamic icon; // IconData usually

  MenuItem(this.title, this.route, this.icon);
}

/// Notification / Insight Item.
class InsightItem {
  final String title;
  final String message;
  final String type; // ALERT, INFO
  final DateTime time;

  InsightItem({
    required this.title,
    required this.message,
    required this.type,
    required this.time,
  });
}
