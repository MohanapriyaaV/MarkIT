import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectMembersPage extends StatefulWidget {
  final List<String> selectedMembers;
  final String currentUserId;
  final String role;
  final bool isGeneralTeam;
  final bool isSuperAdmin;

  const SelectMembersPage({
    Key? key,
    this.selectedMembers = const [],
    required this.currentUserId,
    required this.role,
    this.isGeneralTeam = false,
    this.isSuperAdmin = false,
  }) : super(key: key);

  @override
  _SelectMembersPageState createState() => _SelectMembersPageState();
}

class _SelectMembersPageState extends State<SelectMembersPage> 
    with TickerProviderStateMixin {
  String? _projectManagerId;
  String? _assistantProjectManagerId;
  String? _projectLeadId;
  String? _assistantManagerHRId;
  String? _managerHRId;
  String? _generalProjectManagerId;

  final Set<String> _otherMembers = {};
  List<DocumentSnapshot> allUsers = [];

  final List<String> adminRoles = [
    'Project Manager',
    'Assistant Project Manager',
    'Project Lead',
    'Assistant Manager HR',
    'Manager HR',
    'General Project Manager',
  ];

  // Set<String> alreadyAssignedUserIds = {}; // No longer needed

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _autoAssignCurrentUser();
    _loadAlreadyAssignedUsers();
    
    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _autoAssignCurrentUser() {
    switch (widget.role) {
      case 'Project Manager':
        _projectManagerId = widget.currentUserId;
        break;
      case 'Assistant Project Manager':
        _assistantProjectManagerId = widget.currentUserId;
        break;
      case 'Project Lead':
        _projectLeadId = widget.currentUserId;
        break;
      case 'Assistant Manager HR':
        _assistantManagerHRId = widget.currentUserId;
        break;
      case 'Manager HR':
        _managerHRId = widget.currentUserId;
        break;
      case 'General Project Manager':
    // _loadAlreadyAssignedUsers(); // Remove constraint logic
        break;
    }
  }

  void _loadAlreadyAssignedUsers() async {
    // Removed: No longer filter out already assigned users
  }

  List<DocumentSnapshot> _filterByRole(String role) {
    return allUsers
        .where(
          (doc) =>
              doc['role'] == role &&
              doc.id != widget.currentUserId,
        )
        .toList();
  }

  Widget _buildAnimatedCard({required Widget child}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? selectedId,
    required List<DocumentSnapshot> options,
    required void Function(String?)? onChanged,
    bool disabled = false,
    IconData? icon,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: disabled 
          ? LinearGradient(
              colors: [Color(0xFFE8F5E8), Color(0xFFE0F2F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: [Colors.white, Color(0xFFF8F9FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: disabled ? Colors.grey : Color(0xFF00BFA6),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: disabled ? Colors.grey : Color(0xFF2C3E50),
                  ),
                ),
                if (disabled) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFF00BFA6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'You',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF00BFA6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 8),
            disabled && selectedId != null
                ? Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      allUsers.firstWhere((doc) => doc.id == selectedId)['name']
                          .toString(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2C3E50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedId,
                        isExpanded: true,
                        hint: Text(
                          "Select a member",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        items: options.map((doc) {
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(
                              doc['name'],
                              style: TextStyle(
                                color: Color(0xFF2C3E50),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: onChanged,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF00BFA6),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(DocumentSnapshot doc) {
    final id = doc.id;
    final name = doc['name'];
    final role = doc['role'];
    final isSelected = _otherMembers.contains(id);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [Color(0xFF00BFA6).withOpacity(0.1), Color(0xFF00A693).withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.white, Color(0xFFF8F9FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: isSelected
            ? Border.all(color: Color(0xFF00BFA6), width: 2)
            : Border.all(color: Colors.transparent, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              if (isSelected) {
                _otherMembers.remove(id);
              } else {
                _otherMembers.add(id);
              }
            });
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF00BFA6) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Color(0xFF00BFA6) : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        role,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF00BFA6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Selected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
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
                        'Select Team Members',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        '${_otherMembers.length} selected',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('employeeInfo')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00BFA6),
                          ),
                        );
                      }
                      
                      allUsers = snapshot.data!.docs;

                      final pmOptions = _filterByRole('Project Manager');
                      final apmOptions = _filterByRole('Assistant Project Manager');
                      final plOptions = _filterByRole('Project Lead');
                      final amhrOptions = _filterByRole('Assistant Manager HR');
                      final mhrOptions = _filterByRole('Manager HR');
                      final gpmOptions = _filterByRole('General Project Manager');

                      final otherOptions = allUsers.where((doc) {
                        final id = doc.id;
                        final role = doc['role'];
                        final isAdmin = adminRoles.contains(role);

                        return id != widget.currentUserId &&
                            role != 'Director' &&
                            id != _projectManagerId &&
                            id != _assistantProjectManagerId &&
                            id != _projectLeadId &&
                            id != _assistantManagerHRId &&
                            id != _managerHRId &&
                            id != _generalProjectManagerId &&
                            (widget.isSuperAdmin ? isAdmin : !isAdmin);
                      }).toList();

                      return _buildAnimatedCard(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!widget.isSuperAdmin) ...[
                                Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    'Team Leadership',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                ),
                                
                                if (widget.isGeneralTeam) ...[
                                  _buildDropdown(
                                    label: 'General Project Manager',
                                    selectedId: _generalProjectManagerId,
                                    options: widget.role == 'General Project Manager' ? [] : gpmOptions,
                                    onChanged: widget.role == 'General Project Manager' 
                                        ? null 
                                        : (val) => setState(() => _generalProjectManagerId = val),
                                    disabled: widget.role == 'General Project Manager',
                                    icon: Icons.stars,
                                  ),
                                ] else ...[
                                  _buildDropdown(
                                    label: 'Project Manager',
                                    selectedId: _projectManagerId,
                                    options: widget.role == 'Project Manager' ? [] : pmOptions,
                                    onChanged: widget.role == 'Project Manager' 
                                        ? null 
                                        : (val) => setState(() => _projectManagerId = val),
                                    disabled: widget.role == 'Project Manager',
                                    icon: Icons.supervisor_account,
                                  ),
                                  _buildDropdown(
                                    label: 'Assistant Project Manager',
                                    selectedId: _assistantProjectManagerId,
                                    options: widget.role == 'Assistant Project Manager' ? [] : apmOptions,
                                    onChanged: widget.role == 'Assistant Project Manager' 
                                        ? null 
                                        : (val) => setState(() => _assistantProjectManagerId = val),
                                    disabled: widget.role == 'Assistant Project Manager',
                                    icon: Icons.person_add,
                                  ),
                                  _buildDropdown(
                                    label: 'Project Lead',
                                    selectedId: _projectLeadId,
                                    options: widget.role == 'Project Lead' ? [] : plOptions,
                                    onChanged: widget.role == 'Project Lead' 
                                        ? null 
                                        : (val) => setState(() => _projectLeadId = val),
                                    disabled: widget.role == 'Project Lead',
                                    icon: Icons.trending_up,
                                  ),
                                ],

                                _buildDropdown(
                                  label: 'Assistant Manager HR',
                                  selectedId: _assistantManagerHRId,
                                  options: widget.role == 'Assistant Manager HR' ? [] : amhrOptions,
                                  onChanged: widget.role == 'Assistant Manager HR' 
                                      ? null 
                                      : (val) => setState(() => _assistantManagerHRId = val),
                                  disabled: widget.role == 'Assistant Manager HR',
                                  icon: Icons.people_outline,
                                ),
                                _buildDropdown(
                                  label: 'Manager HR',
                                  selectedId: _managerHRId,
                                  options: widget.role == 'Manager HR' ? [] : mhrOptions,
                                  onChanged: widget.role == 'Manager HR' 
                                      ? null 
                                      : (val) => setState(() => _managerHRId = val),
                                  disabled: widget.role == 'Manager HR',
                                  icon: Icons.people,
                                ),
                                
                                SizedBox(height: 24),
                              ],

                              Container(
                                margin: EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.group,
                                      color: Color(0xFF00BFA6),
                                      size: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Team Members',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (otherOptions.isEmpty)
                                Container(
                                  padding: EdgeInsets.all(20),
                                  margin: EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No available members to select',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...otherOptions.map((doc) => _buildMemberTile(doc)).toList(),

                              SizedBox(height: 100),
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
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 16, right: 16),
        child: FloatingActionButton.extended(
          backgroundColor: Color(0xFF00BFA6),
          onPressed: () {
            if (_otherMembers.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Please select at least one team member."),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              return;
            }

            final allMembers = {
              widget.currentUserId,
              if (!widget.isSuperAdmin && widget.isGeneralTeam)
                _generalProjectManagerId,
              if (!widget.isSuperAdmin && !widget.isGeneralTeam) ...[
                _projectManagerId,
                _assistantProjectManagerId,
                _projectLeadId,
              ],
              if (!widget.isSuperAdmin) ...[_assistantManagerHRId, _managerHRId],
              ..._otherMembers,
            }.whereType<String>().toSet().toList();

            Navigator.pop(context, {
              'members': allMembers,
              'projectManagerId': _projectManagerId,
              'assistantProjectManagerId': _assistantProjectManagerId,
              'projectLeadId': _projectLeadId,
              'assistantManagerHRId': _assistantManagerHRId,
              'managerHRId': _managerHRId,
              'generalProjectManagerId': _generalProjectManagerId,
              'adminId': widget.currentUserId,
            });
          },
          icon: Icon(Icons.check, color: Colors.white),
          label: Text(
            'Confirm Selection',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevation: 8,
        ),
      ),
    );
  }
}