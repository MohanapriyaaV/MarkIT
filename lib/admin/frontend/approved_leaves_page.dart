import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_leave_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApprovedLeavesPage extends StatefulWidget {
  const ApprovedLeavesPage({super.key});

  @override
  State<ApprovedLeavesPage> createState() => _ApprovedLeavesPageState();
}

class _ApprovedLeavesPageState extends State<ApprovedLeavesPage> {
  final AdminLeaveService _adminLeaveService = AdminLeaveService();
  List<Map<String, dynamic>> _approvedLeaves = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchApprovedLeaves();
  }

  Future<String> _getEmployeeName(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('employeeInfo')
        .doc(userId)
        .get();
    return doc.exists ? (doc['name'] ?? userId) : userId;
  }

  Future<String> _getAdminName(String adminId) async {
    final doc = await FirebaseFirestore.instance
        .collection('employeeInfo')
        .doc(adminId)
        .get();
    return doc.exists ? (doc['name'] ?? adminId) : adminId;
  }

  Future<void> _fetchApprovedLeaves() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final teams = await _adminLeaveService.fetchTeamsForAdmin(user.uid);
    final leaves = await _adminLeaveService.fetchApprovedLeavesForTeams(teams);
    setState(() {
      _approvedLeaves = leaves;
      _loading = false;
    });
  }

  Widget _leaveTile(Map<String, dynamic> leave) {
    return FutureBuilder<String>(
      future: _getEmployeeName(leave['employeeId'] ?? ''),
      builder: (context, empSnapshot) {
        final employeeName = empSnapshot.data ?? leave['employeeId'];
        return FutureBuilder<String>(
          future: _getAdminName(leave['approvedBy'] ?? ''),
          builder: (context, adminSnapshot) {
            final adminName = adminSnapshot.data ?? leave['approvedBy'];
            final adminRole = leave['approvedByRole'] ?? '';
            return Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                title: Text('Employee: $employeeName'),
                subtitle: Text(
                  'Approved by: $adminName ($adminRole)\nReason: ${leave['reason']}',
                ),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approved Leaves')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _approvedLeaves.length,
              itemBuilder: (context, index) {
                final leave = _approvedLeaves[index];
                return _leaveTile(leave);
              },
            ),
    );
  }
}
