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
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
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
    'Project Manager',
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