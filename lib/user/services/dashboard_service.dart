import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';

// Role service to check admin roles consistently
class RoleService {
  static const List<String> adminRoles = [
    'supervisor',
    'team_lead',
    'assistant_manager',
    'manager',
    'director',
    'ceo'
  ];

  static const Map<String, String> roleDisplayNames = {
    'process_associate': 'Process Associate',
    'senior_associate': 'Senior Associate',
    'supervisor': 'Supervisor',
    'team_lead': 'Team Lead',
    'assistant_manager': 'Assistant Manager',
    'manager': 'Manager',
    'director': 'Director',
    'ceo': 'CEO',
  };

  static bool isAdminRole(String role) {
    String normalizedRole = role.toLowerCase().replaceAll(' ', '_');
    return adminRoles.contains(normalizedRole);
  }

  static String getDisplayName(String role) {
    String normalizedRole = role.toLowerCase().replaceAll(' ', '_');
    return roleDisplayNames[normalizedRole] ?? role;
  }
}

class DashboardService {
  static List<DashboardButton> getDashboardButtons({required bool isAdmin}) {
    List<DashboardButton> buttons = [
      DashboardButton(
        "Profile Summary",
        Icons.person_outline,
        const LinearGradient(
          colors: [Color(0xFF6A5ACD), Color(0xFF9370DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      DashboardButton(
        "Mark Present",
        Icons.check_circle_outline,
        const LinearGradient(
          colors: [Color(0xFF32CD32), Color(0xFF00FA9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      DashboardButton(
        "Apply Leave",
        Icons.event_note_outlined,
        const LinearGradient(
          colors: [Color(0xFF4169E1), Color(0xFF6495ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      DashboardButton(
        "Apply Emergency Leave",
        Icons.warning_amber_outlined,
        const LinearGradient(
          colors: [Color(0xFFFF6347), Color(0xFFFF7F50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      DashboardButton(
        "Pending Leave Requests",
        Icons.pending_actions_outlined,
        const LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      DashboardButton(
        "Leave Overview",
        Icons.view_list_outlined,
        const LinearGradient(
          colors: [Color(0xFF4B0082), Color(0xFF663399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      DashboardButton(
        "Attendance Overview",
        Icons.analytics_outlined,
        const LinearGradient(
          colors: [Color(0xFF20B2AA), Color(0xFF48D1CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      DashboardButton(
        "Notifications",
        Icons.notifications_outlined,
        const LinearGradient(
          colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      DashboardButton(
        "Calendar",
        Icons.calendar_today_outlined,
        const LinearGradient(
          colors: [Color(0xFF8A2BE2), Color(0xFFBA55D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ];

    // Add Admin Functionality button only for admin users
    if (isAdmin) {
      buttons.add(
        DashboardButton(
          "Admin Functionality",
          Icons.admin_panel_settings_outlined,
          const LinearGradient(
            colors: [Color(0xFFDC143C), Color(0xFFB22222)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }

    return buttons;
  }

  static UserData processUserData(Map<String, dynamic>? routeData) {
    UserData userData = UserData.fromMap(routeData);
    
    // Check admin status from user data first
    bool isAdmin = userData.isAdmin;
    
    // If not admin, double check using role service
    if (!isAdmin && userData.userRole.isNotEmpty) {
      isAdmin = RoleService.isAdminRole(userData.userRole);
    }
    
    // Return updated user data with correct admin status
    return UserData(
      name: userData.name,
      role: userData.role,
      uid: userData.uid,
      isAdmin: isAdmin,
      rawData: userData.rawData,
    );
  }
}