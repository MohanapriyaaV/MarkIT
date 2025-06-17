import 'package:flutter/material.dart';
import '../models/employee_details_model.dart';
import '../services/employee_details_service.dart';

class EmployeeFormPage extends StatefulWidget {
  final String uid;
  final String email;

  const EmployeeFormPage({super.key, required this.uid, required this.email});

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _joiningDateController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  late TextEditingController _emailController;
  final EmployeeService _employeeService = EmployeeService();

  late AnimationController _animationController;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;

  String? name, role, phone, location, employeeId;
  String? selectedRole, selectedDepartment;
  bool isCheckingEmployeeId = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _joiningDateController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectJoiningDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _joiningDateController.text = picked.toLocal().toString().split(' ')[0];
    }
  }

  Future<bool> _validateEmployeeId(String employeeId) async {
    // Check format: VISTA followed by 4 digits
    final RegExp vistaRegex = RegExp(r'^VISTA\d{4}$');
    if (!vistaRegex.hasMatch(employeeId)) {
      return false;
    }

    // Check if employee ID already exists in database
    bool exists = await _employeeService.employeeIdExists(employeeId);
    return !exists;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Validate employee ID
      if (employeeId != null) {
        setState(() {
          isCheckingEmployeeId = true;
        });

        bool isValidEmployeeId = await _validateEmployeeId(employeeId!);
        
        setState(() {
          isCheckingEmployeeId = false;
        });

        if (!isValidEmployeeId) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Employee ID format should be VISTA followed by 4 digits and must be unique."),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        }
      }

      // Create Employee object
      final employee = Employee(
        name: name?.trim(),
        role: selectedRole,
        department: selectedDepartment,
        email: widget.email,
        phoneNumber: phone?.trim(),
        location: location?.trim(),
        joiningDate: _joiningDateController.text,
        empId: widget.uid,
        userId: employeeId,
        emergencyLeave: 0,
      );

      // Save using service
      bool success = await _employeeService.saveEmployeeData(employee);

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Error saving details."),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _animation,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.15),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: controller,
              readOnly: readOnly,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
              keyboardType: keyboardType,
              validator: validator,
              onSaved: onSaved,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _animation,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.15),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
              dropdownColor: const Color(0xFF6366F1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              validator: validator,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _animation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 45,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Register Your Details",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please fill in your information to complete your profile",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getRolesByDepartment(String? department) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1), // Indigo
              Color(0xFF8B5CF6), // Purple
              Color(0xFFA855F7), // Purple
              Color(0xFFEC4899), // Pink
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildTextField(
                          label: "Full Name",
                          icon: Icons.person_rounded,
                          validator: (val) => val!.isEmpty ? "Enter name" : null,
                          onSaved: (val) => name = val?.trim(),
                        ),
                        _buildTextField(
                          label: "Employee ID",
                          icon: Icons.badge_rounded,
                          controller: _employeeIdController,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Enter employee ID";
                            }
                            final RegExp vistaRegex = RegExp(r'^VISTA\d{4}$');
                            if (!vistaRegex.hasMatch(val)) {
                              return "Format: VISTA followed by 4 digits";
                            }
                            return null;
                          },
                          onSaved: (val) => employeeId = val?.trim(),
                        ),
                        _buildDropdownField(
                          label: "Department",
                          icon: Icons.business_rounded,
                          items: EmployeeFormData.departmentOptions,
                          value: selectedDepartment,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedDepartment = newValue;
                              selectedRole = null; // Reset role when department changes
                            });
                          },
                          validator: (val) => val == null ? "Select a department" : null,
                        ),
                        if (selectedDepartment != null)
                          _buildDropdownField(
                            label: "Role",
                            icon: Icons.work_rounded,
                            items: _getRolesByDepartment(selectedDepartment),
                            value: selectedRole,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedRole = newValue;
                              });
                            },
                            validator: (val) => val == null ? "Select a role" : null,
                          ),
                        _buildTextField(
                          label: "Email",
                          icon: Icons.email_rounded,
                          controller: _emailController,
                          readOnly: true,
                          validator: (val) => null,
                          onSaved: (_) {},
                        ),
                        _buildTextField(
                          label: "Phone Number",
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          validator: (val) {
                            final phoneExp = RegExp(r'^\d{10,15}$');
                            return (val != null && phoneExp.hasMatch(val))
                                ? null
                                : "Enter a valid phone number";
                          },
                          onSaved: (val) => phone = val?.trim(),
                        ),
                        _buildTextField(
                          label: "Address",
                          icon: Icons.location_on_rounded,
                          validator: (val) => val!.isEmpty ? "Enter location" : null,
                          onSaved: (val) => location = val?.trim(),
                        ),
                        _buildTextField(
                          label: "Joining Date",
                          icon: Icons.calendar_today_rounded,
                          controller: _joiningDateController,
                          readOnly: true,
                          validator: (val) => val!.isEmpty ? "Pick a date" : null,
                          onSaved: (_) {},
                          onTap: _selectJoiningDate,
                        ),
                        const SizedBox(height: 20),
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _animation,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isCheckingEmployeeId ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF6366F1),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isCheckingEmployeeId
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF6366F1),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "Validating...",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 22,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "Submit Details",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
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
}