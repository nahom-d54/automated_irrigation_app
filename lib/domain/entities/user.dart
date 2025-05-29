enum UserRole {
  admin,
  operator,
  viewer,
}

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final Map<String, dynamic>? permissions;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.permissions,
  });

  String get fullName => '$firstName $lastName';
  
  bool get canControlIrrigation => role == UserRole.admin || role == UserRole.operator;
  bool get canViewData => true; // All users can view data
  bool get canManageUsers => role == UserRole.admin;
  bool get canModifySettings => role == UserRole.admin || role == UserRole.operator;
}
