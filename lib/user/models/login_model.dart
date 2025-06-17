import '../services/login_service.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final bool isAdmin;
  final bool isDirector;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final String? department;
  final String? domain;
  final String? manager;
  final String? location;
  final String? phoneNumber;
  final String? joiningDate;
  final int? emergencyLeave;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    bool? isAdmin,
    bool? isDirector,
    this.createdAt,
    this.lastLogin,
    this.department,
    this.domain,
    this.manager,
    this.location,
    this.phoneNumber,
    this.joiningDate,
    this.emergencyLeave,
  }) : isAdmin = isAdmin ?? RoleService.isAdminRole(role),
       isDirector = isDirector ?? RoleService.isDirector(role);

  /// Factory constructor from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    final role = RoleService.fixRoleData(map['role']?.toString() ?? 'Process Associate');
    
    return UserModel(
      uid: map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      role: role,
      isAdmin: map['isAdmin'] as bool? ?? RoleService.isAdminRole(role),
      isDirector: map['isDirector'] as bool? ?? RoleService.isDirector(role),
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null,
      lastLogin: map['lastLogin'] != null ? DateTime.tryParse(map['lastLogin'].toString()) : null,
      department: map['department']?.toString(),
      domain: map['domain']?.toString(),
      manager: map['Manager']?.toString() ?? map['manager']?.toString(),
      location: map['location']?.toString(),
      phoneNumber: map['phoneNumber']?.toString(),
      joiningDate: map['JoiningDate']?.toString() ?? map['joiningDate']?.toString(),
      emergencyLeave: map['emergency_leave'] as int? ?? map['emergencyLeave'] as int? ?? 0,
    );
  }

  /// Factory constructor from Firestore
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    final role = RoleService.fixRoleData(data['role']?.toString() ?? 'Process Associate');
    
    return UserModel(
      uid: uid,
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      role: role,
      isAdmin: data['isAdmin'] as bool? ?? RoleService.isAdminRole(role),
      isDirector: data['isDirector'] as bool? ?? RoleService.isDirector(role),
      createdAt: data['createdAt']?.toDate(),
      lastLogin: data['lastLogin']?.toDate(),
      department: data['department']?.toString(),
      domain: data['domain']?.toString(),
      manager: data['Manager']?.toString() ?? data['manager']?.toString(),
      location: data['location']?.toString(),
      phoneNumber: data['phoneNumber']?.toString(),
      joiningDate: data['JoiningDate']?.toString() ?? data['joiningDate']?.toString(),
      emergencyLeave: data['emergency_leave'] as int? ?? data['emergencyLeave'] as int? ?? 0,
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'isAdmin': isAdmin,
      'isDirector': isDirector,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'department': department,
      'domain': domain,
      'manager': manager,
      'location': location,
      'phoneNumber': phoneNumber,
      'joiningDate': joiningDate,
      'emergencyLeave': emergencyLeave,
    };
  }

  /// Convert to Firestore Map
  Map<String, dynamic> toFirestoreMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'isAdmin': isAdmin,
      'isDirector': isDirector,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'department': department,
      'domain': domain,
      'Manager': manager,
      'location': location,
      'phoneNumber': phoneNumber,
      'JoiningDate': joiningDate,
      'emergency_leave': emergencyLeave,
    };
  }

  /// Create copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    bool? isAdmin,
    bool? isDirector,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? department,
    String? domain,
    String? manager,
    String? location,
    String? phoneNumber,
    String? joiningDate,
    int? emergencyLeave,
  }) {
    final newRole = role ?? this.role;
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: newRole,
      isAdmin: isAdmin ?? RoleService.isAdminRole(newRole),
      isDirector: isDirector ?? RoleService.isDirector(newRole),
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      department: department ?? this.department,
      domain: domain ?? this.domain,
      manager: manager ?? this.manager,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      joiningDate: joiningDate ?? this.joiningDate,
      emergencyLeave: emergencyLeave ?? this.emergencyLeave,
    );
  }

  /// Get display name for role
  String get roleDisplayName => RoleService.getDisplayName(role);

  /// Get role description
  String get roleDescription => RoleService.getRoleDescription(role);

  /// Get role level
  int get roleLevel => RoleService.getRoleLevel(role);

  /// Check if has higher authority than another user
  bool hasHigherAuthorityThan(UserModel other) => RoleService.hasHigherAuthority(role, other.role);

  /// Get subordinate roles
  List<String> get subordinateRoles => RoleService.getSubordinateRoles(role);

  /// Get senior roles
  List<String> get seniorRoles => RoleService.getSeniorRoles(role);

  /// Check if can manage another user
  bool canManage(UserModel other) => isAdmin && hasHigherAuthorityThan(other);

  /// Get user permissions
  Map<String, bool> get permissions => RoleService.getPermissions(role);

  /// Check if has specific permission
  bool hasPermission(String permission) => permissions[permission] ?? false;

  /// Get display string
  String get displayString => '$name ($roleDisplayName)';

  /// Get initials for avatar
  String get initials {
    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  /// Get status text
  String get statusText {
    if (isDirector) return 'Director';
    if (isAdmin) return 'Administrator';
    return 'Employee';
  }

  /// Get role color for UI
  String get roleColor {
    if (isDirector) return '#FF5722'; // Director: Deep Orange
    if (roleLevel >= 7) return '#FF9800'; // Manager level: Orange
    if (roleLevel >= 5) return '#2196F3'; // Lead level: Blue
    if (roleLevel >= 3) return '#4CAF50'; // Team Lead: Green
    return '#757575'; // Others: Grey
  }

  @override
  String toString() => 'UserModel{uid: $uid, email: $email, name: $name, role: $role, isAdmin: $isAdmin, isDirector: $isDirector}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && uid == other.uid && email == other.email;

  @override
  int get hashCode => uid.hashCode ^ email.hashCode;
}

/// Extension for additional UserModel functionality
extension UserModelExtensions on UserModel {
  /// Check if user is a specific role
  bool isRole(String targetRole) => RoleService.fixRoleData(role) == RoleService.fixRoleData(targetRole);

  /// Check if user is in any of the provided roles
  bool isAnyRole(List<String> targetRoles) {
    String currentRole = RoleService.fixRoleData(role);
    return targetRoles.any((targetRole) => currentRole == RoleService.fixRoleData(targetRole));
  }

  /// Check if should show admin buttons (only Director)
  bool get shouldShowAdminButtons => isDirector;
}