import 'package:flutter/material.dart';
import '../services/profile_summary_service.dart';
import '../models/profile_summary_model.dart';

class ProfileSummaryPage extends StatefulWidget {
  const ProfileSummaryPage({super.key});

  @override
  State<ProfileSummaryPage> createState() => _ProfileSummaryPageState();
}

class _ProfileSummaryPageState extends State<ProfileSummaryPage>
    with TickerProviderStateMixin {
  Employee? employee;
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _profileController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _profileAnimation;

  final EmployeeService _employeeService = EmployeeService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _profileController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _profileAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _profileController, curve: Curves.elasticOut),
    );

    fetchEmployeeData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  Future<void> fetchEmployeeData() async {
    try {
      final employeeData = await _employeeService.fetchEmployeeData();
      
      setState(() {
        employee = employeeData;
        isLoading = false;
      });
      
      if (employeeData != null) {
        // Staggered animations
        _fadeController.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _slideController.forward();
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _profileController.forward();
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6B73FF),
                Color(0xFF9575CD),
                Color(0xFF4DD0E1),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6B73FF),
                    ),
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Loading Your Profile...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Please wait a moment",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (employee == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6B73FF),
                Color(0xFF9575CD),
                Color(0xFF4DD0E1),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_off_outlined,
                    size: 72,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "No Profile Data Found",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Please contact your administrator",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final String employeeName = employee!.name ?? 'N/A';
    final String designation = employee!.role ?? 'N/A';
    final String domain = employee!.domain ?? 'N/A';
    final String joiningDate = employee!.joiningDate ?? 'N/A';
    final String employeeId = employee!.empId;
    final String email = employee!.email;
    final String phoneNumber = employee!.phoneNumber ?? 'N/A';
    final String location = employee!.location ?? 'N/A';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B73FF),
              Color(0xFF9575CD),
              Color(0xFF4DD0E1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced App Bar
              _buildEnhancedAppBar(context),

              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Enhanced Profile Header
                          ScaleTransition(
                            scale: _profileAnimation,
                            child: _buildEnhancedProfileHeader(
                              employeeName,
                              designation,
                              domain,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Contact Information
                          _buildEnhancedContactSection(email, phoneNumber),

                          const SizedBox(height: 16),

                          // Work Information
                          _buildEnhancedWorkSection(
                            employeeId,
                            location,
                            joiningDate,
                          ),

                          const SizedBox(height: 24),
                        ],
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

  Widget _buildEnhancedAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Employee Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Add edit functionality here
                },
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProfileHeader(
    String name,
    String designation,
    String domain,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image with Circular Background
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6B73FF).withOpacity(0.1),
              border: Border.all(
                color: const Color(0xFF6B73FF).withOpacity(0.2),
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: const Icon(
              Icons.person,
              size: 60,
              color: Color(0xFF6B73FF),
            ),
          ),

          const SizedBox(height: 24),

          // Welcome Text
          const Text(
            "Welcome back,",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          // Employee Name
          Text(
            name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getCurrentDate(),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Designation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6B73FF).withOpacity(0.1),
                  const Color(0xFF9575CD).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6B73FF).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              designation,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B73FF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Domain - Fixed to properly display domain instead of department
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.business_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  domain, // Now properly displays domain from Firestore
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedContactSection(String email, String phoneNumber) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6B73FF).withOpacity(0.1),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.contact_phone_outlined,
                  color: Color(0xFF6B73FF),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Contact Information",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEnhancedInfoRow(
            Icons.email_outlined,
            "Email Address",
            email,
            const Color(0xFF6B73FF),
          ),
          const SizedBox(height: 16),
          _buildEnhancedInfoRow(
            Icons.phone_outlined,
            "Phone Number",
            phoneNumber,
            const Color(0xFF9575CD),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedWorkSection(
    String employeeId,
    String location,
    String joiningDate,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4DD0E1).withOpacity(0.1),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.work_outline,
                  color: Color(0xFF4DD0E1),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Work Information",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEnhancedInfoRow(
            Icons.badge_outlined,
            "Employee ID",
            employeeId,
            const Color(0xFF4DD0E1),
          ),
          const SizedBox(height: 16),
          _buildEnhancedInfoRow(
            Icons.location_on_outlined,
            "Location",
            location,
            const Color(0xFF6B73FF),
          ),
          const SizedBox(height: 16),
          _buildEnhancedInfoRow(
            Icons.calendar_today_outlined,
            "Joining Date",
            joiningDate,
            const Color(0xFF9575CD),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    
    return '$weekday, $month ${now.day}, ${now.year}';
  }
}