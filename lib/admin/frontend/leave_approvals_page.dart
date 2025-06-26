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

  Future<String> _getTeamName(String teamId) async {
    final doc = await FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .get();
    return doc.exists ? (doc['teamName'] ?? teamId) : teamId;
  }

  void _showLeaveDetailsDialog(Map<String, dynamic> leave) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _getLeaveDetails(leave),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              );
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text('Failed to load leave details: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text('No leave details found.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            }
            final details = snapshot.data!;
            return AlertDialog(
              title: const Text('Leave Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Employee: ${details['employeeName'] ?? 'N/A'}'),
                  Text('Team name: ${details['teamName'] ?? 'N/A'}'),
                  Text('Leave applied at: ${details['appliedAt'] ?? 'N/A'}'),
                  Text('Leave start date: ${details['startDate'] ?? 'N/A'}'),
                  Text('Leave end date: ${details['endDate'] ?? 'N/A'}'),
                  Text('Reason: ${details['reason'] ?? 'N/A'}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _updateLeaveStatus(leave, 'approved');
                    Navigator.of(context).pop();
                  },
                  child: const Text('Approve'),
                ),
                TextButton(
                  onPressed: () async {
                    await _updateLeaveStatus(leave, 'rejected');
                    Navigator.of(context).pop();
                  },
                  child: const Text('Reject'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getLeaveDetails(Map<String, dynamic> leave) async {
    final employeeId = leave['employeeId'] ?? '';
    final teamId = leave['teamId'] ?? '';
    if (employeeId.isEmpty || teamId.isEmpty) {
      throw Exception('employeeId or teamId is missing. employeeId: $employeeId, teamId: $teamId');
    }
    String employeeName = employeeId;
    String teamName = teamId;
    try {
      employeeName = await _getEmployeeName(employeeId);
    } catch (e) {
      employeeName = 'Not found ($employeeId)';
    }
    try {
      teamName = await _getTeamName(teamId);
    } catch (e) {
      teamName = 'Not found ($teamId)';
    }
    // Format Firestore Timestamp to readable string
    String formatDate(dynamic ts) {
      if (ts == null) return '';
      if (ts is String) return ts;
      if (ts is DateTime) return ts.toString().split(' ')[0];
      if (ts is Timestamp) return ts.toDate().toString().split(' ')[0];
      return ts.toString();
    }
    // Handle leave end date calculation
    String leaveEndDate = '';
    if (leave['endDateTime'] != null) {
      DateTime endDate;
      if (leave['endDateTime'] is Timestamp) {
        endDate = (leave['endDateTime'] as Timestamp).toDate();
      } else if (leave['endDateTime'] is DateTime) {
        endDate = leave['endDateTime'];
      } else {
        endDate = DateTime.tryParse(leave['endDateTime'].toString()) ?? DateTime.now();
      }
      int numberOfDays = 1;
      if (leave['numberOfDays'] != null) {
        numberOfDays = int.tryParse(leave['numberOfDays'].toString()) ?? 1;
      }
      if (numberOfDays > 1) {
        endDate = endDate.add(Duration(days: numberOfDays - 1));
      } else if (numberOfDays == 1) {
        endDate = endDate.add(const Duration(days: 1));
      }
      leaveEndDate = formatDate(endDate);
    }
    return {
      'employeeName': employeeName,
      'teamName': teamName,
      'appliedAt': formatDate(leave['appliedAt']),
      'startDate': formatDate(leave['startDate']),
      'endDate': leaveEndDate,
      'reason': leave['reason'] ?? '',
    };
  }

  Future<void> _updateLeaveStatus(Map<String, dynamic> leave, String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('leaveapplication')
        .doc(leave['employeeId'])
        .collection('userLeaves')
        .doc(leave['leaveId'])
        .update({'status': status});
    _fetchPendingLeaves();
  }

  Widget _leaveTile(Map<String, dynamic> leave) {
    return FutureBuilder<String>(
      future: _getEmployeeName(leave['employeeId'] ?? ''),
      builder: (context, snapshot) {
        final employeeName = snapshot.data ?? leave['employeeId'];
        return Card(
          margin: const EdgeInsets.all(12),
          child: ListTile(
            title: Text(employeeName),
            trailing: ElevatedButton(
              onPressed: () => _showLeaveDetailsDialog(leave),
              child: const Text('View Details'),
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
