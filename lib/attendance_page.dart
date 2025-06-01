import 'dart:ui'; // for BackdropFilter
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  final String empId;
  const AttendancePage({super.key, required this.empId});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with TickerProviderStateMixin {
  bool _attendanceMarked = false;
  bool _isSunday = false;
  bool _isEligibleTime = false;

  String _statusMessage = "";
  String? _employeeName;
  String? _remark;

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
      curve: Curves.elasticOut
    );
    
    _pulseController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500)
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);

    fetchEmployeeName();
    _checkEligibility();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> fetchEmployeeName() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('employeeInfo')
          .doc(widget.empId)
          .get();
      setState(() => _employeeName = snap.data()?['name'] ?? 'Employee');
    } catch (_) {
      setState(() => _employeeName = 'Employee');
    }
  }

  void _checkEligibility() {
    final now = DateTime.now();
    _isSunday = now.weekday == DateTime.sunday;

    _isEligibleTime = (now.hour >= 12) ||
        (now.hour > 7) ||
        (now.hour == 7 && now.minute >= 0);
    setState(() {});
  }

  Future<void> markAttendance() async {
    final firestore = FirebaseFirestore.instance;
    final uid = widget.empId.trim();
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final month = DateFormat('yyyy-MM').format(now);

    if (now.hour < 8 || (now.hour == 8 && now.minute < 30)) {
      await _askForRemark();
    }

    String session;
    if (now.hour < 9 || (now.hour == 9 && now.minute <= 5)) {
      session = "FN";
    } else {
      if (now.hour < 13 || (now.hour == 13 && now.minute < 5)) {
        _statusMessage =
            "⏰ Too late for FN – marked absent for FN, marking AN.";
      }
      session = "AN";
    }

    final docRef = firestore.collection('attendance').doc(uid);
    final rec = {
      'timestamp': now,
      'remark': _remark ?? '',
      session: true,
    };

    final doc = await docRef.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final records = Map<String, dynamic>.from(data['records'] ?? {});
      final day = Map<String, dynamic>.from(records[today] ?? {});
      day.addAll(rec);
      records[today] = day;
      await docRef.update({'records': records});
    } else {
      await docRef.set({
        'empId': uid,
        'records': {today: rec},
      });
    }

    final q = await firestore
        .collection('monthly_attendance_summaries')
        .where('empId', isEqualTo: uid)
        .where('month', isEqualTo: month)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) {
      await q.docs.first.reference.update({'count': FieldValue.increment(1)});
    } else {
      await firestore.collection('monthly_attendance_summaries').add({
        'empId': uid,
        'month': month,
        'count': 1,
      });
    }

    setState(() {
      _attendanceMarked = true;
      _statusMessage = "✅ Marked present for $session session!";
    });

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/dashboard', arguments: uid);
    });
  }

  Future<void> _askForRemark() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
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
                "You're early!",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Please provide reason for early login...",
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _remark = controller.text;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Submit",
                style: TextStyle(
                  fontSize: 16,
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
                        border: Border.all(color: Colors.white.withOpacity(0.5)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        border: Border.all(color: Colors.white.withOpacity(0.4)),
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

  Widget _buildStatItem(IconData icon, String title, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: Colors.black87, size: 24),
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

  Widget _buildActionContent() {
    if (_isSunday) {
      return Column(
        key: const ValueKey('sunday'),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.weekend_rounded,
              size: 48,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "🎉 It's Sunday!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enjoy your day off and recharge for the week ahead!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      );
    }

    if (!_isEligibleTime) {
      return Column(
        key: const ValueKey('not-eligible'),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 48,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "⏰ Not Yet Time",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Attendance portal opens at:\n• 07:00 for Morning Session\n• 12:00 for Afternoon Session",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
        ],
      );
    }

    if (_attendanceMarked) {
      return Column(
        key: const ValueKey('marked'),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 56,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "✅ All Set!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('button'),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [primaryColor.withOpacity(0.1), accentColor.withOpacity(0.1)],
            ),
          ),
          child: Icon(
            Icons.fingerprint_rounded,
            size: 48,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Ready to Mark Attendance?",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Tap the button below to record your presence",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 28),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: [primaryColor, accentColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: markAttendance,
                  icon: const Icon(
                    Icons.touch_app_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: const Text(
                    "Mark My Attendance",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}