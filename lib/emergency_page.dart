import 'package:flutter/material.dart';
import 'dashboard.dart'; // Your dashboard file
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmergencyLeavePage extends StatefulWidget {
  const EmergencyLeavePage({super.key});

  @override
  _EmergencyLeavePageState createState() => _EmergencyLeavePageState();
}

class _EmergencyLeavePageState extends State<EmergencyLeavePage>
    with SingleTickerProviderStateMixin {
  int availableLeaves = 2;
  String? selectedReason;

  final List<String> reasons = [
    'Medical Emergency',
    'Family Emergency',
    'Personal Emergency',
    'Other',
  ];

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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

      // Store data using user UID as the document ID
      await FirebaseFirestore.instance
          .collection('emergencyLeave')
          .doc(user.uid)
          .set({
        'reason': selectedReason,
        'dayType': 'Full Day',
        'userID': user.uid,
        'appliedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        availableLeaves -= 1;
      });

      _controller.forward();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return ScaleTransition(
            scale: _animation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 10),
                  Text('Leave Applied'),
                ],
              ),
              content: Text(
                'Your emergency leave has been successfully applied.\n'
                'You can take leave for today.\n\n'
                'Remaining leaves: $availableLeaves',
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const DashboardPage()),
                      (route) => false,
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying leave: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Emergency Leave'),
        backgroundColor: const Color(0xffEBD8FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 50,
            ),
            const SizedBox(height: 10),
            Text(
              'Available Emergency Leaves: $availableLeaves',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const Text(
              'Select Reason for Emergency Leave',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedReason,
              hint: const Text('Choose a reason'),
              items: reasons
                  .map(
                    (reason) => DropdownMenuItem(
                      value: reason,
                      child: Text(reason),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedReason = val;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton.icon(
                onPressed: applyLeave,
                icon: const Icon(Icons.send_rounded),
                label: const Text(
                  'Apply Emergency Leave',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffEBD8FF),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
