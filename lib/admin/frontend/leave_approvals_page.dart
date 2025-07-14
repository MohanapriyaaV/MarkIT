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

      // Refresh pending leaves
      _fetchPendingLeaves();
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

  // Show leave details for pending leaves
  void _showPendingLeaveDetailsPage(Map<String, dynamic> leave) {
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
            // Refresh both pending and history lists after status update
            _fetchPendingLeaves();
            _fetchLeaveHistory();
          },
        ),
      ),
    );
  }

  // Show leave details for history leaves (read-only)
  void _showHistoryLeaveDetailsPage(Map<String, dynamic> leave) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeaveDetailsPage(
          leave: leave,
          getEmployeeName: _getEmployeeName,
          getTeamName: _getTeamName,
          onStatusUpdate: null, // No actions for history leaves
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
        // Get rejection remarks before proceeding
        String? rejectionRemarks = await _getRejectionRemarks();
        if (rejectionRemarks == null) {
          // User cancelled the rejection, don't proceed
          return;
        }

        updateData.addAll({
          'rejectedBy': user.uid,
          'rejectedByName': adminName,
          'rejectedByRole': adminRole,
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectionRemarks': rejectionRemarks,
        });
      }

      await FirebaseFirestore.instance
          .collection('leaveapplication')
          .doc(leave['employeeId'])
          .collection('userLeaves')
          .doc(leave['leaveId'])
          .update(updateData);

      // Refresh pending leaves
      _fetchPendingLeaves();
    } catch (e) {
      print('Error updating leave status: $e');
    }
  }

  Future<String?> _getRejectionRemarks() async {
    final TextEditingController remarksController = TextEditingController();
    String? result;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rejection Reason'),
          content: TextField(
            controller: remarksController,
            decoration: const InputDecoration(
              hintText: 'Please enter the reason for rejecting this leave request',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                result = remarksController.text;
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    return result;
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
              onPressed: () => _showPendingLeaveDetailsPage(leave),
              child: const Text('View Details'),
            ),
          ),
        );
      },
    );
  }

  // Display history leave tile
  Widget _historyLeaveTile(Map<String, dynamic> leave) {
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
        final status = leave['status']?.toString().toUpperCase() ?? 'UNKNOWN';

        // Set color based on status
        Color statusColor = Colors.grey;
        if (status == 'APPROVED') {
          statusColor = Colors.green;
        } else if (status == 'REJECTED') {
          statusColor = Colors.red;
        }

        return Card(
          margin: const EdgeInsets.all(12),
          child: ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Employee: $employeeName'),
                Text('Team: $teamName'),
                Text('Leave Type: $leaveType'),
                Row(
                  children: [
                    Text('Status: '),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (status == 'REJECTED' && leave['rejectionRemarks'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Rejection Reason: ${leave['rejectionRemarks']}',
                      style: TextStyle(color: Colors.red.shade700),
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

  Future<void> _fetchLeaveHistory() async {
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

      // 获取已处理的假期申请（已批准或已拒绝）
      final processedLeaves = await _adminLeaveService.fetchProcessedLeavesForTeams(teams);

      // 过滤掉不在团队中的假期
      final filteredLeaves = processedLeaves
          .where((leave) => teamIds.contains(leave['teamId']))
          .toList();

      setState(() {
        _historyLeaves = filteredLeaves;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // No TabBar, just show the pending approvals content directly
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
        ? Center(child: Text('Error:\n$_errorMessage'))
        : Column(
            children: [
              // Header section
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
            ],
          );
  }
}

class LeaveDetailsPage extends StatefulWidget {
  final Map<String, dynamic> leave;
  final Future<String> Function(String) getEmployeeName;
  final Future<String> Function(String) getTeamName;
  final Future<void> Function(String status)? onStatusUpdate;

  const LeaveDetailsPage({
    Key? key,
    required this.leave,
    required this.getEmployeeName,
    required this.getTeamName,
    this.onStatusUpdate,
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
      if (ts == null) return 'N/A';
      if (ts is String && ts.isEmpty) return 'N/A';
      if (ts is String) return ts;
      if (ts is DateTime) return ts.toString().split(' ')[0];
      if (ts is Timestamp) return ts.toDate().toString().split(' ')[0];
      return ts.toString();
    }

    // Parse number of days
    int numberOfDays = 1;
    if (leave['numberOfDays'] != null) {
      numberOfDays = int.tryParse(leave['numberOfDays'].toString()) ?? 1;
    }

    // Calculate leave end date
    String leaveEndDate = 'N/A';
    DateTime? endDate;
    if (leave['endDateTime'] != null) {
      if (leave['endDateTime'] is Timestamp) {
        endDate = (leave['endDateTime'] as Timestamp).toDate();
      } else if (leave['endDateTime'] is DateTime) {
        endDate = leave['endDateTime'];
      } else {
        endDate = DateTime.tryParse(leave['endDateTime'].toString());
      }

      if (endDate != null) {
        if (numberOfDays > 1) {
          endDate = endDate.add(Duration(days: numberOfDays - 1));
        }
        // For single day leave, just use the end date as is
        leaveEndDate = formatDate(endDate);
      }
    }

    // Calculate start date
    String leaveStartDate = 'N/A';
    if (leave['startDate'] != null) {
      leaveStartDate = formatDate(leave['startDate']);
    }

    // Key modification: For single-day leaves, always use end date as start date
    if (numberOfDays == 1 && leaveEndDate != 'N/A') {
      leaveStartDate = leaveEndDate;
    }

    return {
      'employeeName': employeeName,
      'teamName': teamName,
      'appliedAt': formatDate(leave['appliedAt']),
      'startDate': leaveStartDate,
      'endDate': leaveEndDate,
      'reason': leave['reason'] ?? '',
      'rejectionRemarks': leave['rejectionRemarks'] ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Details'),
        // Don't include tab bar here
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load leave details: ${snapshot.error}'),
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
                if (widget.leave['status'] == 'rejected' && widget.leave['rejectionRemarks'] != null && widget.leave['rejectionRemarks'].toString().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rejection Remarks',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          widget.leave['rejectionRemarks'] ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
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
                // Display rejection reason (if exists and status is rejected)
                if (widget.leave['status'] == 'rejected' && 
                    widget.leave['rejectionRemarks'] != null && 
                    widget.leave['rejectionRemarks'].toString().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rejection Reason',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          widget.leave['rejectionRemarks'] ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                // Display action buttons only if onStatusUpdate is provided and leave is pending
                if (widget.onStatusUpdate != null && 
                    (widget.leave['status'] == null || widget.leave['status'] == 'pending' || widget.leave['status'].toString().toLowerCase() == 'pending'))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => widget.onStatusUpdate?.call('approved'),
                        child: const Text('Approve'),
                      ),
                      ElevatedButton(
                        onPressed: () => widget.onStatusUpdate?.call('rejected'),
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