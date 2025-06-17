// profile_summary_model.dart
class Employee {
  final String? name;
  final String? role;
  final String? department; // Changed from domain to department
  final String email;
  final String? phoneNumber;
  final String? location;
  final String? joiningDate;
  final String userId; // Changed from empId to userId

  Employee({
    this.name,
    this.role,
    this.department, // Changed from domain to department
    required this.email,
    this.phoneNumber,
    this.location,
    this.joiningDate,
    required this.userId, // Changed from empId to userId
  });

  factory Employee.fromFirestore(Map<String, dynamic> data) {
    return Employee(
      name: data['name'] as String?,
      role: data['role'] as String?,
      department: data['department'] as String?, // Now extracts department field
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String?,
      location: data['location'] as String?,
      joiningDate: data['JoiningDate'] as String?, // Note: 'JoiningDate' with capital J
      userId: data['userId'] as String? ?? 'VISTA0001', // Now extracts userId field
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'department': department, // Changed from domain to department
      'email': email,
      'phoneNumber': phoneNumber,
      'location': location,
      'JoiningDate': joiningDate,
      'userId': userId, // Changed from empId to userId
    };
  }

  @override
  String toString() {
    return 'Employee(name: $name, role: $role, department: $department, email: $email, phoneNumber: $phoneNumber, location: $location, joiningDate: $joiningDate, userId: $userId)';
  }
}