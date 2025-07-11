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
  List<Map<String, dynamic>> _historyLeaves = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPendingLeaves();
    _fetchHistoryLeaves();
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

  Future<void> _fetchHistoryLeaves() async {
    // Add a loading indicator if you have one
    setState(() {
      _loading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _historyLeaves = [];
      });
      return;
    }

    try {
      print('DEBUG: Fetching history leaves - starting...');

      // Directly query for teams this admin manages
      print('DEBUG: Fetching teams for admin ${user.uid}');
      final teamsSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .where('admins', arrayContains: user.uid)
          .get();

      print('DEBUG: Found ${teamsSnapshot.docs.length} teams for this admin');

      if (teamsSnapshot.docs.isEmpty) {
        print('DEBUG: No teams found for this admin');
        setState(() {
          _historyLeaves = [];
          _loading = false;
        });
        return;
      }

      // Get team IDs and member lists
      final List<String> teamIds = [];
      final Set<String> allTeamMembers = {};

      for (var teamDoc in teamsSnapshot.docs) {
        teamIds.add(teamDoc.id);
        final members = List<String>.from(teamDoc.data()['members'] ?? []);
        allTeamMembers.addAll(members);
      }

      print('DEBUG: Found ${allTeamMembers.length} team members across ${teamIds.length} teams');

      // For each team member, query their leaves that are approved/rejected
      final List<Map<String, dynamic>> allProcessedLeaves = [];

      // Break into smaller batches to avoid timeout issues
      const int batchSize = 10;
      for (var i = 0; i < allTeamMembers.length; i += batchSize) {
        final end = (i + batchSize < allTeamMembers.length) ? i + batchSize : allTeamMembers.length;
        final batch = allTeamMembers.toList().sublist(i, end);

        await Future.wait(
          batch.map((memberId) async {
            try {
              // Query leaves for each member
              final leavesSnapshot = await FirebaseFirestore.instance
                  .collection('leaveapplication')
                  .doc(memberId)
                  .collection('userLeaves')
                  .where('status', whereIn: ['approved', 'rejected', 'Approved', 'Rejected'])
                  .get();

              // Process each leave
              for (var leaveDoc in leavesSnapshot.docs) {
                final leaveData = leaveDoc.data();
                leaveData['leaveId'] = leaveDoc.id;
                leaveData['employeeId'] = memberId;

                // Only add leaves for teams this admin manages
                final leaveTeamId = leaveData['teamId'];
                if (teamIds.contains(leaveTeamId)) {
                  allProcessedLeaves.add(leaveData);
                }
              }
            } catch (memberError) {
              print('DEBUG: Error fetching leaves for member $memberId: $memberError');
            }
          }),
        );
      }

      print('DEBUG: Found ${allProcessedLeaves.length} processed leaves');

      // Sort by most recent action
      allProcessedLeaves.sort((a, b) {
        final aTime = a['approvedAt'] ?? a['rejectedAt'] ?? a['appliedAt'];
        final bTime = b['approvedAt'] ?? b['rejectedAt'] ?? b['appliedAt'];
        if (aTime == null || bTime == null) return 0;
        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime); // Newest first
        }
        return 0;
      });

      setState(() {
        _historyLeaves = allProcessedLeaves;
        _loading = false;
      });

      print('DEBUG: History leaves fetch complete - found ${allProcessedLeaves.length} leaves');

    } catch (e) {
      print('ERROR: Failed to fetch history leaves: $e');
      setState(() {
        _historyLeaves = [];
        _loading = false;
      });
    }
  }

  Future<void> _approveLeave(Map<String, dynamic> leave) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get admin name and role for proper recording
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('employeeInfo')
          .doc(user.uid)
          .get();

      final adminName = adminDoc.exists ? (adminDoc.data()?['name'] as String? ?? '') : '';
      final adminRole = adminDoc.exists ? (adminDoc.data()?['role'] as String? ?? '') : '';

      await _adminLeaveService.approveLeave(
        memberId: leave['employeeId'],
        leaveId: leave['leaveId'],
        adminId: user.uid,
        adminName: adminName,
        adminRole: adminRole,
      );

      // Refresh both pending leaves and history
      _fetchPendingLeaves();
      _fetchHistoryLeaves();
    } catch (e) {
      // Handle error
      print('Error approving leave: $e');
    }
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

  void _showLeaveDetailsPage(Map<String, dynamic> leave) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeaveDetailsPage(
          leave: leave,
          getEmployeeName: _getEmployeeName,
          getTeamName: _getTeamName,
          onStatusUpdate: (status) async {
            await _updateLeaveStatus(leave, status);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _updateLeaveStatus(
    Map<String, dynamic> leave,
    String status,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get admin details to properly record who approved/rejected
      final adminDoc = await FirebaseFirestore.instance
          .collection('employeeInfo')
          .doc(user.uid)
          .get();

      final adminName = adminDoc.exists ? (adminDoc.data()?['name'] as String? ?? '') : '';
      final adminRole = adminDoc.exists ? (adminDoc.data()?['role'] as String? ?? '') : '';

      // Update with more details
      final Map<String, dynamic> updateData = {
        'status': status,
      };

      // Add appropriate fields based on approval status
      if (status == 'approved') {
        updateData.addAll({
          'approvedBy': user.uid,
          'approvedByName': adminName,
          'approvedByRole': adminRole,
          'approvedAt': FieldValue.serverTimestamp(),
        });
      } else if (status == 'rejected') {
        updateData.addAll({
          'rejectedBy': user.uid,
          'rejectedByName': adminName,
          'rejectedByRole': adminRole,
          'rejectedAt': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseFirestore.instance
          .collection('leaveapplication')
          .doc(leave['employeeId'])
          .collection('userLeaves')
          .doc(leave['leaveId'])
          .update(updateData);

      // Refresh both pending leaves and history
      _fetchPendingLeaves();
      _fetchHistoryLeaves();
    } catch (e) {
      print('Error updating leave status: $e');
    }
  }

  Widget _leaveTile(Map<String, dynamic> leave) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _getEmployeeName(leave['employeeId'] ?? ''),
        _getTeamName(leave['teamId'] ?? ''),
      ]),
      builder: (context, snapshot) {
        final employeeName = snapshot.hasData
            ? snapshot.data![0] as String
            : leave['employeeId'];
        final teamName = snapshot.hasData
            ? snapshot.data![1] as String
            : leave['teamId'];
        final leaveType = leave['reason'] ?? 'N/A';
        return Card(
          margin: const EdgeInsets.all(12),
          child: ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Employee: $employeeName'),
                Text('Team: $teamName'),
                Text('Leave Type: $leaveType'),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _showLeaveDetailsPage(leave),
              child: const Text('View Details'),
            ),
          ),
        );
      },
    );
  }

  Widget _historyTile(Map<String, dynamic> leave) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _getEmployeeName(leave['employeeId'] ?? ''),
        _getTeamName(leave['teamId'] ?? ''),
      ]),
      builder: (context, snapshot) {
        final employeeName = snapshot.hasData
            ? snapshot.data![0] as String
            : leave['employeeId'];
        final teamName = snapshot.hasData
            ? snapshot.data![1] as String
            : leave['teamId'];
        final leaveType = leave['reason'] ?? 'N/A';
        return Card(
          margin: const EdgeInsets.all(12),
          child: ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Employee: $employeeName'),
                Text('Team: $teamName'),
                Text('Leave Type: $leaveType'),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _showHistoryLeaveDetailsPage(leave),
              child: const Text('View Details'),
            ),
          ),
        );
      },
    );
  }

  void _showHistoryLeaveDetailsPage(Map<String, dynamic> leave) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryLeaveDetailsPage(leave: leave),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Approvals')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('Error:\n$_errorMessage'))
          : Column(
              children: [
                // First half - Pending Leaves
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.blue.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pending Leave Approvals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _fetchPendingLeaves,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _pendingLeaves.isEmpty
                      ? const Center(child: Text('No pending leave approvals'))
                      : ListView.builder(
                          itemCount: _pendingLeaves.length,
                          itemBuilder: (context, index) {
                            final leave = _pendingLeaves[index];
                            return _leaveTile(leave);
                          },
                        ),
                ),

                // Divider between sections
                const Divider(thickness: 2, height: 2),

                // Second half - History of approved/rejected leaves
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.green.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'History of Approved/Rejected Leaves',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _fetchHistoryLeaves,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _historyLeaves.isEmpty
                      ? const Center(child: Text('No leave history found'))
                      : ListView.builder(
                          itemCount: _historyLeaves.length,
                          itemBuilder: (context, index) {
                            final leave = _historyLeaves[index];
                            return _historyTile(leave);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class LeaveDetailsPage extends StatefulWidget {
  final Map<String, dynamic> leave;
  final Future<String> Function(String) getEmployeeName;
  final Future<String> Function(String) getTeamName;
  final Future<void> Function(String status) onStatusUpdate;

  const LeaveDetailsPage({
    Key? key,
    required this.leave,
    required this.getEmployeeName,
    required this.getTeamName,
    required this.onStatusUpdate,
  }) : super(key: key);

  @override
  State<LeaveDetailsPage> createState() => _LeaveDetailsPageState();
}

class _LeaveDetailsPageState extends State<LeaveDetailsPage> {
  late Future<Map<String, dynamic>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _getLeaveDetails(widget.leave);
  }

  Future<Map<String, dynamic>> _getLeaveDetails(
    Map<String, dynamic> leave,
  ) async {
    final employeeId = leave['employeeId'] ?? '';
    final teamId = leave['teamId'] ?? '';
    String employeeName = employeeId;
    String teamName = teamId;
    try {
      employeeName = await widget.getEmployeeName(employeeId);
    } catch (e) {
      employeeName = 'Not found ($employeeId)';
    }
    try {
      teamName = await widget.getTeamName(teamId);
    } catch (e) {
      teamName = 'Not found ($teamId)';
    }
    String formatDate(dynamic ts) {
      if (ts == null) return '';
      if (ts is String) return ts;
      if (ts is DateTime) return ts.toString().split(' ')[0];
      if (ts is Timestamp) return ts.toDate().toString().split(' ')[0];
      return ts.toString();
    }

    String leaveEndDate = '';
    if (leave['endDateTime'] != null) {
      DateTime endDate;
      if (leave['endDateTime'] is Timestamp) {
        endDate = (leave['endDateTime'] as Timestamp).toDate();
      } else if (leave['endDateTime'] is DateTime) {
        endDate = leave['endDateTime'];
      } else {
        endDate =
            DateTime.tryParse(leave['endDateTime'].toString()) ??
            DateTime.now();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Details')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load leave details: \\${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No leave details found.'));
          }
          final details = snapshot.data!;
          // Extract all fields
          final leaveType = details['reason'] ?? 'N/A';
          final status =
              widget.leave['status']?.toString().toUpperCase() ?? 'PENDING';
          final startDate = details['startDate'] ?? 'N/A';
          final endDate = details['endDate'] ?? 'N/A';
          final numDays = widget.leave['numberOfDays']?.toString() ?? 'N/A';
          final leaveDuration =
              widget.leave['leaveDuration']?.toString() ?? 'N/A';
          final appliedAt = details['appliedAt'] ?? 'N/A';
          final explanation = widget.leave['explanation'] ?? 'N/A';
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                // Leave Type and Status
                Text(
                  leaveType,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'PENDING'
                            ? Colors.orange
                            : status == 'APPROVED'
                            ? Colors.green
                            : Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Leave Duration Section
                const Text(
                  'Leave Duration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Start Date', startDate),
                _buildDetailRow('End Date', endDate),
                _buildDetailRow('Number of Days', '$numDays day(s)'),
                _buildDetailRow('Leave Duration', '$leaveDuration day(s)'),
                const SizedBox(height: 24),
                // Application Details Section
                const Text(
                  'Application Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Applied At', appliedAt),
                const SizedBox(height: 24),
                // Explanation Section
                const Text(
                  'Explanation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    explanation,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => widget.onStatusUpdate('approved'),
                      child: const Text('Approve'),
                    ),
                    ElevatedButton(
                      onPressed: () => widget.onStatusUpdate('rejected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryLeaveDetailsPage extends StatelessWidget {
  final Map<String, dynamic> leave;
  const HistoryLeaveDetailsPage({Key? key, required this.leave})
    : super(key: key);

  Future<Map<String, String>> _getAdminInfo(String? adminUid) async {
    if (adminUid == null) return {'name': 'N/A', 'role': 'N/A'};
    final doc = await FirebaseFirestore.instance
        .collection('employeeInfo')
        .doc(adminUid)
        .get();
    if (!doc.exists) return {'name': 'N/A', 'role': 'N/A'};
    return {'name': doc['name'] ?? 'N/A', 'role': doc['role'] ?? 'N/A'};
  }

  @override
  Widget build(BuildContext context) {
    final status = leave['status']?.toString().toUpperCase() ?? 'N/A';
    final adminUid = status == 'APPROVED' ? leave['approvedBy'] : leave['rejectedBy'];

    return Scaffold(
      appBar: AppBar(
        title: Text('${status == 'REJECTED' ? 'Rejected' : 'Approved'} Leave Details'),
        backgroundColor: status == 'REJECTED' ? Colors.red.shade700 : Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _getAdminInfo(adminUid),
        builder: (context, snapshot) {
          final adminName = snapshot.data?['name'] ?? 'N/A';
          final adminRole = snapshot.data?['role'] ?? 'N/A';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Section with custom styling
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: status == 'REJECTED' ? Colors.red.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: status == 'REJECTED' ? Colors.red.shade400 : Colors.green.shade400,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              status == 'REJECTED' ? Icons.cancel : Icons.check_circle,
                              color: status == 'REJECTED' ? Colors.red : Colors.green,
                              size: 32,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Status: $status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: status == 'REJECTED' ? Colors.red.shade800 : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          '${status == 'REJECTED' ? 'Rejected' : 'Approved'} By:',
                          adminName,
                        ),
                        _buildDetailRow(
                          '${status == 'REJECTED' ? 'Rejected' : 'Approved'} By Role:',
                          adminRole,
                        ),
                        if (leave['rejectionRemarks'] != null && status == 'REJECTED')
                          _buildDetailRow('Rejection Reason:', leave['rejectionRemarks']),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Employee Information
                  const Text(
                    'Employee Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: _getEmployeeName(leave['employeeId'] ?? ''),
                    builder: (context, snapshot) {
                      final empName = snapshot.data ?? leave['employeeId'] ?? 'N/A';
                      return _buildDetailRow('Employee Name:', empName);
                    },
                  ),
                  FutureBuilder<String>(
                    future: _getTeamName(leave['teamId'] ?? ''),
                    builder: (context, snapshot) {
                      final teamName = snapshot.data ?? leave['teamId'] ?? 'N/A';
                      return _buildDetailRow('Team Name:', teamName);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Leave Details
                  const Text(
                    'Leave Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Leave Type:', leave['reason'] ?? 'N/A'),
                  _buildDetailRow('Start Date:', _formatDate(leave['startDate'])),
                  _buildDetailRow('End Date:', _formatDate(leave['endDate'])),
                  _buildDetailRow('Number of Days:', '${leave['numberOfDays'] ?? 'N/A'}'),
                  _buildDetailRow('Applied At:', _formatDate(leave['appliedAt'])),

                  const SizedBox(height: 24),

                  // Explanation
                  const Text(
                    'Explanation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      leave['explanation'] ?? 'No explanation provided',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) return date.toDate().toString().split(' ')[0];
    return date.toString();
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../services/admin_leave_service.dart';
// //import 'leave_details_page.dart'; // Add if you have one or create this screen

// class LeaveApprovalsPage extends StatefulWidget {
//   const LeaveApprovalsPage({super.key});

//   @override
//   State<LeaveApprovalsPage> createState() => _LeaveApprovalsPageState();
// }

// class _LeaveApprovalsPageState extends State<LeaveApprovalsPage> {
//   final AdminLeaveService _adminLeaveService = AdminLeaveService();
//   List<Map<String, dynamic>> _pendingLeaves = [];
//   List<Map<String, dynamic>> _historyLeaves = [];
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchPendingLeaves();
//     _fetchHistoryLeaves();
//   }

//   Future<Map<String, String>> _getAdminDetails() async {
//   final user = FirebaseAuth.instance.currentUser;
//   if (user == null) return {'name': '', 'role': ''};
//   final doc = await FirebaseFirestore.instance
//       .collection('employeeInfo')
//       .doc(user.uid)
//       .get();
//   if (!doc.exists) return {'name': '', 'role': ''};
//   return {
//     'name': doc['name'] ?? '',
//     'role': doc['role'] ?? '',
//   };
// }

//   Future<void> _fetchPendingLeaves() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//     try {
//       final teams = await _adminLeaveService.fetchTeamsForAdmin(user.uid);
//       final teamIds = teams.map((t) => t['id'] ?? t['teamId']).whereType<String>().toSet();
//       final leaves = await _adminLeaveService.fetchPendingLeavesForTeams(teams);
//       final filteredLeaves = leaves.where((leave) => teamIds.contains(leave['teamId'])).toList();
//       setState(() {
//         _pendingLeaves = filteredLeaves;
//       });
//     } catch (_) {}
//   }

//   Future<void> _fetchHistoryLeaves() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//     try {
//       final teams = await _adminLeaveService.fetchTeamsForAdmin(user.uid);
//       final teamIds = teams.map((t) => t['id'] ?? t['teamId']).whereType<String>().toSet();
//       final leaves = await _adminLeaveService.fetchAllLeavesForTeams(teams);
//       final filtered = leaves
//           .where((leave) =>
//               teamIds.contains(leave['teamId']) &&
//               (leave['status'] == 'approved' || leave['status'] == 'rejected'))
//           .toList();
//       setState(() {
//         _historyLeaves = filtered;
//       });
//     } catch (_) {}
//   }

//   Future<String> _getEmployeeName(String userId) async {
//     final doc = await FirebaseFirestore.instance.collection('employeeInfo').doc(userId).get();
//     return doc.exists ? (doc['name'] ?? userId) : userId;
//   }

//   Future<String> _getTeamName(String teamId) async {
//     final doc = await FirebaseFirestore.instance.collection('teams').doc(teamId).get();
//     return doc.exists ? (doc['teamName'] ?? teamId) : teamId;
//   }

//   Future<Map<String, String>> _getRejectedByDetails(String uid) async {
//     final doc = await FirebaseFirestore.instance.collection('employeeInfo').doc(uid).get();
//     if (doc.exists) {
//       return {
//         'name': doc['name'] ?? '',
//         'role': doc['role'] ?? '',
//       };
//     }
//     return {'name': 'Unknown', 'role': 'Unknown'};
//   }

//   void _showLeaveDetailsPage(Map<String, dynamic> leave) async {
//     final rejectedBy = leave['rejectedBy'] ?? leave['approvedBy'] ?? '';
//     final rejectedDetails = await _getRejectedByDetails(rejectedBy);
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => Scaffold(
//           appBar: AppBar(title: const Text('Leave Details')),
//           body: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Status: ${leave['status']}'),
//                 const SizedBox(height: 8),
//                 Text('Handled By: ${rejectedDetails['name']}'),
//                 const SizedBox(height: 4),
//                 Text('Role: ${rejectedDetails['role']}'),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _leaveTile(Map<String, dynamic> leave) {
//     return FutureBuilder<List<dynamic>>(
//       future: Future.wait([
//         _getEmployeeName(leave['employeeId'] ?? ''),
//         _getTeamName(leave['teamId'] ?? ''),
//       ]),
//       builder: (context, snapshot) {
//         final employeeName = snapshot.hasData ? snapshot.data![0] as String : leave['employeeId'];
//         final teamName = snapshot.hasData ? snapshot.data![1] as String : leave['teamId'];
//         final leaveType = leave['reason'] ?? 'N/A';
//         return Card(
//           margin: const EdgeInsets.all(12),
//           child: ListTile(
//             title: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Employee: $employeeName'),
//                 Text('Team: $teamName'),
//                 Text('Leave Type: $leaveType'),
//               ],
//             ),
//             trailing: ElevatedButton(
//               onPressed: () => _showLeaveDetailsPage(leave),
//               child: const Text('View Details'),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Leave Approvals')),
//       body: Column(
//         children: [
//           Expanded(
//             child: _pendingLeaves.isEmpty
//                 ? const Center(child: Text('No pending leaves.'))
//                 : ListView.builder(
//                     itemCount: _pendingLeaves.length,
//                     itemBuilder: (_, i) => _leaveTile(_pendingLeaves[i]),
//                   ),
//           ),
//           const Divider(thickness: 1),
//           const Padding(
//             padding: EdgeInsets.all(10),
//             child: Text(
//               "History of Approved/Rejected Leaves:",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: _historyLeaves.isEmpty
//                 ? const Center(child: Text('No history found.'))
//                 : ListView.builder(
//                     itemCount: _historyLeaves.length,
//                     itemBuilder: (_, i) => _leaveTile(_historyLeaves[i]),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
