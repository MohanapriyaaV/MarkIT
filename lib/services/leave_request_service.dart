import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/leave_request.dart';

class LeaveService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<List<LeaveRequest>> fetchUserLeaves() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('DEBUG: No user logged in');
        return [];
      }

      debugPrint('DEBUG: Current user ID: ${user.uid}');
      debugPrint('DEBUG: User email: ${user.email}');

      // Updated: Access nested subcollection 'userLeaves' under leaveapplication/{user.uid}
      final snapshot = await _firestore
          .collection('leaveapplication')
          .doc(user.uid)
          .collection('userLeaves')
          .where('status', isEqualTo: 'Pending')
          .get();

      debugPrint('DEBUG: Found ${snapshot.docs.length} pending leave requests');

      final results = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        debugPrint('DEBUG: Document ID: ${doc.id}');
        debugPrint('DEBUG: Document data: $data');
        return LeaveRequest.fromMap(data, doc.id);
      }).toList();

      // FIXED: Sort by startDateTime descending (most recent first)
      results.sort((a, b) {
        final aTime = a.startDateTime;
        final bTime = b.startDateTime;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      debugPrint('DEBUG: Returning ${results.length} leave requests');
      return results;
    } catch (e, stackTrace) {
      debugPrint('DEBUG: Error fetching leaves: $e');
      debugPrint('DEBUG: Stack trace: $stackTrace');
      return [];
    }
  }
}
