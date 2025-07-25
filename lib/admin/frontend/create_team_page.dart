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

class _CreateTeamPageState extends State<CreateTeamPage>
    with TickerProviderStateMixin {
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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool get isEditMode => widget.editTeam != null;
  bool get isSuperAdmin =>
      _currentUserRole == 'Director' || _currentUserRole == 'CEO';

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0.0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        _animationController.forward(); // Start animation after data is loaded
      }
    }
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay? initialTime) {
    return showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSwatch().copyWith(
              primary: Color(0xFF00BFA6),
            ),
          ),
          child: child!,
        );
      },
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final adminIds = <String?>[
          _projectManagerId,
          _assistantProjectManagerId,
          _projectLeadId,
          _assistantManagerHRId,
          _managerHRId,
        ].whereType<String>().toList();

        final memberIds = _selectedMembers
            .where((id) => !adminIds.contains(id))
            .toList();


        final teamModel = TeamModel(
          teamId: isEditMode ? widget.editTeam!.teamId : '',
          teamName: _teamNameController.text.trim(),
          adminId: currentUser.uid,
          teamType: _teamType,
          projectManagerId: isSuperAdmin ? null : (_teamType == 'Production Team' ? _projectManagerId : null),
          assistantProjectManagerId: isSuperAdmin ? null : (_teamType == 'Production Team' ? _assistantProjectManagerId : null),
          projectLeadId: isSuperAdmin ? null : (_teamType == 'Production Team' ? _projectLeadId : null),
          generalProjectManagerId: isSuperAdmin ? null : (_teamType == 'General Team' ? _generalProjectManagerId : null),
          assistantManagerHRId: isSuperAdmin ? null : _assistantManagerHRId,
          managerHRId: isSuperAdmin ? null : _managerHRId,
          members: memberIds,
          admins: adminIds,
          session1Login: session1Login,
          session1Logout: session1Logout,
          session2Login: session2Login,
          session2Logout: session2Logout,
          graceTimeInMinutes: int.tryParse(_graceTimeController.text) ?? 0,
          noLOPDays: int.tryParse(_noLOPController.text) ?? 0,
          emergencyLeaves: int.tryParse(_emergencyLeaveController.text) ?? 2,
        );

        final TeamService _teamService = TeamService();
        if (isEditMode) {
          await _teamService.updateTeam(teamModel);
        } else {
          await _teamService.createTeam(teamModel);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? 'Team updated successfully!'
                  : 'Team created successfully!',
            ),
            backgroundColor: Color(0xFF00BFA6),
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildAnimatedCard({required Widget child}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(opacity: _fadeAnimation, child: child),
        );
      },
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixIcon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Color(0xFF00BFA6), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay? time,
    Function(TimeOfDay) onPicked,
    IconData icon,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFF8F9FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () async {
            final picked = await _pickTime(time);
            if (picked != null) setState(() => onPicked(picked));
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Color(0xFF00BFA6)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF00BFA6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    time == null ? 'Select' : time.format(context),
                    style: TextStyle(
                      color: Color(0xFF00BFA6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    Color? color,
    Widget? icon,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: color != null
                  ? [color, color.withOpacity(0.8)]
                  : [Color(0xFF00BFA6), Color(0xFF00A693)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon, SizedBox(width: 8)],
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00BFA6), Color(0xFF00A693)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        isEditMode ? 'Edit Team' : 'Create Team',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Form Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _currentUserRole == null
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00BFA6),
                          ),
                        )
                      : _buildAnimatedCard(
                          child: Form(
                            key: _formKey,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Team Type Dropdown
                                  Container(
                                    margin: EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      value: _teamType,
                                      decoration: InputDecoration(
                                        labelText: 'Team Type',
                                        prefixIcon: Icon(
                                          Icons.group_work,
                                          color: Color(0xFF00BFA6),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      items: ['Production Team', 'General Team']
                                          .map((type) {
                                            return DropdownMenuItem(
                                              value: type,
                                              child: Text(type),
                                            );
                                          })
                                          .toList(),
                                      onChanged: (val) =>
                                          setState(() => _teamType = val!),
                                    ),
                                  ),

                                  // Team Name Field
                                  _buildTextField(
                                    controller: _teamNameController,
                                    label: 'Team Name',
                                    validator: (value) => value!.isEmpty
                                        ? 'Enter team name'
                                        : null,
                                    prefixIcon: Icon(
                                      Icons.group,
                                      color: Color(0xFF00BFA6),
                                    ),
                                  ),

                                  // Shift Timings Section
                                  Container(
                                    margin: EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      'Shift Timings',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ),

                                  _buildTimePicker(
                                    'Session 1 Login',
                                    _session1Login,
                                    (val) => _session1Login = val,
                                    Icons.login,
                                  ),
                                  _buildTimePicker(
                                    'Session 1 Logout',
                                    _session1Logout,
                                    (val) => _session1Logout = val,
                                    Icons.logout,
                                  ),
                                  _buildTimePicker(
                                    'Session 2 Login',
                                    _session2Login,
                                    (val) => _session2Login = val,
                                    Icons.login,
                                  ),
                                  _buildTimePicker(
                                    'Session 2 Logout',
                                    _session2Logout,
                                    (val) => _session2Logout = val,
                                    Icons.logout,
                                  ),

                                  // Numeric Fields
                                  _buildTextField(
                                    controller: _graceTimeController,
                                    label: 'Grace Time (in minutes)',
                                    validator: (value) => value!.isEmpty
                                        ? 'Enter grace time'
                                        : null,
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icon(
                                      Icons.timer,
                                      color: Color(0xFF00BFA6),
                                    ),
                                  ),

                                  _buildTextField(
                                    controller: _noLOPController,
                                    label: 'No LOP Days',
                                    validator: (value) =>
                                        value!.isEmpty ? 'Enter number' : null,
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF00BFA6),
                                    ),
                                  ),

                                  _buildTextField(
                                    controller: _emergencyLeaveController,
                                    label: 'Emergency Leaves',
                                    validator: (value) =>
                                        value!.isEmpty ? 'Enter number' : null,
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icon(
                                      Icons.emergency,
                                      color: Color(0xFF00BFA6),
                                    ),
                                  ),

                                  // Select Members Button
                                  _buildGradientButton(
                                    text:
                                        'Select Members (${_selectedMembers.length})',
                                    onPressed: _selectMembers,
                                    color: Color(0xFF3498DB),
                                    icon: Icon(
                                      Icons.people,
                                      color: Colors.white,
                                    ),
                                  ),

                                  // Submit Button
                                  _buildGradientButton(
                                    text: isEditMode
                                        ? 'Update Team'
                                        : 'Create Team',
                                    onPressed: _submit,
                                    icon: Icon(
                                      isEditMode ? Icons.update : Icons.add,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
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
}
