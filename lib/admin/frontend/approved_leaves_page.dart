import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/admin_leave_service.dart';

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

  Future<void> _fetchApprovedLeaves() async {
    print('DEBUG: _fetchApprovedLeaves called');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('DEBUG: User is null');
      return;
    }
    
    try {
      print('DEBUG: Fetching teams for admin: ${user.uid}');
      final teams = await _adminLeaveService.fetchTeamsForAdmin(user.uid);
      print('DEBUG: Teams fetched: ${teams.length}');
      
      final leaves = await _adminLeaveService.fetchApprovedLeavesForTeams(teams);
      print('DEBUG: Approved leaves fetched: ${leaves.length}');
      
      setState(() {
        _approvedLeaves = leaves;
        _loading = false;
      });
    } catch (e) {
      print('DEBUG: Error fetching leaves: $e');
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching leaves: $e')),
        );
      }
    }
  }

  void _showRejectDialog(Map<String, dynamic> leave) {
    final TextEditingController remarksController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Leave'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please provide remarks for rejecting this leave:'),
              const SizedBox(height: 16),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  hintText: 'Enter reason for rejection...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (remarksController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide remarks')),
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                await _rejectLeave(leave, remarksController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rejectLeave(Map<String, dynamic> leave, String remarks) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _adminLeaveService.rejectLeave(
        memberId: leave['employeeId'],
        leaveId: leave['leaveId'],
        adminId: user.uid,
        adminName: user.displayName ?? 'Admin',
        adminRole: 'Admin',
        remarks: remarks,
      );

      // Remove from local list and update UI
      setState(() {
        _approvedLeaves.removeWhere((item) => 
          item['leaveId'] == leave['leaveId'] && 
          item['employeeId'] == leave['employeeId']
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave rejected successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting leave: $e')),
        );
      }
    }
  }

  void _showLeaveDetails(Map<String, dynamic> leave) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LeaveDetailsPage(
          leave: leave,
          onReject: () => _showRejectDialog(leave),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    
    DateTime dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      dateTime = DateTime.tryParse(date) ?? DateTime.now();
    } else {
      return 'N/A';
    }
    
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  Widget _leaveTile(Map<String, dynamic> leave) {
    return FutureBuilder<String>(
      future: _adminLeaveService.getEmployeeName(leave['employeeId'] ?? ''),
      builder: (context, empSnapshot) {
        final employeeName = empSnapshot.data ?? leave['employeeId'];
        
        return Card(
          margin: const EdgeInsets.all(8),
          elevation: 2,
          child: ListTile(
            title: Text(
              'Employee: $employeeName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Team: ${leave['teamName'] ?? 'Unknown Team'}'),
                Text('Leave Type: ${leave['leaveType'] ?? 'N/A'}'),
                Text('Duration: ${_formatDate(leave['startDate'])} - ${_formatDate(leave['endDate'])}'),
                Text('Reason: ${leave['reason'] ?? 'N/A'}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: () => _showLeaveDetails(leave),
                  tooltip: 'View Details',
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _showRejectDialog(leave),
                  tooltip: 'Reject Leave',
                ),
              ],
            ),
            leading: const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approved Leaves'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _approvedLeaves.isEmpty
              ? const Center(
                  child: Text(
                    'No approved leaves found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchApprovedLeaves,
                  child: ListView.builder(
                    itemCount: _approvedLeaves.length,
                    itemBuilder: (context, index) {
                      final leave = _approvedLeaves[index];
                      return _leaveTile(leave);
                    },
                  ),
                ),
    );
  }
}

// Full page view for leave details
class LeaveDetailsPage extends StatelessWidget {
  final Map<String, dynamic> leave;
  final VoidCallback onReject;

  const LeaveDetailsPage({
    super.key,
    required this.leave,
    required this.onReject,
  });

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    
    DateTime dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      dateTime = DateTime.tryParse(date) ?? DateTime.now();
    } else {
      return 'N/A';
    }
    
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  String _formatDateTime(dynamic date) {
    if (date == null) return 'N/A';
    
    DateTime dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      dateTime = DateTime.tryParse(date) ?? DateTime.now();
    } else {
      return 'N/A';
    }
    
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () {
              Navigator.pop(context);
              onReject();
            },
            tooltip: 'Reject Leave',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'APPROVED',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Employee Information
            _buildInfoCard(
              'Employee Information',
              [
                _buildInfoRow('Employee ID', leave['employeeId'] ?? 'N/A'),
                FutureBuilder<String>(
                  future: AdminLeaveService().getEmployeeName(leave['employeeId'] ?? ''),
                  builder: (context, snapshot) {
                    return _buildInfoRow('Employee Name', snapshot.data ?? 'Loading...');
                  },
                ),
                _buildInfoRow('Team', leave['teamName'] ?? 'Unknown Team'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Leave Information
            _buildInfoCard(
              'Leave Information',
              [
                _buildInfoRow('Leave Type', leave['leaveType'] ?? 'N/A'),
                _buildInfoRow('Start Date', _formatDate(leave['startDate'])),
                _buildInfoRow('End Date', _formatDate(leave['endDate'])),
                _buildInfoRow('Number of Days', leave['numberOfDays']?.toString() ?? 'N/A'),
                _buildInfoRow('Applied On', _formatDateTime(leave['appliedAt'])),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Reason
            _buildInfoCard(
              'Reason',
              [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    leave['reason'] ?? 'No reason provided',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Approval Information
            _buildInfoCard(
              'Approval Information',
              [
                _buildInfoRow('Approved By', leave['approvedByName'] ?? 'N/A'),
                _buildInfoRow('Approved By Role', leave['approvedByRole'] ?? 'N/A'),
                _buildInfoRow('Approved At', _formatDateTime(leave['approvedAt'])),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onReject();
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Reject This Leave'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}