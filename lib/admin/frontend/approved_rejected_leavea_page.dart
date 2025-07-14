import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApprovedRejectedLeavesPage extends StatefulWidget {
  const ApprovedRejectedLeavesPage({super.key});

  @override
  State<ApprovedRejectedLeavesPage> createState() => _ApprovedRejectedLeavesPageState();
}

class _ApprovedRejectedLeavesPageState extends State<ApprovedRejectedLeavesPage> {
  List<Map<String, dynamic>> _historyLeaves = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistoryLeaves();
  }

  Future<void> _fetchHistoryLeaves() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
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
        _errorMessage = e.toString();
      });
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
        final status = leave['status']?.toString().toUpperCase() ?? 'N/A';
        
        return Card(
          margin: const EdgeInsets.all(12),
          child: ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Employee: $employeeName'),
                Text('Team: $teamName'),
                Text('Leave Type: $leaveType'),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'APPROVED' ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
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
      appBar: AppBar(
        title: const Text('Approved/Rejected Leaves'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('Error:\n$_errorMessage'))
          : Column(
              children: [
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