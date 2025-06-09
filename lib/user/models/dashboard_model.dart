import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class DashboardButton {
  final String title;
  final IconData icon;
  final LinearGradient gradient;

  DashboardButton(this.title, this.icon, this.gradient);
}

class UserData {
  final String? name;
  final String? role;
  final String? uid;
  final bool isAdmin;
  final Map rawData;

  UserData({
    this.name,
    this.role,
    this.uid,
    this.isAdmin = false,
    required this.rawData,
  });

  factory UserData.fromMap(Map? data) {
    if (data == null) {
      return UserData(rawData: {});
    }

    final name = data['name'] ?? 'User';
    final role = data['role'] ?? 'Process Associates';
    final uid = data['uid'] as String?;
    final isAdmin = data['isAdmin'] ?? false;

    return UserData(
      name: name,
      role: role,
      uid: uid,
      isAdmin: isAdmin,
      rawData: data,
    );
  }

  String get displayName => name ?? 'User';
  String get userRole => role ?? 'process_associate';
  String get welcomeText => "Welcome, ${displayName}!";
  
  String get subtitleText {
    if (isAdmin) {
      return "Admin Dashboard - Manage your team";
    }
    return "Have a productive day";
  }
}

class AdminInfo {
  final String name;
  final String role;
  final String displayRole;

  AdminInfo({
    required this.name,
    required this.role,
    required this.displayRole,
  });

  factory AdminInfo.fromUserData(UserData userData) {
    return AdminInfo(
      name: userData.displayName,
      role: userData.userRole,
      displayRole: RoleService.getDisplayName(userData.userRole),
    );
  }
}