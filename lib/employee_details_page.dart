import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  late TextEditingController _emailController;

  late AnimationController _animationController;
  late Animation<double> _animation;

  String? name, designation, department, phone, location, manager;

  final Color primaryPurple = const Color(0xFF6A0DAD);
  final Color lightLavender = const Color(0xFFE6E6FA);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _joiningDateController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectJoiningDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );
    if (picked != null) {
      _joiningDateController.text = picked.toLocal().toString().split(' ')[0];
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final data = {
        'name': name ?? '',
        'role': designation ?? '',
        'department': department ?? '',
        'email': widget.email,
        'phoneNumber': phone ?? '',
        'location': location ?? '',
        'JoiningDate': _joiningDateController.text,
        'Manager': manager ?? '',
        'empId': widget.uid,
        'emergency_leave': 0,
      };

      try {
        await FirebaseFirestore.instance
            .collection('employeeInfo')
            .doc(widget.uid)
            .set(data, SetOptions(merge: true));

        await showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text("✅ Employee Info Submitted"),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Name: $name"),
                        Text("Designation: $designation"),
                        Text("Department: $department"),
                        Text("Email: ${widget.email}"),
                        Text("Phone: $phone"),
                        Text("Location: $location"),
                        Text("Joining Date: ${_joiningDateController.text}"),
                        Text("Manager: $manager"),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(
                        context,
                        '/dashboard',
                        arguments: widget.uid,
                      );
                    },
                    child: const Text('Continue'),
                  ),
                ],
              ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error saving details."),
            backgroundColor: Colors.red,
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: FadeTransition(
        opacity: _animation,
        child: TextFormField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: primaryPurple),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: lightLavender,
          ),
          keyboardType: keyboardType,
          validator: validator,
          onSaved: onSaved,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryPurple, lightLavender],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: const [
          Icon(Icons.person_add_alt_1, size: 60, color: Colors.white),
          SizedBox(height: 10),
          Text(
            "Register Your Details",
            style: TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  blurRadius: 6,
                  color: Colors.black26,
                  offset: Offset(1, 2),
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
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Form(
                  key: _formKey,
                  child: FadeTransition(
                    opacity: _animation,
                    child: Column(
                      children: [
                        _buildTextField(
                          label: "Full Name",
                          icon: Icons.person,
                          validator:
                              (val) => val!.isEmpty ? "Enter name" : null,
                          onSaved: (val) => name = val?.trim(),
                        ),
                        _buildTextField(
                          label: "Designation",
                          icon: Icons.badge_outlined,
                          validator:
                              (val) =>
                                  val!.isEmpty ? "Enter designation" : null,
                          onSaved: (val) => designation = val?.trim(),
                        ),
                        _buildTextField(
                          label: "Department",
                          icon: Icons.apartment,
                          validator:
                              (val) => val!.isEmpty ? "Enter department" : null,
                          onSaved: (val) => department = val?.trim(),
                        ),
                        _buildTextField(
                          label: "Email",
                          icon: Icons.email_outlined,
                          controller: _emailController,
                          readOnly: true,
                          validator: (val) => null,
                          onSaved: (_) {},
                        ),
                        _buildTextField(
                          label: "Phone No",
                          icon: Icons.phone,
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
                          label: "Location / Address",
                          icon: Icons.location_on_outlined,
                          validator:
                              (val) => val!.isEmpty ? "Enter location" : null,
                          onSaved: (val) => location = val?.trim(),
                        ),
                        _buildTextField(
                          label: "Joining Date",
                          icon: Icons.date_range,
                          controller: _joiningDateController,
                          readOnly: true,
                          validator:
                              (val) => val!.isEmpty ? "Pick a date" : null,
                          onSaved: (_) {},
                          onTap: _selectJoiningDate,
                        ),
                        _buildTextField(
                          label: "Manager Name",
                          icon: Icons.supervisor_account,
                          validator:
                              (val) =>
                                  val!.isEmpty ? "Enter manager's name" : null,
                          onSaved: (val) => manager = val?.trim(),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            "Submit",
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 6,
                          ),
                          onPressed: _submitForm,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
