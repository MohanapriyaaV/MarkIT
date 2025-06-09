class Employee {
  final String? name;
  final String? role;
  final String? domain;
  final String email;
  final String? phoneNumber;
  final String? location;
  final String? joiningDate;
  final String empId;
  final int emergencyLeave;

  Employee({
    this.name,
    this.role,
    this.domain,
    required this.email,
    this.phoneNumber,
    this.location,
    this.joiningDate,
    required this.empId,
    this.emergencyLeave = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name ?? '',
      'role': role ?? '',
      'domain': domain ?? '',
      'email': email,
      'phoneNumber': phoneNumber ?? '',
      'location': location ?? '',
      'JoiningDate': joiningDate ?? '',
      'empId': empId,
      'emergency_leave': emergencyLeave,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      name: map['name'],
      role: map['role'],
      domain: map['domain'],
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      location: map['location'],
      joiningDate: map['JoiningDate'],
      empId: map['empId'] ?? '',
      emergencyLeave: map['emergency_leave'] ?? 0,
    );
  }
}

class EmployeeFormData {
  // Role options
  static const List<String> roleOptions = [
    'Intern',
    'Process Associates',
    'Senior Associates',
    'Supervisor',
    'Team Lead',
    'Assistant Manager',
    'Manager',
    'Other'
  ];

  // Other role options (when "Other" is selected)
  static const List<String> otherRoleOptions = [
    'Director',
    'CEO'
  ];

  // Domain options
  static const List<String> domainOptions = [
    'Software Development',
    'Data Annotation',
    'Quality Control'
  ];
}