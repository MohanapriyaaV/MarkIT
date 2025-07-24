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
          .set(employee.toMap(),     SetOptions(merge: true));
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

  // Check if employee ID (userId) already exists
  Future<bool> employeeIdExists(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking employee ID existence: $e');
      return false;
    }
  }

  // Get employee by userId
  Future<Employee?> getEmployeeByUserId(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return Employee.fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting employee by userId: $e');
      return null;
    }
  }

  // Fetch all employees
  Future<List<Employee>> getAllEmployees() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collectionName).get();
      return snapshot.docs.map((doc) => Employee.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching all employees: $e');
      return [];
    }
  }

  // Update employee data with edit log
  Future<bool> updateEmployeeWithLog(String empId, Map<String, dynamic> updates, String editedBy) async {
    try {
      updates['editedBy'] = editedBy;
      updates['editedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection(_collectionName).doc(empId).update(updates);
      return true;
    } catch (e) {
      print('Error updating employee with log: $e');
      return false;
    }
  }

  // Utility: Update all employees' session times to HH:mm:ss format
  Future<void> updateAllSessionTimesToHHMMSSFormat() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collectionName).get();
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic>? shiftTiming = data['shiftTiming'] != null ? Map<String, dynamic>.from(data['shiftTiming']) : null;
        if (shiftTiming != null) {
          bool needsUpdate = false;
          for (var key in ['session1Login', 'session1Logout', 'session2Login', 'session2Logout']) {
            var value = shiftTiming[key];
            if (value != null && value is String) {
              final parts = value.split(":");
              if (parts.length == 2) {
                shiftTiming[key] = value + ":00";
                needsUpdate = true;
              } else if (parts.length != 3) {
                // Try DateTime parse fallback
                final dt = DateTime.tryParse(value);
                if (dt != null) {
                  shiftTiming[key] = dt.hour.toString().padLeft(2, '0') + ':' + dt.minute.toString().padLeft(2, '0') + ':' + dt.second.toString().padLeft(2, '0');
                  needsUpdate = true;
                }
              }
            } else if (value != null && value is Map && value.containsKey('seconds')) {
              final seconds = value['seconds'];
              if (seconds is int) {
                final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
                shiftTiming[key] = dt.hour.toString().padLeft(2, '0') + ':' + dt.minute.toString().padLeft(2, '0') + ':' + dt.second.toString().padLeft(2, '0');
                needsUpdate = true;
              }
            }
          }
          if (needsUpdate) {
            await _firestore.collection(_collectionName).doc(doc.id).update({'shiftTiming': shiftTiming});
          }
        }
      }
      print('All session times updated to HH:mm:ss format.');
    } catch (e) {
      print('Error updating session times: $e');
    }
  }
}