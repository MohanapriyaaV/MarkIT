class RoleService {
  // Define admin roles - only these roles have admin access
  static const List<String> _adminRoles = [
    'Manager',
    'Supervisor',
    'Team Lead',
    'Assistant Manager',
    'Director',
    'CEO',
  ];

  // Define non-admin roles
  static const List<String> _nonAdminRoles = [
    'Intern',
    'Process Associates',
    'Senior Associates',
  ];

  // All valid roles in the system
  static const List<String> _allRoles = [
    'Intern',
    'Process Associates',
    'Senior Associates',
    'Manager',
    'Supervisor',
    'Team Lead',
    'Assistant Manager',
    'Director',
    'CEO',
  ];

  // Admin roles in lowercase for checking
  static const List<String> adminRoles = [
    'supervisor',
    'team_lead',
    'assistant_manager',
    'manager',
    'director',
    'ceo'
  ];

  // Role display names mapping
  static const Map<String, String> roleDisplayNames = {
    'intern': 'Intern',
    'process_associate': 'Process Associates',
    'process_associates': 'Process Associates',
    'senior_associate': 'Senior Associates',
    'senior_associates': 'Senior Associates',
    'supervisor': 'Supervisor',
    'team_lead': 'Team Lead',
    'assistant_manager': 'Assistant Manager',
    'manager': 'Manager',
    'director': 'Director',
    'ceo': 'CEO',
  };

  /// Check if a role is an admin role
  static bool isAdminRole(String role) {
    final cleanRole = _cleanRole(role);
    
    // Also check using the normalized approach
    String normalizedRole = role.toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('process_associates', 'process_associate');
    
    final isAdmin = _adminRoles.contains(cleanRole) || adminRoles.contains(normalizedRole);
    
    print('=== ROLE SERVICE DEBUG ===');
    print('Input role: "$role"');
    print('Clean role: "$cleanRole"');
    print('Normalized role: "$normalizedRole"');
    print('Is admin: $isAdmin');
    print('Admin roles: $_adminRoles');
    print('========================');
    
    return isAdmin;
  }

  /// Check if a role is a non-admin role
  static bool isNonAdminRole(String role) {
    final cleanRole = _cleanRole(role);
    return _nonAdminRoles.contains(cleanRole);
  }

  /// Check if a role is valid
  static bool isValidRole(String role) {
    final cleanRole = _cleanRole(role);
    return _allRoles.contains(cleanRole);
  }

  /// Get display name for a role (formatted properly)
  static String getDisplayName(String role) {
    final cleanRole = _cleanRole(role);
    
    // Try the new mapping first
    String normalizedRole = role.toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('process_associates', 'process_associate');
    
    if (roleDisplayNames.containsKey(normalizedRole)) {
      return roleDisplayNames[normalizedRole]!;
    }
    
    // Fallback to the original switch statement
    switch (cleanRole.toLowerCase()) {
      case 'intern':
        return 'Intern';
      case 'process associates':
        return 'Process Associates';
      case 'senior associates':
        return 'Senior Associates';
      case 'manager':
        return 'Manager';
      case 'supervisor':
        return 'Supervisor';
      case 'team lead':
        return 'Team Lead';
      case 'assistant manager':
        return 'Assistant Manager';
      case 'director':
        return 'Director';
      case 'ceo':
        return 'CEO';
      default:
        return cleanRole; // Return as-is if not found
    }
  }

  /// Get role description
  static String getRoleDescription(String role) {
    final cleanRole = _cleanRole(role);
    
    switch (cleanRole.toLowerCase()) {
      case 'intern':
        return 'Trainee with limited access';
      case 'process associates':
        return 'Standard employee access';
      case 'senior associates':
        return 'Senior employee with enhanced access';
      case 'manager':
        return 'Team management and administrative access';
      case 'supervisor':
        return 'Supervisory and administrative access';
      case 'team lead':
        return 'Team leadership and administrative access';
      case 'assistant manager':
        return 'Assistant management and administrative access';
      case 'director':
        return 'Director level administrative access';
      case 'ceo':
        return 'Full executive administrative access';
      default:
        return 'Standard access';
    }
  }

  /// Get all admin roles
  static List<String> getAdminRoles() {
    return List.from(_adminRoles);
  }

  /// Get all non-admin roles
  static List<String> getNonAdminRoles() {
    return List.from(_nonAdminRoles);
  }

  /// Get all valid roles
  static List<String> getAllRoles() {
    return List.from(_allRoles);
  }

  /// Clean and normalize role string - Enhanced version
  static String _cleanRole(String role) {
    if (role.isEmpty) return 'Process Associates'; // Default role
    
    // Remove extra whitespace and normalize
    String cleaned = role.trim();
    
    // Handle common variations and typos - Enhanced mapping
    Map<String, String> roleMapping = {
      // Intern variations
      'intern': 'Intern',
      'internship': 'Intern',
      'trainee': 'Intern',
      
      // Process Associates variations
      'process associate': 'Process Associates',
      'process associates': 'Process Associates',
      'process_associates': 'Process Associates',
      'processassociates': 'Process Associates',
      'associate': 'Process Associates',
      'associates': 'Process Associates',
      
      // Senior Associates variations
      'senior associate': 'Senior Associates',
      'senior associates': 'Senior Associates',
      'senior_associate': 'Senior Associates',
      'sr associate': 'Senior Associates',
      'sr associates': 'Senior Associates',
      
      // Manager variations
      'manager': 'Manager',
      'mgr': 'Manager',
      
      // Supervisor variations
      'supervisor': 'Supervisor',
      'super': 'Supervisor',
      'supv': 'Supervisor',
      
      // Team Lead variations
      'team lead': 'Team Lead',
      'team leader': 'Team Lead',
      'team_lead': 'Team Lead',
      'teamlead': 'Team Lead',
      'tl': 'Team Lead',
      'lead': 'Team Lead',
      
      // Assistant Manager variations
      'assistant manager': 'Assistant Manager',
      'assistant_manager': 'Assistant Manager',
      'assistantmanager': 'Assistant Manager',
      'asst manager': 'Assistant Manager',
      'ast mgr': 'Assistant Manager',
      
      // Director variations
      'director': 'Director',
      'dir': 'Director',
      
      // CEO variations
      'ceo': 'CEO',
      'chief executive officer': 'CEO',
    };
    
    // Check the enhanced mapping first
    String normalizedInput = cleaned.toLowerCase();
    if (roleMapping.containsKey(normalizedInput)) {
      return roleMapping[normalizedInput]!;
    }
    
    // If no match found, try to find the closest match in valid roles
    for (String validRole in _allRoles) {
      if (validRole.toLowerCase() == normalizedInput) {
        return validRole;
      }
    }
    
    // If still no match, return default
    return 'Process Associates';
  }

  /// Fix and normalize role data from database - Enhanced version
  static String fixRoleData(String rawRole) {
    if (rawRole.isEmpty) return 'Process Associates';
    
    // Use the enhanced _cleanRole method
    return _cleanRole(rawRole);
  }

  /// Debug method to print role information
  static void debugRole(String role) {
    print('=== ROLE DEBUG INFO ===');
    print('Original role: "$role"');
    print('Role length: ${role.length}');
    print('Role bytes: ${role.codeUnits}');
    
    // Check for invisible characters
    for (int i = 0; i < role.length; i++) {
      int charCode = role.codeUnitAt(i);
      String char = role[i];
      print('Char $i: "$char" (Code: $charCode)');
      
      // Check for common invisible characters
      if (charCode == 160) print('  ^ This is a non-breaking space!');
      if (charCode == 8203) print('  ^ This is a zero-width space!');
      if (charCode < 32 || charCode == 127) print('  ^ This is a control character!');
    }
    
    String cleaned = _cleanRole(role);
    print('Cleaned role: "$cleaned"');
    print('Is admin: ${isAdminRole(role)}');
    print('Is valid: ${isValidRole(role)}');
    print('Display name: ${getDisplayName(role)}');
    print('Description: ${getRoleDescription(role)}');
    print('=====================');
  }

  /// Get role hierarchy level (higher number = more authority)
  static int getRoleLevel(String role) {
    final cleanRole = _cleanRole(role);
    
    switch (cleanRole) {
      case 'CEO':
        return 9;
      case 'Director':
        return 8;
      case 'Manager':
        return 7;
      case 'Assistant Manager':
        return 6;
      case 'Team Lead':
        return 5;
      case 'Supervisor':
        return 4;
      case 'Senior Associates':
        return 3;
      case 'Process Associates':
        return 2;
      case 'Intern':
        return 1;
      default:
        return 2; // Default to Process Associates level
    }
  }

  /// Check if role1 has higher authority than role2
  static bool hasHigherAuthority(String role1, String role2) {
    return getRoleLevel(role1) > getRoleLevel(role2);
  }

  /// Get roles that are subordinate to the given role
  static List<String> getSubordinateRoles(String role) {
    final currentLevel = getRoleLevel(role);
    return _allRoles.where((r) => getRoleLevel(r) < currentLevel).toList();
  }

  /// Get roles that are senior to the given role
  static List<String> getSeniorRoles(String role) {
    final currentLevel = getRoleLevel(role);
    return _allRoles.where((r) => getRoleLevel(r) > currentLevel).toList();
  }

  /// Additional utility methods for better role management
  
  /// Check if a user can manage another user based on roles
  static bool canManageUser(String managerRole, String userRole) {
    return hasHigherAuthority(managerRole, userRole);
  }

  /// Get all roles that the given role can manage
  static List<String> getManageableRoles(String role) {
    return getSubordinateRoles(role);
  }

  /// Check if role has specific permissions
  static bool hasPermission(String role, String permission) {
    final cleanRole = _cleanRole(role);
    final roleLevel = getRoleLevel(cleanRole);
    
    switch (permission.toLowerCase()) {
      case 'admin':
        return isAdminRole(cleanRole);
      case 'manage_users':
        return roleLevel >= 4; // Supervisor and above
      case 'view_reports':
        return roleLevel >= 3; // Senior Associates and above
      case 'edit_data':
        return roleLevel >= 2; // Process Associates and above
      case 'basic_access':
        return roleLevel >= 1; // All roles
      default:
        return false;
    }
  }

  /// Get available permissions for a role
  static List<String> getPermissions(String role) {
    final permissions = <String>[];
    final roleLevel = getRoleLevel(_cleanRole(role));
    
    if (roleLevel >= 1) permissions.add('basic_access');
    if (roleLevel >= 2) permissions.add('edit_data');
    if (roleLevel >= 3) permissions.add('view_reports');
    if (roleLevel >= 4) permissions.add('manage_users');
    if (isAdminRole(role)) permissions.add('admin');
    
    return permissions;
  }
}