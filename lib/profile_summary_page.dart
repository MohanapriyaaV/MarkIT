import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSummaryPage extends StatefulWidget {
  const ProfileSummaryPage({super.key});

  @override
  State<ProfileSummaryPage> createState() => _ProfileSummaryPageState();
}

class _ProfileSummaryPageState extends State<ProfileSummaryPage> {
  Map<String, dynamic>? employeeData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEmployeeData();
  }

  Future<void> fetchEmployeeData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        throw Exception("User not logged in.");
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('employeeInfo')
              .doc(uid)
              .get();

      if (doc.exists) {
        setState(() {
          employeeData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          employeeData = {};
          isLoading = false;
        });
      }
    } catch (e) {
      print("🔥 Error fetching employee data: $e");
      setState(() {
        employeeData = {};
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xffF6F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (employeeData == null || employeeData!.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xffF6F7FB),
        body: Center(
          child: Text(
            "No employee data found or failed to load.",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final String employeeName = employeeData!['name'] ?? 'N/A';
    final String designation = employeeData!['role'] ?? 'N/A';
    final String department = employeeData!['department'] ?? 'N/A';
    final String joiningDate = employeeData!['JoiningDate'] ?? 'N/A';
    final String employeeId = "VistaES01";
    final String email = employeeData!['email'] ?? 'N/A';
    final String phoneNumber = employeeData!['phoneNumber'] ?? 'N/A';
    final String location = employeeData!['location'] ?? 'N/A';
    final String? currentManager = employeeData!['Manager'];

    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        title: const Text("Employee Profile"),
        backgroundColor: const Color(0xffEBD8FF),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Hero(
                      tag: 'profile-pic',
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: const AssetImage(
                          'assets/images/image.png',
                        ),
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      employeeName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff333333),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      designation,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      department,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(thickness: 1),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.badge, "Employee ID:", employeeId),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.email, "Email:", email),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.phone, "Phone:", phoneNumber),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.location_on, "Location:", location),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    Icons.calendar_today,
                    "Joining Date:",
                    joiningDate,
                  ),
                  const SizedBox(height: 10),
                  if (currentManager != null)
                    _buildInfoRow(
                      Icons.person_outline,
                      "Manager:",
                      currentManager,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }
}
