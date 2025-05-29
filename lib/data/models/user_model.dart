import 'package:irrigation_app/domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.role,
    super.profileImageUrl,
    required super.createdAt,
    super.lastLoginAt,
    super.isActive,
    super.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '', 
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      role: _parseUserRole(json['is_superuser']),
      profileImageUrl: json['profile_image_url'] ?? json['profileImageUrl'],
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      lastLoginAt: json['last_login_at'] != null || json['lastLoginAt'] != null
          ? _parseDateTime(json['last_login_at'] ?? json['lastLoginAt'])
          : null,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      permissions: json['permissions'] as Map<String, dynamic>?,
    );
  }

  static UserRole _parseUserRole(dynamic role) {
    if (role == null) return UserRole.viewer;
    
    if (role as bool==true){
      return UserRole.admin;
    }
    return UserRole.operator;
    // switch (role.toString().toLowerCase()) {
    //   case 'admin':
    //     return UserRole.admin;
    //   case 'operator':
    //     return UserRole.operator;
    //   case 'viewer':
    //   default:
    //     return UserRole.viewer;
    // }
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    
    if (dateTime is String) {
      return DateTime.parse(dateTime);
    } else if (dateTime is num) {
      return DateTime.fromMillisecondsSinceEpoch((dateTime * 1000).toInt());
    }
    
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role.name,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_active': isActive,
      'permissions': permissions,
    };
  }
}
