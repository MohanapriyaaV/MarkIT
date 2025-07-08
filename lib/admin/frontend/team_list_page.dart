import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/team_model.dart';
import '../services/team_service.dart';
import 'create_team_page.dart';
final Color primaryTeal = Color(0xFF00BFA6);
final Color secondaryTeal = Color(0xFF00A693);

class TeamListPage extends StatefulWidget {
  @override
  _TeamListPageState createState() => _TeamListPageState();
}

class _TeamListPageState extends State<TeamListPage> 
    with TickerProviderStateMixin {
  List<TeamModel> _teams = [];
  Map<String, Map<String, String>> _userDetailsMap = {};
  bool _isLoading = true;
  late String _currentUserId;
  late AnimationController _animationController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fetchTeams();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeams() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      _currentUserId = currentUser.uid;
      final teams = await TeamService().getAllTeams();

      final userIds = <String>{};
      for (var team in teams) {
        userIds.addAll([
          team.projectManagerId,
          team.assistantProjectManagerId,
          team.projectLeadId,
          team.generalProjectManagerId,
          team.assistantManagerHRId,
          team.managerHRId,
          team.adminId,
          ...team.members
        ].whereType<String>());
      }

      final detailsMap = <String, Map<String, String>>{};
      final snapshots = await Future.wait(userIds.map((uid) =>
          FirebaseFirestore.instance.collection('employeeInfo').doc(uid).get()));

      for (var snap in snapshots) {
        if (snap.exists) {
          detailsMap[snap.id] = {
            'name': snap['name'] ?? 'Unknown',
            'role': snap['role'] ?? 'Unknown',
          };
        }
      }

      setState(() {
        _teams = teams;
        _userDetailsMap = detailsMap;
        _isLoading = false;
      });
      
      _animationController.forward();
      _fabController.forward();
    } catch (e) {
      print("🔥 Error fetching teams or users: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading teams'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteTeam(String teamId) async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    await TeamService().deleteTeam(teamId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text("Team deleted successfully"),
          ],
        ),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _fetchTeams();
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text("Delete Team"),
          ],
        ),
        content: Text("Are you sure you want to delete this team? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete"),
          ),
        ],
      ),
    ) ?? false;
  }

  String formatTime(DateTime? time) {
    if (time == null) return "N/A";
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  String userNameRole(String? uid, {String? creatorId}) {
    if (uid == null || !_userDetailsMap.containsKey(uid)) return "Unknown";
    final data = _userDetailsMap[uid]!;
    final nameRole = "${data['name']} (${data['role']})";
    return creatorId == uid ? "$nameRole 👑" : nameRole;
  }

  void _viewTeam(TeamModel team) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            TeamDetailFullScreen(team: team, userDetailsMap: _userDetailsMap),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  void _editTeam(TeamModel team) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateTeamPage(editTeam: team)),
    );
    _fetchTeams();
  }

  bool _isTeamOwner(TeamModel team) {
    return [
      team.adminId,
      team.projectManagerId,
      team.assistantProjectManagerId,
      team.projectLeadId,
      team.assistantManagerHRId,
      team.managerHRId,
      team.generalProjectManagerId,
    ].contains(_currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryTeal.withOpacity(0.1),
      secondaryTeal.withOpacity(0.1),
      primaryTeal.withOpacity(0.05),
    ],
  ),
),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryTeal,
      secondaryTeal,
      primaryTeal,
    ],
  ),
),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 30),
                        Icon(
                          Icons.groups,
                          size: 40,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your Teams',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? Container(
                      height: 400,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
  valueColor: AlwaysStoppedAnimation<Color>(
    primaryTeal,
  ),
),
                            SizedBox(height: 16),
                            Text(
                              "Loading teams...",
                              style: TextStyle(
                                color: primaryTeal,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _teams.isEmpty
                      ? Container(
                          height: 400,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.groups_outlined,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No teams created yet",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Tap the + button to create your first team",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: _teams.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final team = entry.value;
                                    return AnimatedContainer(
                                      duration: Duration(milliseconds: 600 + (index * 100)),
                                      curve: Curves.easeOutBack,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: Offset(0, 1),
                                          end: Offset(0, 0),
                                        ).animate(CurvedAnimation(
                                          parent: _animationController,
                                          curve: Interval(
                                            (index * 0.1).clamp(0.0, 1.0),
                                            ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                                            curve: Curves.easeOutBack,
                                          ),
                                        )),
                                        child: ScaleTransition(
                                          scale: _scaleAnimation,
                                          child: _buildTeamCard(team),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabController,
        builder: (context, child) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
            ),
            child: FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateTeamPage()),
                );
                _fetchTeams();
              },
              icon: Icon(Icons.add),
              label: Text("Create Team"),
             backgroundColor: primaryTeal,
              elevation: 8,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeamCard(TeamModel team) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        boxShadow: [
          BoxShadow(
  color: primaryTeal.withOpacity(0.2),
  blurRadius: 20,
  spreadRadius: 2,
  offset: Offset(0, 8),
),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _viewTeam(team),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: [
      primaryTeal,
      secondaryTeal,
    ],
  ),
  borderRadius: BorderRadius.circular(12),
),
                      child: Icon(
                        team.teamType == "Production Team" 
                            ? Icons.precision_manufacturing 
                            : Icons.business_center,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.teamName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: secondaryTeal,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
  color: primaryTeal.withOpacity(0.1),
  borderRadius: BorderRadius.circular(20),
),
                            child: Text(
                              team.teamType,
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryTeal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                    SizedBox(width: 8),
                    Text(
                      "${team.members.length} members",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    Spacer(),
                    if (_isTeamOwner(team))
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
  color: primaryTeal.withOpacity(0.1),
  borderRadius: BorderRadius.circular(12),
),
                        child: Text(
                          "Owner",
                          style: TextStyle(
                            color: secondaryTeal,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewTeam(team),
                        icon: Icon(Icons.visibility, size: 16),
                        label: Text("View Details"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (_isTeamOwner(team)) ...[
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _editTeam(team),
                        icon: Icon(Icons.edit),
                       color: primaryTeal,
style: IconButton.styleFrom(
  backgroundColor: primaryTeal.withOpacity(0.1),
),
                      ),
                      SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _deleteTeam(team.teamId),
                        icon: Icon(Icons.delete),
                        color: Colors.red.shade600,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TeamDetailFullScreen extends StatefulWidget {
  final TeamModel team;
  final Map<String, Map<String, String>> userDetailsMap;

  TeamDetailFullScreen({required this.team, required this.userDetailsMap});

  @override
  _TeamDetailFullScreenState createState() => _TeamDetailFullScreenState();
}

class _TeamDetailFullScreenState extends State<TeamDetailFullScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String formatTime(DateTime? time) {
    if (time == null) return "N/A";
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  String userNameRole(String? uid, {String? creatorId}) {
    if (uid == null || !widget.userDetailsMap.containsKey(uid)) return "Unknown";
    final data = widget.userDetailsMap[uid]!;
    final nameRole = "${data['name']} (${data['role']})";
    return creatorId == uid ? "$nameRole 👑" : nameRole;
  }

  Widget _managerRow(String roleTitle, String? uid, String creatorId) {
    if (uid == null) return SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
       border: Border.all(color: primaryTeal.withOpacity(0.2))
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: primaryTeal.withOpacity(0.1),
child: Icon(Icons.person, color: primaryTeal),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleTitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  userNameRole(uid, creatorId: creatorId),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: secondaryTeal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryTeal,
      secondaryTeal,
      primaryTeal,
    ],
  ),
),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.team.teamName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.team.teamType,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Content
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Managers Section
                          _buildSection(
                            title: "👨‍💼 Management Team",
                            child: Column(
                              children: [
                                if (widget.team.teamType == "Production Team") ...[
                                  _managerRow("Project Manager", widget.team.projectManagerId, widget.team.adminId),
                                  _managerRow("Assistant Project Manager", widget.team.assistantProjectManagerId, widget.team.adminId),
                                  _managerRow("Project Lead", widget.team.projectLeadId, widget.team.adminId),
                                ] else if (widget.team.teamType == "General Team") ...[
                                  _managerRow("General Project Manager", widget.team.generalProjectManagerId, widget.team.adminId),
                                ],
                                _managerRow("Assistant Manager HR", widget.team.assistantManagerHRId, widget.team.adminId),
                                _managerRow("Manager HR", widget.team.managerHRId, widget.team.adminId),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Members Section
                          _buildSection(
                            title: "👥 Team Members (${widget.team.members.length})",
                            child: widget.team.members.isEmpty
                                ? Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                                        SizedBox(height: 8),
                                        Text("No members added yet", style: TextStyle(color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 3,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: widget.team.members.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: primaryTeal.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: primaryTeal.withOpacity(0.1),
child: Icon(Icons.person, size: 16, color: primaryTeal),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                userNameRole(widget.team.members[index]),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: secondaryTeal,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Shift Timing Section
                          _buildSection(
                            title: "🕒 Shift Timing",
                            child: Column(
                              children: [
                                _buildTimingCard("Session 1", formatTime(widget.team.session1Login), formatTime(widget.team.session1Logout)),
                                SizedBox(height: 12),
                                _buildTimingCard("Session 2", formatTime(widget.team.session2Login), formatTime(widget.team.session2Logout)),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Settings Section
                          _buildSection(
                            title: "⚙️ Team Settings",
                            child: Column(
                              children: [
                                _buildSettingCard("Grace Time", "${widget.team.graceTimeInMinutes > 0 ? '${widget.team.graceTimeInMinutes} minutes' : 'Not Set'}", Icons.timer),
                                SizedBox(height: 12),
                                _buildSettingCard("No LOP Days", "${widget.team.noLOPDays > 0 ? widget.team.noLOPDays.toString() : 'Not Set'}", Icons.calendar_today),
                                SizedBox(height: 12),
                                _buildSettingCard("Emergency Leaves", "${widget.team.emergencyLeaves > 0 ? widget.team.emergencyLeaves.toString() : 'Not Set'}", Icons.emergency),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: secondaryTeal,
          ),
        ),
        SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildTimingCard(String session, String login, String logout) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
       gradient: LinearGradient(
  colors: [primaryTeal.withOpacity(0.1), secondaryTeal.withOpacity(0.1)],
),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
         Icon(Icons.schedule, color: primaryTeal),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: secondaryTeal,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Login: $login • Logout: $logout",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryTeal.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
  color: primaryTeal.withOpacity(0.1),
  borderRadius: BorderRadius.circular(8),
),
            child: Icon(icon, color: primaryTeal, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: secondaryTeal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}  