// attendance_page.dart
import 'dart:ui'; // for BackdropFilter
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../services/face_data_service.dart';
import '../frontend/face_auth_screen.dart';

class AttendancePage extends StatefulWidget {
  final String empId;
  const AttendancePage({super.key, required this.empId});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with TickerProviderStateMixin {
  final AttendanceService _attendanceService = AttendanceService();
  final FaceDataService _faceDataService = FaceDataService();

  bool _attendanceMarked = false;
  bool _isSunday = false;
  bool _isEligibleTime = false;
  bool _isLoading = false;

  String _statusMessage = "";
  String? _employeeName;
  String? _remark;
  String? _currentSession;
  bool _isEarly = false;
  bool _isLateFN = false;
  bool _isTooLate = false;
  Duration? _timeRemaining;

  late final AnimationController _animationController;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseAnimation;

  final Color primaryColor = const Color(0xFF6C63FF);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Duration animDur = const Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this, duration: animDur);
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);

    _fetchEmployeeName();
    _checkEligibility();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployeeName() async {
    try {
      final employee = await _attendanceService.fetchEmployeeData(widget.empId);
      setState(() => _employeeName = employee?.name ?? 'Employee');
    } catch (e) {
      setState(() => _employeeName = 'Employee');
    }
  }

  void _checkEligibility() {
    final eligibility = _attendanceService.checkEligibility();
    setState(() {
      _isSunday = eligibility.isSunday;
      _isEligibleTime = true; // Always enable for testing
      _currentSession = eligibility.session;
      _isEarly = eligibility.isEarly;
      _isLateFN = eligibility.isLateFN;
      _isTooLate = eligibility.isTooLate;
      _timeRemaining = eligibility.timeRemaining;
      if (!eligibility.isEligibleTime && eligibility.lateMessage != null) {
        _statusMessage = eligibility.lateMessage!;
      }
    });
  }

  Future<void> _markAttendance() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final eligibility = _attendanceService.checkEligibility();
      if (eligibility.isEarly) {
        await _askForRemark();
      }
      // Check if face data exists for this user
      final hasFace = await _faceDataService.hasFaceData(widget.empId);
      final faceAuthResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceAuthScreen(
            isRegistration: !hasFace, // true if first time, false otherwise
            userId: widget.empId,
          ),
        ),
      );
      if (faceAuthResult != true) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Face authentication failed or cancelled.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face authentication failed or cancelled.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final statusMessage = await _attendanceService.markAttendance(
        widget.empId,
        _remark,
      );
      setState(() {
        _attendanceMarked = true;
        _statusMessage = statusMessage;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(statusMessage),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/dashboard',
            arguments: widget.empId,
          );
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark attendance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _askForRemark() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.access_time, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                "Early Attendance",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "You're marking attendance early. Please provide a reason:",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Reason for early attendance...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _remark = "";
              Navigator.pop(context);
            },
            child: const Text("Skip"),
          ),
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: () {
                _remark = controller.text.trim();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Submit",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Attendance Portal",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                  Color(0xFF6B73FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Welcome Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.white.withOpacity(0.9),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                        ),
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
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor.withOpacity(0.1),
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              size: 32,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Welcome back,",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _employeeName ?? 'Loading...',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              DateFormat.yMMMMEEEEd().format(DateTime.now()),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Session Info Card
                    if (_currentSession != null && _isEligibleTime)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: accentColor.withOpacity(0.1),
                          border: Border.all(
                            color: accentColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _currentSession == 'FN'
                                  ? Icons.wb_sunny
                                  : Icons.wb_twilight,
                              color: accentColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Current Session: ${_currentSession == 'FN' ? 'Forenoon' : 'Afternoon'}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Main Action Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: animDur,
                        child: _buildActionContent(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Quick Stats Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.white.withOpacity(0.8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              Icons.today_rounded,
                              "Today",
                              DateFormat.d().format(DateTime.now()),
                              primaryColor,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.black.withOpacity(0.1),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              Icons.calendar_month_rounded,
                              "Month",
                              DateFormat.MMM().format(DateTime.now()),
                              accentColor,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.black.withOpacity(0.1),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              Icons.schedule_rounded,
                              "Time",
                              DateFormat.Hm().format(DateTime.now()),
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionContent() {
    if (_isSunday) {
      return Column(
        children: [
          Icon(Icons.weekend_rounded, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            "It's Sunday!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Enjoy your weekend. No attendance needed today.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      );
    } else if (_attendanceMarked) {
      return Column(
        children: [
          const Icon(Icons.check_circle_rounded, size: 48, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            "Success!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      );
    } else if (_isEligibleTime) {
      return Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: ElevatedButton.icon(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.fingerprint_rounded),
              label: Text(
                _isLoading ? "Marking..." : "Mark Attendance",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _isLoading ? null : _markAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                shadowColor: primaryColor.withOpacity(0.4),
              ),
            ),
          ),
          if (_isEarly) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "You're early! You'll be asked for a reason.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    } else {
      return Column(
        children: [
          Icon(
            _isLateFN || _isTooLate
                ? Icons.schedule_rounded
                : Icons.schedule_rounded,
            size: 48,
            color: _isLateFN ? Colors.orange : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _isLateFN ? "Session Missed" : "Outside Window",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _isLateFN ? Colors.orange : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage.isNotEmpty
                ? _statusMessage
                : "You are not within the attendance window. Please try later.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Attendance Hours:\nFN: 7:00 AM - 9:05 AM\nAN: 12:00 PM - 1:05 PM",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
          ),
        ],
      );
    }
  }

  Widget _buildStatItem(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
