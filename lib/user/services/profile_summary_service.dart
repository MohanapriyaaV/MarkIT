// profile_summary_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profile_summary_model.dart';

class EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Employee?> fetchEmployeeData() async {
    try {
      final uid = _auth.currentUser?.uid;

      if (uid == null) {
        throw Exception("User not logged in.");
      }

      final doc = await _firestore
          .collection('employeeInfo')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        print("🔥 Firestore data: $data"); // Debug print to see what's actually coming from Firestore
        
        return Employee.fromFirestore(data);
      } else {
        return null;
      }
    } catch (e) {
      print("🔥 Error fetching employee data: $e");
      rethrow;
    }
  }
}