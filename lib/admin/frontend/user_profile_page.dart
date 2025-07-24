import 'package:flutter/material.dart';
import '../../user/models/employee_details_model.dart';
import '../../user/services/employee_details_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  late Future<List<Employee>> _employeesFuture;
  final EmployeeService _employeeService = EmployeeService();

  List<Employee> _allEmployees = [];
  List<Employee> _filteredEmployees = [];
  final TextEditingController _searchController = TextEditingController();
  String? _currentUserRole;
  String? _currentUserEmpId;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fetchCurrentUserRoleAndEmpId();
    _employeesFuture = _employeeService.getAllEmployees();
    _employeesFuture.then((employees) {
      setState(() {
        _allEmployees = employees;
        _filteredEmployees = employees;
      });
      _fadeController.forward();
    });
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchCurrentUserRoleAndEmpId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('employeeInfo').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _currentUserRole = doc['role'];
          _currentUserEmpId = doc['empId'];
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEmployees = _allEmployees.where((emp) {
        final name = (emp.name ?? '').toLowerCase();
        final role = (emp.role ?? '').toLowerCase();
        final userId = (emp.userId ?? '').toLowerCase();
        return name.contains(query) || role.contains(query) || userId.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryTeal = Color(0xFF00BFA6);
    final Color secondaryTeal = Color(0xFF00A693);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryTeal.withOpacity(0.08), secondaryTeal.withOpacity(0.08), Colors.white],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 48, bottom: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryTeal, secondaryTeal, primaryTeal],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryTeal.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.groups, size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text(
                    'User Profiles',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, role, or user ID',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _filteredEmployees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final emp = _filteredEmployees[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _showUserDetails(context, emp),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Colors.grey.shade50],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryTeal.withOpacity(0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primaryTeal, secondaryTeal],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.account_circle_outlined, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        emp.name ?? '-',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: secondaryTeal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: primaryTeal.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: SizedBox(
                                            width: 80,
                                            child: Text(
                                              emp.role ?? '-',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: secondaryTeal,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            emp.department ?? '-',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios, color: primaryTeal, size: 18),
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
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }

  void _showUserDetails(BuildContext context, Employee emp) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserDetailsFullPage(
          employee: emp,
          canEdit: _currentUserRole == 'Manager HR' || _currentUserRole == 'Assistant Manager HR',
          currentUserEmpId: _currentUserEmpId,
          onProfileUpdated: _refreshEmployees,
          allEmployees: _allEmployees,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _refreshEmployees() async {
    final employees = await _employeeService.getAllEmployees();
    setState(() {
      _allEmployees = employees;
      _filteredEmployees = employees;
    });
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label + ':', style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(child: Text(value ?? '-', textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class UserDetailsFullPage extends StatefulWidget {
  final Employee employee;
  final bool canEdit;
  final String? currentUserEmpId;
  final VoidCallback? onProfileUpdated;
  final List<Employee> allEmployees;
  const UserDetailsFullPage({Key? key, required this.employee, required this.canEdit, this.currentUserEmpId, this.onProfileUpdated, required this.allEmployees}) : super(key: key);

  @override
  State<UserDetailsFullPage> createState() => _UserDetailsFullPageState();
}

class _UserDetailsFullPageState extends State<UserDetailsFullPage> {
  late Employee _employee;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _departmentController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _joiningDateController;

  // Helper to get editor name (role) from empId
  Widget editedByWidget(String? empId) {
    if (empId == null || empId.isEmpty) return const Text('-', style: TextStyle(color: Colors.white));
    final editor = widget.allEmployees.firstWhere(
      (e) => e.empId == empId,
      orElse: () => Employee(empId: '', email: ''),
    );
    if (editor.empId.isNotEmpty) {
      return Text(
        (editor.name ?? '-') + ' (' + (editor.role ?? '-') + ')',
        style: const TextStyle(color: Colors.white),
      );
    } else {
      // Optionally: fetch from Firestore if not found in allEmployees
      return FutureBuilder<Employee?>(
        future: EmployeeService().getEmployeeData(empId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
          }
          final emp = snapshot.data;
          if (emp != null) {
            return Text((emp.name ?? '-') + ' (' + (emp.role ?? '-') + ')', style: const TextStyle(color: Colors.white));
          }
          return const Text('-', style: TextStyle(color: Colors.white));
        },
      );
    }
  }

  String _displayRole(String? role, String? department) {
    if ((role ?? '').trim() == 'Project Manager' && (department ?? '').trim() == 'Other Designation') {
      return 'General Project Manager';
    }
    return role ?? '-';
  }

  String _formatSessionTime(dynamic value) {
    if (value == null) return '-';
    try {
      // Handle Firestore Timestamp (from cloud_firestore)
      if (value.runtimeType.toString() == 'Timestamp' || value.toString().contains('Timestamp(')) {
        // Try to extract seconds
        final match = RegExp(r'seconds\s*=\s*(\d+)').firstMatch(value.toString());
        if (match != null) {
          final seconds = int.tryParse(match.group(1)!);
          if (seconds != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
            return dt.hour.toString().padLeft(2, '0') + ':' + dt.minute.toString().padLeft(2, '0') + ':' + dt.second.toString().padLeft(2, '0');
          }
        }
      }
      if (value is String && value.isNotEmpty) {
        // Try to parse as HH:mm:ss
        final parts = value.split(":");
        if (parts.length == 3) {
          return value;
        } else if (parts.length == 2) {
          // If only HH:mm, add :00
          return value + ":00";
        } else {
          // Try DateTime parse fallback
          final dt = DateTime.tryParse(value);
          if (dt != null) {
            return dt.hour.toString().padLeft(2, '0') + ':' + dt.minute.toString().padLeft(2, '0') + ':' + dt.second.toString().padLeft(2, '0');
          }
        }
      } else if (value is Map && value.containsKey('seconds')) {
        final seconds = value['seconds'];
        if (seconds is int) {
          final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          return dt.hour.toString().padLeft(2, '0') + ':' + dt.minute.toString().padLeft(2, '0') + ':' + dt.second.toString().padLeft(2, '0');
        }
      }
    } catch (_) {}
    return value.toString();
  }

  String _formatDateTime(String? value) {
    if (value == null || value.isEmpty) return '-';
    try {
      final dt = DateTime.parse(value);
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return value;
    }
  }

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _nameController = TextEditingController(text: _employee.name);
    _roleController = TextEditingController(text: _employee.role);
    _departmentController = TextEditingController(text: _employee.department);
    _phoneController = TextEditingController(text: _employee.phoneNumber);
    _locationController = TextEditingController(text: _employee.location);
    _joiningDateController = TextEditingController(text: _employee.joiningDate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _joiningDateController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final updates = {
      'name': _nameController.text,
      'role': _roleController.text,
      'department': _departmentController.text,
      'phoneNumber': _phoneController.text,
      'location': _locationController.text,
      'JoiningDate': _joiningDateController.text,
    };
    final service = EmployeeService();
    final success = await service.updateEmployeeWithLog(
      _employee.empId,
      updates,
      widget.currentUserEmpId ?? '',
    );
    if (success) {
      if (widget.onProfileUpdated != null) widget.onProfileUpdated!();
      setState(() {
        _isEditing = false;
        _employee = _employee.copyWith(
          name: _nameController.text,
          role: _roleController.text,
          department: _departmentController.text,
          phoneNumber: _phoneController.text,
          location: _locationController.text,
          joiningDate: _joiningDateController.text,
          editedBy: widget.currentUserEmpId,
          editedAt: DateTime.now().toIso8601String(),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    }
  }

  Future<bool> _showDoubleAuthDialog() async {
    String email = '';
    String password = '';
    bool isLoading = false;
    String? errorMsg;
    final currentUser = FirebaseAuth.instance.currentUser;
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00BFA6).withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_user, color: Color(0xFF00BFA6), size: 28),
                        const SizedBox(width: 10),
                        Text('Verify Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF00BFA6))),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      onChanged: (v) => email = v,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                      obscureText: true,
                      onChanged: (v) => password = v,
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(errorMsg!, style: const TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel', style: TextStyle(color: Color(0xFF00BFA6), fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  setState(() => isLoading = true);
                                  if (currentUser == null || email.trim().toLowerCase() != (currentUser.email?.trim().toLowerCase() ?? '')) {
                                    setState(() {
                                      errorMsg = 'Email does not match current session.';
                                      isLoading = false;
                                    });
                                    return;
                                  }
                                  try {
                                    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
                                    if (cred.user != null) {
                                      Navigator.of(context).pop(true);
                                    } else {
                                      setState(() {
                                        errorMsg = 'Authentication failed.';
                                        isLoading = false;
                                      });
                                    }
                                  } catch (e) {
                                    setState(() {
                                      errorMsg = 'Invalid credentials.';
                                      isLoading = false;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF00BFA6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          ),
                          child: const Text('Verify'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryTeal = Color(0xFF00BFA6);
    final Color secondaryTeal = Color(0xFF00A693);
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        actions: widget.canEdit && !_isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    // Double authentication for Manager HR or Assistant Manager HR
                    final isManager = widget.canEdit;
                    if (isManager) {
                      final verified = await _showDoubleAuthDialog();
                      if (verified) {
                        setState(() => _isEditing = true);
                      }
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
                ),
              ]
            : null,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryTeal, secondaryTeal],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: !_isEditing ? _buildDetailsView() : _buildEditForm(),
        ),
      ),
    );
  }

  Widget _buildDetailsView() {
    final Color primaryTeal = Color(0xFF00BFA6);
    final Color secondaryTeal = Color(0xFF00A693);
    return Center(
      child: Card(
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        color: const Color(0xFFFDF6EC), // Cream white
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: primaryTeal.withOpacity(0.1),
                      child: Icon(Icons.account_circle_outlined, size: 48, color: primaryTeal),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_employee.name ?? '-', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _displayRole(_employee.role, _employee.department),
                              style: TextStyle(fontSize: 12, color: secondaryTeal, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_employee.department ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey.shade800), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: primaryTeal.withOpacity(0.2)),
                const SizedBox(height: 12),
                Text('Contact Info', style: TextStyle(fontWeight: FontWeight.bold, color: secondaryTeal)),
                const SizedBox(height: 8),
                _detailRow('Phone', _employee.phoneNumber, color: Colors.black),
                _detailRow('Location', _employee.location, color: Colors.black),
                _detailRow('Joining Date', _employee.joiningDate, color: Colors.black),
                _detailRow('User ID', _employee.userId, color: Colors.black),
                const SizedBox(height: 18),
                Divider(color: primaryTeal.withOpacity(0.2)),
                const SizedBox(height: 12),
                Text('Leave & Shift', style: TextStyle(fontWeight: FontWeight.bold, color: secondaryTeal)),
                const SizedBox(height: 8),
                if (_employee.leaveLimits != null) ...[
                  _detailRow('Emergency Leaves', _employee.leaveLimits?['emergencyLeaves']?.toString(), color: Colors.black),
                  _detailRow('No LOP Days', _employee.leaveLimits?['noLOPDays']?.toString(), color: Colors.black),
                ],
                if (_employee.shiftTiming != null) ...[
                  _detailRow('Grace Time (min)', _employee.shiftTiming?['graceTimeInMinutes']?.toString(), color: Colors.black),
                  _detailRow('Session 1 Login', _formatSessionTime(_employee.shiftTiming?['session1Login']), color: Colors.black),
                  _detailRow('Session 1 Logout', _formatSessionTime(_employee.shiftTiming?['session1Logout']), color: Colors.black),
                  _detailRow('Session 2 Login', _formatSessionTime(_employee.shiftTiming?['session2Login']), color: Colors.black),
                  _detailRow('Session 2 Logout', _formatSessionTime(_employee.shiftTiming?['session2Logout']), color: Colors.black),
                ],
                const SizedBox(height: 18),
                Divider(color: primaryTeal.withOpacity(0.2)),
                const SizedBox(height: 12),
                Text('Edit Log', style: TextStyle(fontWeight: FontWeight.bold, color: secondaryTeal)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Edited By:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                      Flexible(child: FutureBuilder<String>(
                        future: _getEditedByNameRole(_employee.editedBy),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(width: 60, height: 16, child: LinearProgressIndicator(minHeight: 2));
                          }
                          return Text(
                            snapshot.data ?? '-',
                            style: const TextStyle(color: Colors.black),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      )),
                    ],
                  ),
                ),
                _detailRow('Edited At', _formatDateTime(_employee.editedAt), color: Colors.black),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    final Color primaryTeal = Color(0xFF00BFA6);
    final Color secondaryTeal = Color(0xFF00A693);
    // Controllers for nested fields
    final leaveEmergencyController = TextEditingController(text: _employee.leaveLimits?['emergencyLeaves']?.toString() ?? '');
    final leaveNoLOPController = TextEditingController(text: _employee.leaveLimits?['noLOPDays']?.toString() ?? '');
    final shiftGraceController = TextEditingController(text: _employee.shiftTiming?['graceTimeInMinutes']?.toString() ?? '');
    final session1LoginController = TextEditingController(text: _employee.shiftTiming?['session1Login']?.toString() ?? '');
    final session1LogoutController = TextEditingController(text: _employee.shiftTiming?['session1Logout']?.toString() ?? '');
    final session2LoginController = TextEditingController(text: _employee.shiftTiming?['session2Login']?.toString() ?? '');
    final session2LogoutController = TextEditingController(text: _employee.shiftTiming?['session2Logout']?.toString() ?? '');

    // Dropdown state
    String selectedDepartment = _departmentController.text.isNotEmpty ? _departmentController.text : EmployeeFormData.departmentOptions.first;
    List<String> getRoleOptions(String department) {
      switch (department) {
        case 'Production':
          return EmployeeFormData.productionRoles;
        case 'Other Designation':
          return EmployeeFormData.otherDesignationRoles;
        case 'Admin':
          return EmployeeFormData.adminRoles;
        case 'Recruiters':
          return EmployeeFormData.recruiterRoles;
        default:
          return [];
      }
    }
    String selectedRole = _roleController.text.isNotEmpty ? _roleController.text : getRoleOptions(selectedDepartment).first;

    return StatefulBuilder(
      builder: (context, setState) {
        return Center(
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeIn,
            child: Card( 
              elevation: 12,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              color: const Color(0xFFFDF6EC), // Cream white
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: primaryTeal.withOpacity(0.12), width: 1)),
              shadowColor: primaryTeal.withOpacity(0.15),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: primaryTeal.withOpacity(0.1),
                              child: Icon(Icons.account_circle_outlined, size: 48, color: primaryTeal),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(labelText: 'Name'),
                                    validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: selectedRole == 'Project Manager' && selectedDepartment == 'Other Designation' ? 'General Project Manager' : selectedRole,
                                    decoration: const InputDecoration(labelText: 'Role'),
                                    isExpanded: true,
                                    items: getRoleOptions(selectedDepartment).map((role) {
                                      final display = (role == 'Project Manager' && selectedDepartment == 'Other Designation') ? 'General Project Manager' : role;
                                      return DropdownMenuItem(
                                        value: display,
                                        child: Text(display, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          selectedRole = val;
                                          _roleController.text = val;
                                        });
                                      }
                                    },
                                    validator: (v) => v == null || v.isEmpty ? 'Role required' : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    selectedRole,
                                    style: TextStyle(fontSize: 13, color: secondaryTeal, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    value: selectedDepartment,
                                    decoration: const InputDecoration(labelText: 'Department'),
                                    isExpanded: true,
                                    items: EmployeeFormData.departmentOptions.map((dept) => DropdownMenuItem(
                                      value: dept,
                                      child: Text(dept, overflow: TextOverflow.ellipsis),
                                    )).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          selectedDepartment = val;
                                          // Update role to first of new department
                                          selectedRole = getRoleOptions(val).first;
                                          _departmentController.text = val;
                                          _roleController.text = selectedRole;
                                        });
                                      }
                                    },
                                    validator: (v) => v == null || v.isEmpty ? 'Department required' : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    selectedDepartment,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Divider(color: primaryTeal.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Text('Contact Info', style: TextStyle(fontWeight: FontWeight.bold, color: secondaryTeal)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(labelText: 'Location'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _joiningDateController,
                          decoration: const InputDecoration(labelText: 'Joining Date'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _employee.userId,
                          decoration: const InputDecoration(labelText: 'User ID'),
                          readOnly: true,
                        ),
                        const SizedBox(height: 18),
                        Divider(color: primaryTeal.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Text('Leave & Shift', style: TextStyle(fontWeight: FontWeight.bold, color: secondaryTeal)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: leaveEmergencyController,
                          decoration: const InputDecoration(labelText: 'Emergency Leaves'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: leaveNoLOPController,
                          decoration: const InputDecoration(labelText: 'No LOP Days'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: shiftGraceController,
                          decoration: const InputDecoration(labelText: 'Grace Time (min)'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => pickTime(session1LoginController),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: session1LoginController,
                              decoration: const InputDecoration(labelText: 'Session 1 Login (HH:mm:ss)'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => pickTime(session1LogoutController),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: session1LogoutController,
                              decoration: const InputDecoration(labelText: 'Session 1 Logout (HH:mm:ss)'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => pickTime(session2LoginController),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: session2LoginController,
                              decoration: const InputDecoration(labelText: 'Session 2 Login (HH:mm:ss)'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => pickTime(session2LogoutController),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: session2LogoutController,
                              decoration: const InputDecoration(labelText: 'Session 2 Logout (HH:mm:ss)'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() => _isEditing = false);
                              },
                              child: Text('Cancel', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                if (!_formKey.currentState!.validate()) return;
                                String saveRole = selectedRole;
                                if (saveRole == 'General Project Manager' && selectedDepartment == 'Other Designation') {
                                  saveRole = 'General Project Manager';
                                }
                                final updates = {
                                  'name': _nameController.text,
                                  'role': saveRole,
                                  'department': selectedDepartment,
                                  'phoneNumber': _phoneController.text,
                                  'location': _locationController.text,
                                  'JoiningDate': _joiningDateController.text,
                                  'leaveLimits': {
                                    'emergencyLeaves': int.tryParse(leaveEmergencyController.text) ?? 0,
                                    'noLOPDays': int.tryParse(leaveNoLOPController.text) ?? 0,
                                  },
                                  'shiftTiming': {
                                    'graceTimeInMinutes': int.tryParse(shiftGraceController.text) ?? 0,
                                    'session1Login': session1LoginController.text,
                                    'session1Logout': session1LogoutController.text,
                                    'session2Login': session2LoginController.text,
                                    'session2Logout': session2LogoutController.text,
                                  },
                                };
                                final service = EmployeeService();
                                final success = await service.updateEmployeeWithLog(
                                  _employee.empId,
                                  updates,
                                  widget.currentUserEmpId ?? '',
                                );
                                if (success) {
                                  if (widget.onProfileUpdated != null) widget.onProfileUpdated!();
                                  setState(() {
                                    _isEditing = false;
                                    _employee = _employee.copyWith(
                                      name: _nameController.text,
                                      role: saveRole,
                                      department: selectedDepartment,
                                      phoneNumber: _phoneController.text,
                                      location: _locationController.text,
                                      joiningDate: _joiningDateController.text,
                                      leaveLimits: {
                                        'emergencyLeaves': int.tryParse(leaveEmergencyController.text) ?? 0,
                                        'noLOPDays': int.tryParse(leaveNoLOPController.text) ?? 0,
                                      },
                                      shiftTiming: {
                                        'graceTimeInMinutes': int.tryParse(shiftGraceController.text) ?? 0,
                                        'session1Login': session1LoginController.text,
                                        'session1Logout': session1LogoutController.text,
                                        'session2Login': session2LoginController.text,
                                        'session2Logout': session2LogoutController.text,
                                      },
                                      editedBy: widget.currentUserEmpId,
                                      editedAt: DateTime.now().toIso8601String(),
                                    );
                                  });
                                  // Delay to show the snackbar, then return to details view
                                  Future.delayed(const Duration(milliseconds: 500), () {
                                    if (mounted) setState(() => _isEditing = false);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  }

                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryTeal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              ),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String? value, {Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label + ':', style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          Flexible(child: Text(value ?? '-', textAlign: TextAlign.right, style: TextStyle(color: color), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Future<void> pickTime(TextEditingController controller) async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: () {
        final text = controller.text;
        if (text.isNotEmpty) {
          final parts = text.split(":");
          if (parts.length >= 2) {
            return TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 0,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
        return TimeOfDay.now();
      }(),
    );
    if (time != null) {
      controller.text = time.format(context) + ':00';
      // Ensure always HH:mm:ss
      final parsed = TimeOfDay(hour: time.hour, minute: time.minute);
      controller.text = parsed.hour.toString().padLeft(2, '0') + ':' + parsed.minute.toString().padLeft(2, '0') + ':00';
    }
  }

  Future<String> _getEditedByNameRole(String? empId) async {
    if (empId == null || empId.isEmpty) return '-';
    try {
      final doc = await FirebaseFirestore.instance.collection('employeeInfo').doc(empId).get();
      if (doc.exists) {
        final name = doc['name'] ?? empId;
        final role = doc['role'] ?? '';
        return role.isNotEmpty ? '$name($role)' : name;
      }
    } catch (_) {}
    return empId;
  }
} 