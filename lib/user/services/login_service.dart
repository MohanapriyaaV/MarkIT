class RoleService {
  // Production roles (User access)
  static const List<String> productionRoles = [
    'Associate Trainee',
    'Process Associate', 
    'Senior Process Associate',
    'Spark',
    'Assistant Team Lead',
    'Team Lead',
  ];

  // Other Designation roles (Mixed access)
  static const List<String> otherDesignationRoles = [
    'Project Manager',
    'HR Executive',
    'Assistant Manager HR', 
    'Manager HR',
    'Director'
  ];

  // Admin roles (IT roles)
  static const List<String> adminRoles = [
    'IT Executive',
    'Senior IT Executive'
  ];

  // Recruiter roles (User access)
  static const List<String> recruiterRoles = [
    'HR Recruiter',
    'Lead Talent Acquisition'
  ];

  // Roles with admin access (from production + other designation)
  static const List<String> _adminAccessRoles = [
    'Project Lead',
    'Assistant Project Manager', 
    'Project Manager',
    'Assistant Manager HR',
    'Manager HR',
    'Director'
  ];

  /// Check if a role has admin access
  static bool isAdminRole(String role) {
    final cleanRole = fixRoleData(role);
    return adminRoles.contains(cleanRole) || _adminAccessRoles.contains(cleanRole);
  }

  /// Check if role is Director (highest admin level)
  static bool isDirector(String role) {
    return fixRoleData(role) == 'Director';
  }

  /// Get display name for a role
  static String getDisplayName(String role) {
    return fixRoleData(role);
  }

  /// Get role description
  static String getRoleDescription(String role) {
    final cleanRole = fixRoleData(role);
    if (isDirector(cleanRole)) return 'Director level - Full administrative access';
    if (isAdminRole(cleanRole)) return 'Administrative access';
    return 'Standard user access';
  }

  /// Get all valid roles
  static List<String> getAllRoles() {
    return [
      ...productionRoles,
      'Project Lead',
      'Assistant Project Manager',
      ...otherDesignationRoles,
      ...adminRoles,
      ...recruiterRoles,
    ];
  }

  /// Fix and normalize role data
  static String fixRoleData(String rawRole) {
    if (rawRole.isEmpty) return 'Process Associate';
    
    final role = rawRole.trim();
    final allRoles = getAllRoles();
    
    // Find exact match (case insensitive)
    for (String validRole in allRoles) {
      if (validRole.toLowerCase() == role.toLowerCase()) {
        return validRole;
      }
    }
    
    // Common variations mapping
    final roleMapping = {
      'associate trainee': 'Associate Trainee',
      'process associate': 'Process Associate',
      'senior process associate': 'Senior Process Associate',
      'spark': 'Spark',
      'assistant team lead': 'Assistant Team Lead',
      'team lead': 'Team Lead',
      'project lead': 'Project Lead',
      'assistant project manager': 'Assistant Project Manager', 
      'project manager': 'Project Manager',
      'hr executive': 'HR Executive',
      'assistant manager hr': 'Assistant Manager HR',
      'manager hr': 'Manager HR',
      'director': 'Director',
      'it executive': 'IT Executive',
      'senior it executive': 'Senior IT Executive',
      'hr recruiter': 'HR Recruiter',
      'lead talent acquisition': 'Lead Talent Acquisition',
    };
    
    final normalizedRole = role.toLowerCase();
    return roleMapping[normalizedRole] ?? 'Process Associate';
  }

  /// Get role hierarchy level
  static int getRoleLevel(String role) {
    final cleanRole = fixRoleData(role);
    
    switch (cleanRole) {
      case 'Director': return 10;
      case 'Manager HR': return 9;
      case 'Assistant Manager HR': return 8;
      case 'Senior IT Executive': return 8;
      case 'Project Manager': return 7;
      case 'IT Executive': return 7;
      case 'Assistant Project Manager': return 6;
      case 'Project Lead': return 5;
      case 'Lead Talent Acquisition': return 4;
      case 'Team Lead': return 3;
      case 'Assistant Team Lead': return 2;
      case 'Senior Process Associate': return 2;
      case 'HR Recruiter': return 2;
      case 'HR Executive': return 2;
      case 'Spark': return 1;
      case 'Process Associate': return 1;
      case 'Associate Trainee': return 1;
      default: return 1;
    }
  }

  /// Check if role1 has higher authority than role2
  static bool hasHigherAuthority(String role1, String role2) {
    return getRoleLevel(role1) > getRoleLevel(role2);
  }

  /// Get subordinate roles
  static List<String> getSubordinateRoles(String role) {
    final currentLevel = getRoleLevel(role);
    return getAllRoles().where((r) => getRoleLevel(r) < currentLevel).toList();
  }

  /// Get senior roles
  static List<String> getSeniorRoles(String role) {
    final currentLevel = getRoleLevel(role);
    return getAllRoles().where((r) => getRoleLevel(r) > currentLevel).toList();
  }

  /// Check if user can manage another user
  static bool canManageUser(String managerRole, String userRole) {
    return hasHigherAuthority(managerRole, userRole);
  }

  /// Get permissions for a role
  static Map<String, bool> getPermissions(String role) {
    final isAdmin = isAdminRole(role);
    final isDir = isDirector(role);
    final level = getRoleLevel(role);
    
    return {
      'canViewDashboard': true,
      'canEditProfile': true,
      'canApplyLeave': true,
      'canViewReports': isAdmin,
      'canManageUsers': isAdmin,
      'canManageRoles': level >= 7,
      'canAccessAdminPanel': isAdmin,
      'canApproveLeave': level >= 3,
      'canViewAllEmployees': isAdmin,
      'canExportData': isAdmin,
      'canManageSettings': isDir, // Only Director
      'showAdminButtons': isDir, // Only Director shows admin functionality
    };
  }
}