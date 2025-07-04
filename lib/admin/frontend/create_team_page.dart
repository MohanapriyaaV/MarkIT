import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'select_members_page.dart';
import '../models/team_model.dart';
import '../services/team_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateTeamPage extends StatefulWidget {
  final TeamModel? editTeam;

  CreateTeamPage({this.editTeam});

  @override
  _CreateTeamPageState createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<CreateTeamPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _noLOPController = TextEditingController();
  final TextEditingController _emergencyLeaveController =
      TextEditingController();
  final TextEditingController _graceTimeController = TextEditingController();

  TimeOfDay? _session1Login;
  TimeOfDay? _session1Logout;
  TimeOfDay? _session2Login;
  TimeOfDay? _session2Logout;

  List<String> _selectedMembers = [];
  String? _projectManagerId;
  String? _assistantProjectManagerId;
  String? _projectLeadId;
  String? _assistantManagerHRId;
  String? _managerHRId;
  String? _generalProjectManagerId;

  String? _currentUserRole;
  String _teamType = 'Production Team';

  bool get isEditMode => widget.editTeam != null;

  bool get isSuperAdmin =>
      _currentUserRole == 'Director' || _currentUserRole == 'CEO';

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    if (isEditMode) {
      final team = widget.editTeam!;
      _teamNameController.text = team.teamName;
      _noLOPController.text = team.noLOPDays.toString();
      _emergencyLeaveController.text = team.emergencyLeaves.toString();
      _graceTimeController.text = team.graceTimeInMinutes.toString();
      _selectedMembers = List.from(team.members);
      _session1Login = TimeOfDay.fromDateTime(team.session1Login);
      _session1Logout = TimeOfDay.fromDateTime(team.session1Logout);
      _session2Login = TimeOfDay.fromDateTime(team.session2Login);
      _session2Logout = TimeOfDay.fromDateTime(team.session2Logout);
      _projectManagerId = team.projectManagerId;
      _assistantProjectManagerId = team.assistantProjectManagerId;
      _projectLeadId = team.projectLeadId;
      _assistantManagerHRId = team.assistantManagerHRId;
      _managerHRId = team.managerHRId;
      _generalProjectManagerId = team.generalProjectManagerId;
    }
  }

  Future<void> _fetchUserRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('employeeInfo')
          .doc(currentUser.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _currentUserRole = doc['role'];
        });
      }
    }
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay? initialTime) {
    return showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
  }

  void _selectMembers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _currentUserRole == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectMembersPage(
          selectedMembers: _selectedMembers,
          currentUserId: currentUser.uid,
          role: _currentUserRole!,
          isGeneralTeam: _teamType == 'General Team',
          isSuperAdmin: isSuperAdmin,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedMembers = List<String>.from(result['members']);
        if (!isSuperAdmin) {
          _projectManagerId = result['projectManagerId'];
          _assistantProjectManagerId = result['assistantProjectManagerId'];
          _projectLeadId = result['projectLeadId'];
          _generalProjectManagerId = result['generalProjectManagerId'];
          _assistantManagerHRId = result['assistantManagerHRId'];
          _managerHRId = result['managerHRId'];
        }
      });
    }
  }

  Future<void> _submit() async {
    bool hasRequiredOwners = true;

    if (!isSuperAdmin) {
      hasRequiredOwners = _teamType == 'General Team'
          ? (_generalProjectManagerId != null &&
                _assistantManagerHRId != null &&
                _managerHRId != null)
          : (_projectManagerId != null &&
                _assistantProjectManagerId != null &&
                _projectLeadId != null);
    }

    if (_formKey.currentState!.validate() &&
        _session1Login != null &&
        _session1Logout != null &&
        _session2Login != null &&
        _session2Logout != null &&
        _selectedMembers.isNotEmpty &&
        hasRequiredOwners) {
      try {
        final now = DateTime.now();
        final session1Login = DateTime(
          now.year,
          now.month,
          now.day,
          _session1Login!.hour,
          _session1Login!.minute,
        );
        final session1Logout = DateTime(
          now.year,
          now.month,
          now.day,
          _session1Logout!.hour,
          _session1Logout!.minute,
        );
        final session2Login = DateTime(
          now.year,
          now.month,
          now.day,
          _session2Login!.hour,
          _session2Login!.minute,
        );
        final session2Logout = DateTime(
          now.year,
          now.month,
          now.day,
          _session2Logout!.hour,
          _session2Logout!.minute,
        );

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('User not logged in')));
          return;
        }

        // Separate admins and members
        final adminIds = <String?>[
          _projectManagerId,
          _assistantProjectManagerId, // <-- include Assistant Project Manager
          _projectLeadId,
          _assistantManagerHRId,
          _managerHRId,
        ].whereType<String>().toList();
        final memberIds = _selectedMembers
            .where((id) => !adminIds.contains(id))
            .toList();

        final teamData = {
          'teamName': _teamNameController.text.trim(),
          'adminId': currentUser.uid,
          'teamType': _teamType,
          'projectManagerId': isSuperAdmin
              ? null
              : (_teamType == 'Production Team' ? _projectManagerId : null),
          'assistantProjectManagerId': isSuperAdmin
              ? null
              : (_teamType == 'Production Team'
                    ? _assistantProjectManagerId
                    : null),
          'projectLeadId': isSuperAdmin
              ? null
              : (_teamType == 'Production Team' ? _projectLeadId : null),
          'generalProjectManagerId': isSuperAdmin
              ? null
              : (_teamType == 'General Team' ? _generalProjectManagerId : null),
          'assistantManagerHRId': isSuperAdmin ? null : _assistantManagerHRId,
          'managerHRId': isSuperAdmin ? null : _managerHRId,
          'members': memberIds, // Only regular members
          'admins': adminIds, // New field for admins
          'session1Login': session1Login,
          'session1Logout': session1Logout,
          'session2Login': session2Login,
          'session2Logout': session2Logout,
          'graceTimeInMinutes': int.tryParse(_graceTimeController.text) ?? 0,
          'noLOPDays': int.tryParse(_noLOPController.text) ?? 0,
          'emergencyLeaves': int.tryParse(_emergencyLeaveController.text) ?? 0,
        };

        if (isEditMode) {
          await FirebaseFirestore.instance
              .collection('teams')
              .doc(widget.editTeam!.teamId)
              .update(teamData);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Team updated successfully!')));
        } else {
          await FirebaseFirestore.instance.collection('teams').add(teamData);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Team created successfully!')));
        }

        Navigator.pop(context);
      } catch (e) {
        print('🔥 Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${isEditMode ? 'update' : 'create'} team: ${e.toString()}',
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all required fields and assign appropriate roles.',
          ),
        ),
      );
    }
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay? time,
    Function(TimeOfDay) onPicked,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        TextButton(
          onPressed: () async {
            final picked = await _pickTime(time);
            if (picked != null) setState(() => onPicked(picked));
          },
          child: Text(time == null ? 'Select' : time.format(context)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Edit Team' : 'Create Team')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _currentUserRole == null
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _teamType,
                      decoration: InputDecoration(labelText: 'Team Type'),
                      items: ['Production Team', 'General Team'].map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (val) => setState(() => _teamType = val!),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _teamNameController,
                      decoration: InputDecoration(labelText: 'Team Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter team name' : null,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Shift Timings:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildTimePicker(
                      "Session 1 Login",
                      _session1Login,
                      (val) => _session1Login = val,
                    ),
                    _buildTimePicker(
                      "Session 1 Logout",
                      _session1Logout,
                      (val) => _session1Logout = val,
                    ),
                    _buildTimePicker(
                      "Session 2 Login",
                      _session2Login,
                      (val) => _session2Login = val,
                    ),
                    _buildTimePicker(
                      "Session 2 Logout",
                      _session2Logout,
                      (val) => _session2Logout = val,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _graceTimeController,
                      decoration: InputDecoration(
                        labelText: 'Grace Time (in minutes)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter grace time' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _noLOPController,
                      decoration: InputDecoration(labelText: 'No LOP Days'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter number' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emergencyLeaveController,
                      decoration: InputDecoration(
                        labelText: 'Emergency Leaves',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter number' : null,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _selectMembers,
                      child: Text(
                        'Select Members (${_selectedMembers.length})',
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(isEditMode ? 'Update Team' : 'Create Team'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
