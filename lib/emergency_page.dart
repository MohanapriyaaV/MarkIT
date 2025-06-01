import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'dashboard.dart';

class EmergencyLeavePage extends StatefulWidget {
  const EmergencyLeavePage({super.key});

  @override
  _EmergencyLeavePageState createState() => _EmergencyLeavePageState();
}

class _EmergencyLeavePageState extends State<EmergencyLeavePage>
    with TickerProviderStateMixin {
  int availableLeaves = 2;
  String? selectedReason;

  final List<String> reasons = [
    'Medical Emergency',
    'Family Emergency',
    'Personal Emergency',
    'Other',
  ];

  late AnimationController _iconBounceController;
  late Animation<double> _iconBounceAnimation;

  late AnimationController _buttonGlowController;
  late Animation<double> _buttonGlowAnimation;

  late AnimationController _successIconController;
  late Animation<double> _successIconScale;
  late Animation<double> _successIconOpacity;

  @override
  void initState() {
    super.initState();

    _iconBounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _iconBounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _iconBounceController, curve: Curves.easeInOut),
    );

    _buttonGlowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _buttonGlowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _buttonGlowController, curve: Curves.easeInOut),
    );

    _successIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _successIconScale = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(
        parent: _successIconController,
        curve: Curves.easeOutBack,
      ),
    );

    _successIconOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _successIconController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _iconBounceController.dispose();
    _buttonGlowController.dispose();
    _successIconController.dispose();
    super.dispose();
  }

  Future<void> applyLeave() async {
    if (selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason for leave')),
      );
      return;
    }

    if (availableLeaves <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No emergency leaves available')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final hour = now.hour;
      final formattedTime = DateFormat('hh:mm a').format(now);
      final isHalfDay = hour >= 13;
      final leaveType = isHalfDay ? 'Half Day' : 'Full Day';

      await FirebaseFirestore.instance
          .collection('emergencyLeave')
          .doc(user.uid)
          .set({
            'reason': selectedReason,
            'leaveType': leaveType,
            'userID': user.uid,
            'appliedAt': FieldValue.serverTimestamp(),
            'appliedTime': formattedTime,
            'remainingLeaves': availableLeaves - 1,
          });

      setState(() {
        availableLeaves -= 1;
      });

      await _successIconController.forward();

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              backgroundColor: Colors.white.withOpacity(0.95),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _successIconController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _successIconOpacity.value,
                        child: Transform.scale(
                          scale: _successIconScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.check_circle,
                      color: Color.fromARGB(255, 170, 61, 156),
                      size: 70,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Leave Applied',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your emergency leave has been successfully applied as a $leaveType leave.\n'
                    'Applied time: $formattedTime\n\n'
                    'Remaining leaves: $availableLeaves',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const DashboardPage(),
                        ),
                        (route) => false,
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 10,
                      ),
                      backgroundColor: const Color.fromARGB(255, 184, 56, 173),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('OK', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
      );

      _successIconController.reset();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying leave: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Apply Emergency Leave'),
        backgroundColor: Colors.deepPurple[400],
        elevation: 4,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _iconBounceAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _iconBounceAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepPurple[50],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.deepPurple,
                        size: 72,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Available Emergency Leaves',
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: Colors.deepPurple[700],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$availableLeaves',
                    style: theme.textTheme.headlineLarge!.copyWith(
                      color: Colors.deepPurple[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Reason for Emergency Leave',
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: Colors.deepPurple[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.deepPurple[50],
                      border: Border.all(color: Colors.deepPurple.shade200),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: DropdownButtonFormField<String>(
                      value: selectedReason,
                      hint: Text(
                        'Choose a reason',
                        style: TextStyle(color: Colors.deepPurple.shade300),
                      ),
                      dropdownColor: Colors.white,
                      items: reasons
                          .map(
                            (reason) => DropdownMenuItem(
                              value: reason,
                              child: Text(
                                reason,
                                style: TextStyle(color: Colors.deepPurple[900]),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedReason = val;
                        });
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: Colors.deepPurple[900],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  AnimatedBuilder(
                    animation: _buttonGlowAnimation,
                    builder: (context, child) {
                      return ElevatedButton.icon(
                        onPressed: applyLeave,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text(
                          'Apply Emergency Leave',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          backgroundColor: Colors.deepPurple
                              .withOpacity(_buttonGlowAnimation.value),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 12,
                          shadowColor: Colors.deepPurpleAccent.withOpacity(0.6),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
