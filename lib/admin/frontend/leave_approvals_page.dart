import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_leave_service.dart';

class LeaveApprovalsPage extends StatefulWidget {
  const LeaveApprovalsPage({super.key});

  @override
  State<LeaveApprovalsPage> createState() => _LeaveApprovalsPageState();
}

class _LeaveApprovalsPageState extends State<LeaveApprovalsPage> {
  final AdminLeaveService _adminLeaveService = AdminLeaveService();
  List<Map<String, dynamic>> _pendingLeaves = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPendingLeaves();
  }

  Future<void> _fetchPendingLeaves() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final teams = await _adminLeaveService.fetchTeamsForAdmin(user.uid);
      final teamIds = teams
          .map((t) => t['id'] ?? t['teamId'])
          .whereType<String>()
          .toSet();
      final leaves = await _adminLeaveService.fetchPendingLeavesForTeams(teams);
      // Extra filtering: only show leaves with a matching teamId
      final filteredLeaves = leaves
          .where((leave) => teamIds.contains(leave['teamId']))
          .toList();
      setState(() {
        _pendingLeaves = filteredLeaves;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _approveLeave(Map<String, dynamic> leave) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _adminLeaveService.approveLeave(
      memberId: leave['employeeId'],
      leaveId: leave['leaveId'],
      adminId: user.uid,
      adminName: '', // TODO: fetch admin name
      adminRole: '', // TODO: fetch admin role
    );
    _fetchPendingLeaves();
  }

  Future<String> _getEmployeeName(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('employeeInfo')
        .doc(userId)
        .get();
    return doc.exists ? (doc['name'] ?? userId) : userId;
  }

  Widget _leaveTile(Map<String, dynamic> leave) {
    return FutureBuilder<String>(
      future: _getEmployeeName(leave['employeeId'] ?? ''),
      builder: (context, snapshot) {
        final employeeName = snapshot.data ?? leave['employeeId'];
        return Card(
          margin: const EdgeInsets.all(12),
          child: ListTile(
            title: Text('Employee: $employeeName'),
            subtitle: Text('Reason: ${leave['reason']}\nStatus: ${leave['status']}'),
            trailing: ElevatedButton(
              onPressed: () => _approveLeave(leave),
              child: const Text('Approve'),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Leave Approvals')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error:\n$_errorMessage'))
              : ListView.builder(
                  itemCount: _pendingLeaves.length,
                  itemBuilder: (context, index) {
                    final leave = _pendingLeaves[index];
                    return _leaveTile(leave);
                  },
                ),
    );
  }
}
