import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_leave_service.dart';

class LeaveApprovalsPage extends StatefulWidget {
  const LeaveApprovalsPage({super.key});

  @override
  State<LeaveApprovalsPage> createState() => _LeaveApprovalsPageState();
}

class _LeaveApprovalsPageState extends State<LeaveApprovalsPage>
    with TickerProviderStateMixin {
  final AdminLeaveService _adminLeaveService = AdminLeaveService();
  List<Map<String, dynamic>> _pendingLeaves = [];
  bool _loading = true;
  String? _errorMessage;
  
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchPendingLeaves();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
      
      final filteredLeaves = leaves
          .where((leave) => teamIds.contains(leave['teamId']))
          .toList();
      
      setState(() {
        _pendingLeaves = filteredLeaves;
        _loading = false;
      });
      
      // Start animations when data is loaded
      _fadeController.forward();
      _slideController.forward();
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

      _fetchPendingLeaves();
    } catch (e) {
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

  void _showPendingLeaveDetailsPage(Map<String, dynamic> leave) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LeaveDetailsPage(
          leave: leave,
          getEmployeeName: _getEmployeeName,
          getTeamName: _getTeamName,
          onStatusUpdate: (status) async {
            await _updateLeaveStatus(leave, status);
            Navigator.of(context).pop();
            _fetchPendingLeaves();
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
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
      final adminDoc = await FirebaseFirestore.instance
          .collection('employeeInfo')
          .doc(user.uid)
          .get();

      final adminName = adminDoc.exists ? (adminDoc.data()?['name'] as String? ?? '') : '';
      final adminRole = adminDoc.exists ? (adminDoc.data()?['role'] as String? ?? '') : '';

      String? startDate;
      String? endDate;

      String formatDate(dynamic ts) {
        if (ts == null) return 'N/A';
        if (ts is String && ts.isEmpty) return 'N/A';
        if (ts is String) return ts;
        if (ts is DateTime) return ts.toString().split(' ')[0];
        if (ts is Timestamp) return ts.toDate().toString().split(' ')[0];
        return ts.toString();
      }

      DateTime? dateTime;
      int numberOfDays = int.tryParse(leave['numberOfDays']?.toString() ?? '1') ?? 1;

      if (leave['endDateTime'] != null) {
        if (leave['endDateTime'] is Timestamp) {
          dateTime = (leave['endDateTime'] as Timestamp).toDate();
        } else if (leave['endDateTime'] is DateTime) {
          dateTime = leave['endDateTime'];
        } else {
          dateTime = DateTime.tryParse(leave['endDateTime'].toString());
        }

        if (dateTime != null) {
          DateTime originalDateTime = dateTime;

          if (numberOfDays > 1) {
            dateTime = dateTime.add(Duration(days: numberOfDays - 1));
          }
          endDate = formatDate(dateTime);

          if (numberOfDays == 1) {
            startDate = endDate;
          } else if (leave['startDate'] != null) {
            startDate = formatDate(leave['startDate']);
          } else {
            startDate = formatDate(originalDateTime);
          }
        }
      }

      final Map<String, dynamic> updateData = {
        'status': status,
        'startDate': startDate,
        'endDate': endDate,
      };

      if (status == 'approved') {
        updateData.addAll({
          'approvedBy': user.uid,
          'approvedByName': adminName,
          'approvedByRole': adminRole,
          'approvedAt': FieldValue.serverTimestamp(),
        });
      } else if (status == 'rejected') {
        String? rejectionRemarks = await _getRejectionRemarks();
        if (rejectionRemarks == null) {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Rejection Reason',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                hintText: 'Please enter the reason for rejecting this leave request',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
              ),
              maxLines: 3,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.redAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () {
                  result = remarksController.text;
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );

    return result;
  }

  Widget _leaveTile(Map<String, dynamic> leave, int index) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
                top: index == 0 ? 16 : 0,
              ),
              child: TweenAnimationBuilder(
                duration: Duration(milliseconds: 300 + (index * 100)),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF20D4A7).withOpacity(0.1),
                            Colors.white,
                            const Color(0xFF20D4A7).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF20D4A7).withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 10,
                            offset: const Offset(-5, -5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showPendingLeaveDetailsPage(leave),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            child: FutureBuilder<List<dynamic>>(
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

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF20D4A7), Color(0xFF1AB394)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF20D4A7).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                employeeName,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                teamName,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.orange.withOpacity(0.3),
                                            ),
                                          ),
                                          child: const Text(
                                            'PENDING',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.event_note,
                                          color: Colors.grey[600],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Leave Type: $leaveType',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF20D4A7), Color(0xFF1AB394)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF20D4A7).withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton.icon(
                                            onPressed: () => _showPendingLeaveDetailsPage(leave),
                                            icon: const Icon(
                                              Icons.visibility,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'View Details',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(25),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF20D4A7), Color(0xFF1AB394)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF20D4A7), Color(0xFF1AB394)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF20D4A7), Color(0xFF1AB394)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: _pendingLeaves.isEmpty
                  ? FadeTransition(
                      opacity: _fadeAnimation,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF20D4A7).withOpacity(0.1),
                                    Colors.white,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Color(0xFF20D4A7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No Pending Leave Approvals',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All caught up! No leave requests need your attention.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _pendingLeaves.length,
                      itemBuilder: (context, index) {
                        final leave = _pendingLeaves[index];
                        return _leaveTile(leave, index);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced LeaveDetailsPage with animations and gradients
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

class _LeaveDetailsPageState extends State<LeaveDetailsPage>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _detailsFuture;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _getLeaveDetails(widget.leave);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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

    int numberOfDays = 1;
    if (leave['numberOfDays'] != null) {
      numberOfDays = int.tryParse(leave['numberOfDays'].toString()) ?? 1;
    }

    String leaveEndDate = 'N/A';
    DateTime? endDate;

    if (leave['endDate'] != null) {
      leaveEndDate = formatDate(leave['endDate']);
    } else if (leave['endDateTime'] != null) {
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
        leaveEndDate = formatDate(endDate);
      }
    }

    String leaveStartDate = 'N/A';
    if (leave['startDate'] != null) {
      leaveStartDate = formatDate(leave['startDate']);
    } else if (numberOfDays == 1 && leaveEndDate != 'N/A') {
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF20D4A7), Color(0xFF1AB394)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Leave Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _detailsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF20D4A7)),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load leave details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No leave details found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final details = snapshot.data!;
                      final leaveType = details['reason'] ?? 'N/A';
                      final status = widget.leave['status']?.toString().toUpperCase() ?? 'PENDING';
                      final startDate = details['startDate'] ?? 'N/A';
                      final endDate = details['endDate'] ?? 'N/A';
                      final numDays = widget.leave['numberOfDays']?.toString() ?? 'N/A';
                      final leaveDuration = widget.leave['leaveDuration']?.toString() ?? 'N/A';
                      final appliedAt = details['appliedAt'] ?? 'N/A';
                      final explanation = widget.leave['explanation'] ?? 'N/A';

                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Section
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF20D4A7).withOpacity(0.1),
                                      Colors.white,
                                      const Color(0xFF20D4A7).withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF20D4A7).withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF20D4A7), Color(0xFF1AB394)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF20D4A7).withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.event_note,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                leaveType,
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 6,
                                                  horizontal: 16,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: status == 'PENDING'
                                                      ? Colors.orange.withOpacity(0.1)
                                                      : status == 'APPROVED'
                                                          ? Colors.green.withOpacity(0.1)
                                                          : Colors.red.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: status == 'PENDING'
                                                        ? Colors.orange
                                                        : status == 'APPROVED'
                                                            ? Colors.green
                                                            : Colors.red,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Text(
                                                  status,
                                                  style: TextStyle(
                                                    color: status == 'PENDING'
                                                        ? Colors.orange
                                                        : status == 'APPROVED'
                                                            ? Colors.green
                                                            : Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Leave Duration Section
                              _buildSection(
                                'Leave Duration',
                                Icons.calendar_today,
                                [
                                  _buildDetailRow('Start Date', startDate),
                                  _buildDetailRow('End Date', endDate),
                                  _buildDetailRow('Number of Days', '$numDays day(s)'),
                                  _buildDetailRow('Leave Duration', '$leaveDuration day(s)'),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Rejection Remarks Section (if rejected)
                              if (widget.leave['status'] == 'rejected' && 
                                  widget.leave['rejectionRemarks'] != null && 
                                  widget.leave['rejectionRemarks'].toString().isNotEmpty)
                                Column(
                                  children: [
                                    _buildRejectionSection(widget.leave['rejectionRemarks']),
                                    const SizedBox(height: 24),
                                  ],
                                ),

                              // Application Details Section
                              _buildSection(
                                'Application Details',
                                Icons.info_outline,
                                [
                                  _buildDetailRow('Applied At', appliedAt),
                                  _buildDetailRow('Employee', details['employeeName'] ?? 'N/A'),
                                  _buildDetailRow('Team', details['teamName'] ?? 'N/A'),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Explanation Section
                              _buildExplanationSection(explanation),
                              const SizedBox(height: 32),

                              // Action Buttons
                              if (widget.onStatusUpdate != null && 
                                  (widget.leave['status'] == null || 
                                   widget.leave['status'] == 'pending' || 
                                   widget.leave['status'].toString().toLowerCase() == 'pending'))
                                _buildActionButtons(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFF20D4A7).withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF20D4A7).withOpacity(0.1),
                      const Color(0xFF20D4A7).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF20D4A7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRejectionSection(String rejectionRemarks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade50,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.cancel_outlined,
                  color: Colors.red.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Rejection Remarks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            rejectionRemarks,
            style: TextStyle(
              fontSize: 16,
              color: Colors.red.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationSection(String explanation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFF20D4A7).withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF20D4A7).withOpacity(0.1),
                      const Color(0xFF20D4A7).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF20D4A7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Explanation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            explanation,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF20D4A7), Color(0xFF1AB394)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF20D4A7).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => widget.onStatusUpdate?.call('approved'),
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text(
                'Approve',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.redAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => widget.onStatusUpdate?.call('rejected'),
              icon: const Icon(Icons.cancel_outlined, color: Colors.white),
              label: const Text(
                'Reject',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$title:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}