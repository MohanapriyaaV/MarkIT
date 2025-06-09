import '../services/login_service.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final bool isAdmin;
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
    this.createdAt,
    this.lastLogin,
    this.department,
    this.domain,
    this.manager,
    this.location,
    this.phoneNumber,
    this.joiningDate,
    this.emergencyLeave,
  }) : isAdmin = isAdmin ?? RoleService.isAdminRole(role);

  // Factory constructor to create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    final role = RoleService.fixRoleData(map['role']?.toString() ?? 'Process Associates');
    
    return UserModel(
      uid: map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      role: role,
      isAdmin: map['isAdmin'] as bool? ?? RoleService.isAdminRole(role),
      createdAt: map['createdAt'] != null 
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      lastLogin: map['lastLogin'] != null 
          ? DateTime.tryParse(map['lastLogin'].toString())
          : null,
      department: map['department']?.toString(),
      domain: map['domain']?.toString(),
      manager: map['Manager']?.toString() ?? map['manager']?.toString(),
      location: map['location']?.toString(),
      phoneNumber: map['phoneNumber']?.toString(),
      joiningDate: map['JoiningDate']?.toString() ?? map['joiningDate']?.toString(),
      emergencyLeave: map['emergency_leave'] as int? ?? map['emergencyLeave'] as int? ?? 0,
    );
  }

  // Factory constructor to create UserModel from Firestore DocumentSnapshot
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    final role = RoleService.fixRoleData(data['role']?.toString() ?? 'Process Associates');
    
    return UserModel(
      uid: uid,
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      role: role,
      isAdmin: data['isAdmin'] as bool? ?? RoleService.isAdminRole(role),
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

  // Convert UserModel to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'isAdmin': isAdmin,
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

  // Convert UserModel to Firestore Map (for saving to database)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'isAdmin': isAdmin,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'department': department,
      'domain': domain,
      'Manager': manager, // Note: Capital M to match your Firestore field
      'location': location,
      'phoneNumber': phoneNumber,
      'JoiningDate': joiningDate, // Note: Capital J to match your Firestore field
      'emergency_leave': emergencyLeave,
    };
  }

  // Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    bool? isAdmin,
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

  // Get display name for the role
  String get roleDisplayName => RoleService.getDisplayName(role);

  // Get role description
  String get roleDescription => RoleService.getRoleDescription(role);

  // Get role level (hierarchy)
  int get roleLevel => RoleService.getRoleLevel(role);

  // Check if this user has higher authority than another user
  bool hasHigherAuthorityThan(UserModel other) {
    return RoleService.hasHigherAuthority(role, other.role);
  }

  // Get subordinate roles
  List<String> get subordinateRoles => RoleService.getSubordinateRoles(role);

  // Get senior roles
  List<String> get seniorRoles => RoleService.getSeniorRoles(role);

  // Check if user can manage another user (based on role hierarchy)
  bool canManage(UserModel other) {
    return isAdmin && hasHigherAuthorityThan(other);
  }

  // Get user's permissions (you can expand this based on your needs)
  Map<String, bool> get permissions {
    return {
      'canViewDashboard': true,
      'canEditProfile': true,
      'canApplyLeave': true,
      'canViewReports': isAdmin,
      'canManageUsers': isAdmin,
      'canManageRoles': roleLevel >= 7, // Manager level and above
      'canAccessAdminPanel': isAdmin,
      'canApproveLeave': roleLevel >= 4, // Supervisor level and above
      'canViewAllEmployees': isAdmin,
      'canExportData': isAdmin,
      'canManageSettings': roleLevel >= 8, // Director level and above
    };
  }

  // Check if user has specific permission
  bool hasPermission(String permission) {
    return permissions[permission] ?? false;
  }

  // Get a formatted string for display
  String get displayString => '$name ($roleDisplayName)';

  // Get initials for avatar
  String get initials {
    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    } else {
      return email[0].toUpperCase();
    }
  }

  // Get formatted joining date
  String get formattedJoiningDate {
    if (joiningDate != null && joiningDate!.isNotEmpty) {
      try {
        DateTime date = DateTime.parse(joiningDate!);
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return joiningDate!;
      }
    }
    return 'N/A';
  }

  // Get formatted last login
  String get formattedLastLogin {
    if (lastLogin != null) {
      Duration difference = DateTime.now().difference(lastLogin!);
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    }
    return 'Never';
  }

  @override
  String toString() {
    return 'UserModel{uid: $uid, email: $email, name: $name, role: $role, isAdmin: $isAdmin, roleLevel: $roleLevel}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email;

  @override
  int get hashCode => uid.hashCode ^ email.hashCode;
}

// Extension for additional UserModel functionality
extension UserModelExtensions on UserModel {
  // Check if user is a specific role
  bool isRole(String targetRole) {
    return RoleService.fixRoleData(role) == RoleService.fixRoleData(targetRole);
  }

  // Check if user is in any of the provided roles
  bool isAnyRole(List<String> targetRoles) {
    String currentRole = RoleService.fixRoleData(role);
    return targetRoles.any((targetRole) => 
        currentRole == RoleService.fixRoleData(targetRole));
  }

  // Get user status based on role and admin status
  String get statusText {
    if (isAdmin) {
      return 'Administrator';
    } else {
      return 'Employee';
    }
  }

  // Get color based on role level (for UI purposes)
  String get roleColor {
    if (roleLevel >= 8) return '#FF5722'; // Director+: Deep Orange
    if (roleLevel >= 6) return '#FF9800'; // Manager+: Orange
    if (roleLevel >= 4) return '#2196F3'; // Supervisor+: Blue
    if (roleLevel >= 3) return '#4CAF50'; // Senior: Green
    return '#757575'; // Others: Grey
  }
}