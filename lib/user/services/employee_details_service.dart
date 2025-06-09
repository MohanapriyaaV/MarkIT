import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee_details_model.dart';

class EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'employeeInfo';

  // Save employee data to Firestore
  Future<bool> saveEmployeeData(Employee employee) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(employee.empId)
          .set(employee.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error saving employee data: $e');
      return false;
    }
  }

  // Get employee data from Firestore
  Future<Employee?> getEmployeeData(String empId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(empId)
          .get();
      
      if (doc.exists) {
        return Employee.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting employee data: $e');
      return null;
    }
  }

  // Update employee data
  Future<bool> updateEmployeeData(String empId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(empId)
          .update(updates);
      return true;
    } catch (e) {
      print('Error updating employee data: $e');
      return false;
    }
  }

  // Delete employee data
  Future<bool> deleteEmployeeData(String empId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(empId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting employee data: $e');
      return false;
    }
  }

  // Check if employee exists
  Future<bool> employeeExists(String empId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(empId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking employee existence: $e');
      return false;
    }
  }
}