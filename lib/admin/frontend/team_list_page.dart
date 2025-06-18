import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/team_model.dart';
import '../services/team_service.dart';
import 'create_team_page.dart';

class TeamListPage extends StatefulWidget {
  @override
  _TeamListPageState createState() => _TeamListPageState();
}

class _TeamListPageState extends State<TeamListPage> {
  List<TeamModel> _teams = [];
  Map<String, Map<String, String>> _userDetailsMap = {};
  bool _isLoading = true;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
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
    } catch (e) {
      print("🔥 Error fetching teams or users: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading teams')),
      );
    }
  }

  void _deleteTeam(String teamId) async {
    await TeamService().deleteTeam(teamId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Team deleted")),
    );
    _fetchTeams();
  }

  String formatTime(DateTime? time) {
    if (time == null) return "N/A";
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  String userNameRole(String? uid, {String? creatorId}) {
    if (uid == null || !_userDetailsMap.containsKey(uid)) return "Unknown";
    final data = _userDetailsMap[uid]!;
    final nameRole = "${data['name']} (${data['role']})";
    return creatorId == uid ? "$nameRole 👑 (Creator)" : nameRole;
  }

  void _viewTeam(TeamModel team) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${team.teamName} (${team.teamType})"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("🧑‍💼 Managers:"),
              if (team.teamType == "Production Team") ...[
                _managerRow("Project Manager", team.projectManagerId, team.adminId),
                _managerRow("Assistant Project Manager", team.assistantProjectManagerId, team.adminId),
                _managerRow("Project Lead", team.projectLeadId, team.adminId),
              ] else if (team.teamType == "General Team") ...[
                _managerRow("General Project Manager", team.generalProjectManagerId, team.adminId),
              ],
              _managerRow("Assistant Manager HR", team.assistantManagerHRId, team.adminId),
              _managerRow("Manager HR", team.managerHRId, team.adminId),
              SizedBox(height: 12),
              Text("👥 Members (${team.members.length}):"),
              ...team.members.map((m) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text("• ${userNameRole(m)}"),
                  )),
              SizedBox(height: 12),
              Text("🕒 Shift Timing:"),
              Text("• Session 1 Login: ${formatTime(team.session1Login)}"),
              Text("• Session 1 Logout: ${formatTime(team.session1Logout)}"),
              Text("• Session 2 Login: ${formatTime(team.session2Login)}"),
              Text("• Session 2 Logout: ${formatTime(team.session2Logout)}"),
              SizedBox(height: 8),
              Text("⏱ Grace Time: ${team.graceTimeInMinutes > 0 ? '${team.graceTimeInMinutes} mins' : 'Not Set'}"),
              Text("📅 No LOP Days: ${team.noLOPDays > 0 ? team.noLOPDays : 'Not Set'}"),
              Text("🚨 Emergency Leaves: ${team.emergencyLeaves > 0 ? team.emergencyLeaves : 'Not Set'}"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _managerRow(String roleTitle, String? uid, String creatorId) {
    if (uid == null) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Text("• $roleTitle: ${userNameRole(uid, creatorId: creatorId)}"),
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
      appBar: AppBar(
        title: Text('Your Teams'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Create New Team',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateTeamPage()),
              );
              _fetchTeams();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? Center(child: Text("No teams created yet."))
              : ListView.builder(
                  itemCount: _teams.length,
                  itemBuilder: (_, index) {
                    final team = _teams[index];
                    return Card(
                      color: Colors.indigo.shade50,
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      elevation: 3,
                      child: ListTile(
                        title: Text(team.teamName),
                        subtitle: Text("Type: ${team.teamType} | Members: ${team.members.length}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.visibility),
                              tooltip: 'View Details',
                              onPressed: () => _viewTeam(team),
                            ),
                            if (_isTeamOwner(team)) ...[
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Edit Team',
                                onPressed: () => _editTeam(team),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete Team',
                                onPressed: () => _deleteTeam(team.teamId),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
