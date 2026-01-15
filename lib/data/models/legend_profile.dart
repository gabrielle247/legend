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
