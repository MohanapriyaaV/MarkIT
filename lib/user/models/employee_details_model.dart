class Employee {
  final String? name;
  final String? role;
  final String? department;
  final String email;
  final String? phoneNumber;
  final String? location;
  final String? joiningDate;
  final String empId;
  final String? userId; // Employee ID field
  final int emergencyLeave;
  final String? editedBy;
  final String? editedAt;
  final Map<String, dynamic>? leaveLimits;
  final Map<String, dynamic>? shiftTiming;
  final String? teamId;

  Employee({
    this.name,
    this.role,
    this.department,
    required this.email,
    this.phoneNumber,
    this.location,
    this.joiningDate,
    required this.empId,
    this.userId,
    this.emergencyLeave = 0,
    this.editedBy,
    this.editedAt,
    this.leaveLimits,
    this.shiftTiming,
    this.teamId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name ?? '',
      'role': role ?? '',
      'department': department ?? '',
      'email': email,
      'phoneNumber': phoneNumber ?? '',
      'location': location ?? '',
      'JoiningDate': joiningDate ?? '',
      'empId': empId,
      'userId': userId ?? '',
      'emergency_leave': emergencyLeave,
      'editedBy': editedBy ?? '',
      'editedAt': editedAt ?? '',
      'leaveLimits': leaveLimits ?? {},
      'shiftTiming': shiftTiming ?? {},
      'teamId': teamId ?? '',
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    // Defensive: always parse leaveLimits and shiftTiming as Map<String, dynamic>
    Map<String, dynamic>? parseMap(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }
    return Employee(
      name: map['name'],
      role: map['role'],
      department: map['department'],
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      location: map['location'],
      joiningDate: map['JoiningDate'],
      empId: map['empId'] ?? '',
      userId: map['userId'],
      emergencyLeave: map['emergency_leave'] ?? 0,
      editedBy: map['editedBy'],
      editedAt: map['editedAt'],
      leaveLimits: parseMap(map['leaveLimits']),
      shiftTiming: parseMap(map['shiftTiming']),
      teamId: map['teamId'],
    );
  }

  Employee copyWith({
    String? name,
    String? role,
    String? department,
    String? email,
    String? phoneNumber,
    String? location,
    String? joiningDate,
    String? empId,
    String? userId,
    int? emergencyLeave,
    String? editedBy,
    String? editedAt,
    Map<String, dynamic>? leaveLimits,
    Map<String, dynamic>? shiftTiming,
    String? teamId,
  }) {
    return Employee(
      name: name ?? this.name,
      role: role ?? this.role,
      department: department ?? this.department,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      joiningDate: joiningDate ?? this.joiningDate,
      empId: empId ?? this.empId,
      userId: userId ?? this.userId,
      emergencyLeave: emergencyLeave ?? this.emergencyLeave,
      editedBy: editedBy ?? this.editedBy,
      editedAt: editedAt ?? this.editedAt,
      leaveLimits: leaveLimits ?? this.leaveLimits,
      shiftTiming: shiftTiming ?? this.shiftTiming,
      teamId: teamId ?? this.teamId,
    );
  }
}

class EmployeeFormData {
  // Department options
  static const List<String> departmentOptions = [
    'Production',
    'Other Designation',
    'Admin',
    'Recruiters'
  ];

  // Production roles
  static const List<String> productionRoles = [
    'Associate Trainee',
    'Process Associate',
    'Senior Process Associate',
    'Spark',
    'Assistant Team Lead',
    'Team Lead',
    'Project Lead',
    'Assistant Project Manager',
    'Project Manager'
  ];

  // Other Designation roles
  static const List<String> otherDesignationRoles = [
    'General Project Manager',
    'HR Executive',
    'Assistant Manager HR',
    'Manager HR',
    'Director'
  ];

  // Admin roles
  static const List<String> adminRoles = [
    'IT Executive',
    'Senior IT Executive'
  ];

  // Recruiter roles
  static const List<String> recruiterRoles = [
    'HR Recruiter',
    'Lead Talent Acquisition'
  ];
}