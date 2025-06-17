import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectMembersPage extends StatefulWidget {
  final List<String> selectedMembers;
  final String currentUserId;
  final String role;

  const SelectMembersPage({
    Key? key,
    this.selectedMembers = const [],
    required this.currentUserId,
    required this.role,
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

  final Set<String> _otherMembers = {};
  List<DocumentSnapshot> allUsers = [];

  @override
  void initState() {
    super.initState();
    _autoAssignCurrentUser();
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
    }
  }

  List<DocumentSnapshot> _filterByRole(String role) {
    return allUsers
        .where((doc) => doc['role'] == role && doc.id != widget.currentUserId)
        .toList();
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
        child: disabled
            ? Text(
                allUsers
                    .firstWhere((doc) => doc.id == selectedId)['name']
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
        stream:
            FirebaseFirestore.instance.collection('employeeInfo').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          allUsers = snapshot.data!.docs;

          final pmOptions = _filterByRole('Project Manager');
          final apmOptions = _filterByRole('Assistant Project Manager');
          final plOptions = _filterByRole('Project Lead');
          final amhrOptions = _filterByRole('Assistant Manager HR');
          final mhrOptions = _filterByRole('Manager HR');

          final adminRoles = [
            'Project Manager',
            'Assistant Project Manager',
            'Project Lead',
            'Assistant Manager HR',
            'Manager HR',
          ];

          final otherOptions = allUsers.where((doc) {
            final id = doc.id;
            final role = doc['role'];
            return !adminRoles.contains(role) &&
                id != widget.currentUserId &&
                id != _projectManagerId &&
                id != _assistantProjectManagerId &&
                id != _projectLeadId &&
                id != _assistantManagerHRId &&
                id != _managerHRId;
          }).toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Project Manager
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
                        onChanged: (val) =>
                            setState(() => _projectManagerId = val),
                      ),

                // Assistant Project Manager
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
                        onChanged: (val) =>
                            setState(() => _assistantProjectManagerId = val),
                      ),

                // Project Lead
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
                        onChanged: (val) =>
                            setState(() => _projectLeadId = val),
                      ),

                // Assistant Manager HR
                _buildDropdown(
                  label: 'Assistant Manager HR',
                  selectedId: _assistantManagerHRId,
                  options: amhrOptions,
                  onChanged: (val) =>
                      setState(() => _assistantManagerHRId = val),
                ),

                // Manager HR
                _buildDropdown(
                  label: 'Manager HR',
                  selectedId: _managerHRId,
                  options: mhrOptions,
                  onChanged: (val) => setState(() => _managerHRId = val),
                ),

                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Other Members",
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
          if (_projectManagerId == null ||
              _assistantProjectManagerId == null ||
              _projectLeadId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please assign all 3 main roles.")),
            );
            return;
          }

          final allMembers = {
            widget.currentUserId,
            if (_projectManagerId != widget.currentUserId)
              _projectManagerId,
            if (_assistantProjectManagerId != widget.currentUserId)
              _assistantProjectManagerId,
            if (_projectLeadId != widget.currentUserId)
              _projectLeadId,
            ..._otherMembers,
          }.whereType<String>().toSet().toList();

          Navigator.pop(context, {
            'members': allMembers,
            'projectManagerId': _projectManagerId,
            'assistantProjectManagerId': _assistantProjectManagerId,
            'projectLeadId': _projectLeadId,
            'assistantManagerHRId': _assistantManagerHRId,
            'managerHRId': _managerHRId,
          });
        },
      ),
    );
  }
}
