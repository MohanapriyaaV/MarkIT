import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ApplyLeavePage extends StatefulWidget {
  const ApplyLeavePage({Key? key}) : super(key: key);

  @override
  State<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<ApplyLeavePage> {
  DateTime? selectedStartDateTime;
  DateTime? selectedEndDateTime;
  String? selectedReason;
  final TextEditingController explanationController = TextEditingController();

  final List<String> leaveReasons = ['Sick Leave', 'Casual Leave', 'Personal Leave'];

  // Find first valid date in the range excluding Sundays
  DateTime getFirstValidDate(DateTime start, DateTime end) {
    DateTime date = start;
    while (date.isBefore(end) || date.isAtSameMomentAs(end)) {
      if (date.weekday != DateTime.sunday) {
        return date;
      }
      date = date.add(const Duration(days: 1));
    }
    // fallback if all days are Sundays (very unlikely)
    return end;
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final firstDate = now.add(const Duration(days: 1));  // from tomorrow
    final lastDate = now.add(const Duration(days: 5));   // next 5 days

    final initialDate = getFirstValidDate(firstDate, lastDate);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (date) {
        // Exclude Sundays, dates before firstDate, and after lastDate
        if (date.isBefore(firstDate) || date.isAfter(lastDate)) return false;
        if (date.weekday == DateTime.sunday) return false;
        return true;
      },
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (pickedTime == null) return;

    final combinedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        selectedStartDateTime = combinedDateTime;
      } else {
        selectedEndDateTime = combinedDateTime;
      }
    });
  }

  Future<void> _submitLeaveApplication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (selectedStartDateTime == null ||
        selectedEndDateTime == null ||
        selectedReason == null ||
        explanationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (selectedStartDateTime!.difference(DateTime.now()).inHours < 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave must be applied at least 24 hours in advance.')),
      );
      return;
    }

    final leaveData = {
      'startDateTime': selectedStartDateTime,
      'endDateTime': selectedEndDateTime,
      'reason': selectedReason,
      'explanation': explanationController.text,
      'status': 'Pending',
      'appliedAt': Timestamp.now(),
      'userID': user.uid,
    };

    try {
      await FirebaseFirestore.instance
          .collection('leaveapplication')
          .doc(user.uid)
          .collection('userLeaves')
          .add(leaveData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave application submitted.')),
      );

      setState(() {
        selectedStartDateTime = null;
        selectedEndDateTime = null;
        selectedReason = null;
        explanationController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting leave: $e')),
      );
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Select Date & Time';
    return DateFormat('EEE, MMM d yyyy – hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply Leave')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Start Date
              ListTile(
                title: const Text('Start'),
                subtitle: Text(_formatDateTime(selectedStartDateTime)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDateTime(isStart: true),
              ),
              const SizedBox(height: 16),

              // End Date
              ListTile(
                title: const Text('End'),
                subtitle: Text(_formatDateTime(selectedEndDateTime)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDateTime(isStart: false),
              ),
              const SizedBox(height: 16),

              // Reason dropdown
              DropdownButtonFormField<String>(
                value: selectedReason,
                items: leaveReasons.map((reason) {
                  return DropdownMenuItem(value: reason, child: Text(reason));
                }).toList(),
                onChanged: (value) => setState(() => selectedReason = value),
                decoration: const InputDecoration(labelText: 'Select Reason'),
              ),
              const SizedBox(height: 16),

              // Explanation
              TextFormField(
                controller: explanationController,
                decoration: const InputDecoration(labelText: 'Explanation'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _submitLeaveApplication,
                child: const Text('Submit Leave'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
