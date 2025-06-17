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
      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    } catch (e, stacktrace) {
      print("🔥 Error fetching teams: $e");
      print("📌 Stacktrace: $stacktrace");
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

  void _viewTeam(TeamModel team) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(team.teamName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Team ID: ${team.teamId}"),
              Text("Project Manager: ${team.projectManagerId}"),
              Text("Assistant Project Manager: ${team.assistantProjectManagerId}"),
              Text("Project Lead: ${team.projectLeadId}"),
              SizedBox(height: 8),
              Text("Members (${team.members.length}):"),
              ...team.members.map((m) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text("• $m"),
                  )),
              SizedBox(height: 12),
              Text("Shift Timing:"),
              Text("Session 1 Login: ${formatTime(team.session1Login)}"),
              Text("Session 1 Logout: ${formatTime(team.session1Logout)}"),
              Text("Session 2 Login: ${formatTime(team.session2Login)}"),
              Text("Session 2 Logout: ${formatTime(team.session2Logout)}"),
              SizedBox(height: 8),
              Text("Grace Time: ${team.graceTimeInMinutes} minutes"),
SizedBox(height: 12),
Text("No LOP Days: ${team.noLOPDays}"),
Text("Emergency Leaves: ${team.emergencyLeaves}"),

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

  void _editTeam(TeamModel team) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateTeamPage(editTeam: team)),
    );
    _fetchTeams();
  }

  /// ✅ Updated with adminId check
  bool _isTeamOwner(TeamModel team) {
    return team.adminId == _currentUserId ||
        team.projectManagerId == _currentUserId ||
        team.assistantProjectManagerId == _currentUserId ||
        team.projectLeadId == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Teams'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
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
                      color: Colors.deepPurple.shade50,
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      elevation: 3,
                      child: ListTile(
                        title: Text(team.teamName),
                        subtitle: Text("Members: ${team.members.length}"),
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
