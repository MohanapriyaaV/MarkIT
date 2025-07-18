import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApprovedRejectedLeavesPage extends StatefulWidget {
  const ApprovedRejectedLeavesPage({super.key});

  @override
  State<ApprovedRejectedLeavesPage> createState() => _ApprovedRejectedLeavesPageState();
}

class _ApprovedRejectedLeavesPageState extends State<ApprovedRejectedLeavesPage> 
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _historyLeaves = [];
  bool _loading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late AnimationController _refreshController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _fetchHistoryLeaves();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshController.dispose();
    super.dispose();
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
        _animationController.forward();
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

      _animationController.forward();
      print('DEBUG: History leaves fetch complete - found ${allProcessedLeaves.length} leaves');

    } catch (e) {
      print('ERROR: Failed to fetch history leaves: $e');
      setState(() {
        _historyLeaves = [];
        _loading = false;
        _errorMessage = e.toString();
      });
      _animationController.forward();
    }
  }

  Future<void> _refreshData() async {
    _refreshController.forward().then((_) {
      _refreshController.reset();
    });
    await _fetchHistoryLeaves();
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

  Widget _historyTile(Map<String, dynamic> leave, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * (index + 1) * 0.1),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.only(
                left: 16,
                right: 16,
                top: index == 0 ? 16 : 8,
                bottom: 8,
              ),
              child: TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 50)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
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
                    final status = leave['status']?.toString().toUpperCase() ?? 'N/A';
                    
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.grey.shade50,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showHistoryLeaveDetailsPage(leave),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
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
                                            const Color(0xFF1DD1A1),
                                            const Color(0xFF00D2D3),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            employeeName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            teamName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: status == 'APPROVED' 
                                              ? [Colors.green.shade400, Colors.green.shade600]
                                              : [Colors.red.shade400, Colors.red.shade600],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (status == 'APPROVED' 
                                                ? Colors.green 
                                                : Colors.red).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
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
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1DD1A1).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF1DD1A1).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.event_note,
                                        color: const Color(0xFF1DD1A1),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Leave Type: $leaveType',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF1DD1A1),
                                            const Color(0xFF00D2D3),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF1DD1A1).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'View Details',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showHistoryLeaveDetailsPage(Map<String, dynamic> leave) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            HistoryLeaveDetailsPage(leave: leave),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1DD1A1),
              const Color(0xFF00D2D3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      
                    ),
                    
                  ],
                ),
              ),
              
              // Content Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
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
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 1000),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Transform.rotate(
                                        angle: value * 2 * 3.14159,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF1DD1A1),
                                                const Color(0xFF00D2D3),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Icon(
                                            Icons.sync,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Loading leave history...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : _errorMessage != null
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade600,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading data',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : _historyLeaves.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 1000),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: 0.8 + (0.2 * value),
                                    child: Opacity(
                                      opacity: value,
                                      child: Container(
                                        padding: const EdgeInsets.all(30),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
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
                                            Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    const Color(0xFF1DD1A1).withOpacity(0.2),
                                                    const Color(0xFF00D2D3).withOpacity(0.2),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(50),
                                              ),
                                              child: Icon(
                                                Icons.history,
                                                size: 60,
                                                color: const Color(0xFF1DD1A1),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            const Text(
                                              'No Leave History',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'No approved or rejected leaves found',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _historyLeaves.length,
                          itemBuilder: (context, index) {
                            final leave = _historyLeaves[index];
                            return _historyTile(leave, index);
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
}

class HistoryLeaveDetailsPage extends StatefulWidget {
  final Map<String, dynamic> leave;
  const HistoryLeaveDetailsPage({Key? key, required this.leave})
      : super(key: key);

  @override
  State<HistoryLeaveDetailsPage> createState() => _HistoryLeaveDetailsPageState();
}

class _HistoryLeaveDetailsPageState extends State<HistoryLeaveDetailsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getAdminInfo(String? adminUid) async {
    if (adminUid == null) return {'name': 'N/A', 'role': 'N/A'};
    final doc = await FirebaseFirestore.instance
        .collection('employeeInfo')
        .doc(adminUid)
        .get();
    if (!doc.exists) return {'name': 'N/A', 'role': 'N/A'};
    return {'name': doc['name'] ?? 'N/A', 'role': doc['role'] ?? 'N/A'};
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

  Widget _buildAnimatedSection({
    required String title,
    required Widget content,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * (index + 1) * 0.3),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                              const Color(0xFF1DD1A1),
                              const Color(0xFF00D2D3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getIconForSection(title),
                          color: Colors.white,
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
                  content,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForSection(String title) {
    switch (title) {
      case 'Status Information':
        return Icons.info_outline;
      case 'Employee Information':
        return Icons.person_outline;
      case 'Leave Details':
        return Icons.event_note;
      case 'Explanation':
        return Icons.description;
      default:
        return Icons.info_outline;
    }
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.leave['status']?.toString().toUpperCase() ?? 'N/A';
    final adminUid = status == 'APPROVED' ? widget.leave['approvedBy'] : widget.leave['rejectedBy'];
    final isApproved = status == 'APPROVED';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isApproved
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.red.shade400, Colors.red.shade600],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${isApproved ? 'Approved' : 'Rejected'} Leave',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Leave Details',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isApproved ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: FutureBuilder<Map<String, String>>(
                    future: _getAdminInfo(adminUid),
                    builder: (context, snapshot) {
                      final adminName = snapshot.data?['name'] ?? 'N/A';
                      final adminRole = snapshot.data?['role'] ?? 'N/A';

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            
                            // Status Section
                            _buildAnimatedSection(
                              title: 'Status Information',
                              index: 0,
                              content: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isApproved
                                        ? [Colors.green.shade50, Colors.green.shade100]
                                        : [Colors.red.shade50, Colors.red.shade100],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isApproved 
                                        ? Colors.green.shade300 
                                        : Colors.red.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isApproved ? Colors.green : Colors.red,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Icon(
                                            isApproved ? Icons.check : Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Status: $status',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: isApproved 
                                                ? Colors.green.shade800 
                                                : Colors.red.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildDetailRow(
                                      '${isApproved ? 'Approved' : 'Rejected'} By:',
                                      adminName,
                                    ),
                                    _buildDetailRow(
                                      '${isApproved ? 'Approved' : 'Rejected'} By Role:',
                                      adminRole,
                                    ),
                                    if (widget.leave['rejectionRemarks'] != null && !isApproved)
                                      _buildDetailRow(
                                        'Rejection Reason:',
                                        widget.leave['rejectionRemarks'],
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // Employee Information
                            _buildAnimatedSection(
                              title: 'Employee Information',
                              index: 1,
                              content: Column(
                                children: [
                                  FutureBuilder<String>(
                                    future: _getEmployeeName(widget.leave['employeeId'] ?? ''),
                                    builder: (context, snapshot) {
                                      final empName = snapshot.data ?? widget.leave['employeeId'] ?? 'N/A';
                                      return _buildDetailRow('Employee Name:', empName);
                                    },
                                  ),
                                  FutureBuilder<String>(
                                    future: _getTeamName(widget.leave['teamId'] ?? ''),
                                    builder: (context, snapshot) {
                                      final teamName = snapshot.data ?? widget.leave['teamId'] ?? 'N/A';
                                      return _buildDetailRow('Team Name:', teamName);
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Leave Details
                            _buildAnimatedSection(
                              title: 'Leave Details',
                              index: 2,
                              content: Column(
                                children: [
                                  _buildDetailRow('Leave Type:', widget.leave['reason'] ?? 'N/A'),
                                  _buildDetailRow('Start Date:', _formatDate(widget.leave['startDate'])),
                                  _buildDetailRow('End Date:', _formatDate(widget.leave['endDate'])),
                                  _buildDetailRow('Number of Days:', '${widget.leave['numberOfDays'] ?? 'N/A'}'),
                                  _buildDetailRow('Applied At:', _formatDate(widget.leave['appliedAt'])),
                                ],
                              ),
                            ),

                            // Explanation
                            _buildAnimatedSection(
                              title: 'Explanation',
                              index: 3,
                              content: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF1DD1A1).withOpacity(0.05),
                                      const Color(0xFF00D2D3).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF1DD1A1).withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  widget.leave['explanation'] ?? 'No explanation provided',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
}