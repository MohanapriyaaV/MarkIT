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

class _SelectMembersPageState extends State<SelectMembersPage> {
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

  Set<String> alreadyAssignedUserIds = {};

  @override
  void initState() {
    super.initState();
    _autoAssignCurrentUser();
    _loadAlreadyAssignedUsers();
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
        _generalProjectManagerId = widget.currentUserId;
        break;
    }
  }

  Future<void> _loadAlreadyAssignedUsers() async {
    final teamsSnapshot = await FirebaseFirestore.instance.collection('teams').get();

    final Set<String> assignedUsers = {};
    for (var doc in teamsSnapshot.docs) {
      final data = doc.data();
      assignedUsers.addAll([
        data['projectManagerId'],
        data['assistantProjectManagerId'],
        data['projectLeadId'],
        data['assistantManagerHRId'],
        data['managerHRId'],
        data['generalProjectManagerId'],
        ...List<String>.from(data['members'] ?? []),
      ].whereType<String>());
    }

    assignedUsers.remove(widget.currentUserId);

    setState(() {
      alreadyAssignedUserIds = assignedUsers;
    });
  }

  List<DocumentSnapshot> _filterByRole(String role) {
    return allUsers.where((doc) =>
      doc['role'] == role &&
      doc.id != widget.currentUserId &&
      !alreadyAssignedUserIds.contains(doc.id)
    ).toList();
  }

  Widget _buildDropdown({
    required String label,
    required String? selectedId,
    required List<DocumentSnapshot> options,
    required void Function(String?)? onChanged,
    bool disabled = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        child: disabled && selectedId != null
            ? Text(
                allUsers.firstWhere((doc) => doc.id == selectedId)['name']
                    .toString(),
              )
            : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedId,
                  isExpanded: true,
                  hint: const Text("Select a member"),
                  items: options.map((doc) {
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(doc['name']),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Team Members')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('employeeInfo').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || (alreadyAssignedUserIds.isEmpty && allUsers.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
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
            final isAssigned = alreadyAssignedUserIds.contains(id);
            final isAdmin = adminRoles.contains(role);

            return !isAssigned &&
                id != widget.currentUserId &&
                role != 'Director' &&
                id != _projectManagerId &&
                id != _assistantProjectManagerId &&
                id != _projectLeadId &&
                id != _assistantManagerHRId &&
                id != _managerHRId &&
                id != _generalProjectManagerId &&
                (widget.isSuperAdmin ? isAdmin : !isAdmin);
          }).toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                if (!widget.isSuperAdmin)
                  ...[
                    if (widget.isGeneralTeam) ...[
                      widget.role == 'General Project Manager'
                          ? _buildDropdown(
                              label: 'General Project Manager',
                              selectedId: _generalProjectManagerId,
                              options: const [],
                              onChanged: null,
                              disabled: true,
                            )
                          : _buildDropdown(
                              label: 'General Project Manager',
                              selectedId: _generalProjectManagerId,
                              options: gpmOptions,
                              onChanged: (val) => setState(() => _generalProjectManagerId = val),
                            ),
                    ] else ...[
                      widget.role == 'Project Manager'
                          ? _buildDropdown(
                              label: 'Project Manager',
                              selectedId: _projectManagerId,
                              options: const [],
                              onChanged: null,
                              disabled: true,
                            )
                          : _buildDropdown(
                              label: 'Project Manager',
                              selectedId: _projectManagerId,
                              options: pmOptions,
                              onChanged: (val) => setState(() => _projectManagerId = val),
                            ),
                      widget.role == 'Assistant Project Manager'
                          ? _buildDropdown(
                              label: 'Assistant Project Manager',
                              selectedId: _assistantProjectManagerId,
                              options: const [],
                              onChanged: null,
                              disabled: true,
                            )
                          : _buildDropdown(
                              label: 'Assistant Project Manager',
                              selectedId: _assistantProjectManagerId,
                              options: apmOptions,
                              onChanged: (val) => setState(() => _assistantProjectManagerId = val),
                            ),
                      widget.role == 'Project Lead'
                          ? _buildDropdown(
                              label: 'Project Lead',
                              selectedId: _projectLeadId,
                              options: const [],
                              onChanged: null,
                              disabled: true,
                            )
                          : _buildDropdown(
                              label: 'Project Lead',
                              selectedId: _projectLeadId,
                              options: plOptions,
                              onChanged: (val) => setState(() => _projectLeadId = val),
                            ),
                    ],

                    widget.role == 'Assistant Manager HR'
                        ? _buildDropdown(
                            label: 'Assistant Manager HR',
                            selectedId: _assistantManagerHRId,
                            options: const [],
                            onChanged: null,
                            disabled: true,
                          )
                        : _buildDropdown(
                            label: 'Assistant Manager HR',
                            selectedId: _assistantManagerHRId,
                            options: amhrOptions,
                            onChanged: (val) => setState(() => _assistantManagerHRId = val),
                          ),

                    widget.role == 'Manager HR'
                        ? _buildDropdown(
                            label: 'Manager HR',
                            selectedId: _managerHRId,
                            options: const [],
                            onChanged: null,
                            disabled: true,
                          )
                        : _buildDropdown(
                            label: 'Manager HR',
                            selectedId: _managerHRId,
                            options: mhrOptions,
                            onChanged: (val) => setState(() => _managerHRId = val),
                          ),
                  ],

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Other Members", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),

                ...otherOptions.map((doc) {
                  final id = doc.id;
                  final name = doc['name'];
                  final role = doc['role'];
                  return CheckboxListTile(
                    title: Text("$name ($role)"),
                    value: _otherMembers.contains(id),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _otherMembers.add(id);
                        } else {
                          _otherMembers.remove(id);
                        }
                      });
                    },
                  );
                }).toList(),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.done),
        label: const Text("Confirm"),
        onPressed: () {
          if (_otherMembers.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select at least one Other Member.")),
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
            if (!widget.isSuperAdmin) ...[
              _assistantManagerHRId,
              _managerHRId,
            ],
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
            'adminId': widget.currentUserId, // ✅ Added to track team creator
          });
        },
      ),
    );
  }
}
