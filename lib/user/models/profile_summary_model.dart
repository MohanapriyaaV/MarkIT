// profile_summary_model.dart
class Employee {
  final String? name;
  final String? role;
  final String? domain;
  final String email;
  final String? phoneNumber;
  final String? location;
  final String? joiningDate;
  final String empId;

  Employee({
    this.name,
    this.role,
    this.domain,
    required this.email,
    this.phoneNumber,
    this.location,
    this.joiningDate,
    required this.empId,
  });

  factory Employee.fromFirestore(Map<String, dynamic> data) {
    return Employee(
      name: data['name'] as String?,
      role: data['role'] as String?,
      domain: data['domain'] as String?, // Make sure domain is properly extracted
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String?,
      location: data['location'] as String?,
      joiningDate: data['JoiningDate'] as String?, // Note: 'JoiningDate' with capital J
      empId: data['empId'] as String? ?? 'VistaES01',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'domain': domain,
      'email': email,
      'phoneNumber': phoneNumber,
      'location': location,
      'JoiningDate': joiningDate,
      'empId': empId,
    };
  }

  @override
  String toString() {
    return 'Employee(name: $name, role: $role, domain: $domain, email: $email, phoneNumber: $phoneNumber, location: $location, joiningDate: $joiningDate, empId: $empId)';
  }
}