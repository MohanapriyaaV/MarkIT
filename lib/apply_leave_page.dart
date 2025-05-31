import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApplyLeavePage extends StatefulWidget {
  const ApplyLeavePage({super.key});

  @override
  State<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<ApplyLeavePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _explanationController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedReason;
  bool _isSubmitting = false;

  final List<String> _reasons = ['Sick Leave', 'Family Emergency', 'Personal Work', 'Other'];
  int availableNoLopLeaves = 1;

  Future<void> _pickDateTime(BuildContext context, bool isStart) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final DateTime fullDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        setState(() {
          if (isStart) {
            _startDate = fullDateTime;
          } else {
            _endDate = fullDateTime;
          }
        });
      }
    }
  }

  String _formatDateTime(DateTime? dt) {
    return dt != null ? DateFormat('yyyy-MM-dd hh:mm a').format(dt) : 'Select Date & Time';
  }

  void _submitForm() async {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        _showError("Please select both start and end date/time.");
        return;
      }

      if (_startDate!.isBefore(DateTime.now())) {
        _showError("Start date/time cannot be in the past.");
        return;
      }

      if (_startDate!.isAfter(_endDate!)) {
        _showError("Start date/time cannot be after end date/time.");
        return;
      }

      if (_startDate!.isAtSameMomentAs(_endDate!)) {
        _showError("Leave duration cannot be zero.");
        return;
      }

      if (availableNoLopLeaves <= 0) {
        _showError("You do not have any No Loss of Pay leaves left.");
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("User not logged in");

        // ✅ Save to Firestore using UID as document ID
        await FirebaseFirestore.instance
            .collection("leaveapplication")
            .doc(user.uid) // <- document ID = UID
            .set({
          "userID": user.uid,
          "reason": _selectedReason,
          "explanation": _explanationController.text.trim(),
          "startDateTime": _startDate,
          "endDateTime": _endDate,
          "appliedAt": DateTime.now(),
          "status": "Pending",
        });

        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Leave Application Submitted")),
          );
          _formKey.currentState!.reset();
          _explanationController.clear();
          setState(() {
            _startDate = null;
            _endDate = null;
            _selectedReason = null;
          });
        }
      } catch (e) {
        setState(() => _isSubmitting = false);
        _showError("Error submitting: ${e.toString()}");
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        title: const Text("Apply Leave", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  "No Loss of Pay Leave Available: 1",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 25),

                DropdownButtonFormField<String>(
                  value: _selectedReason,
                  decoration: const InputDecoration(
                    labelText: "Leave Reason",
                    border: OutlineInputBorder(),
                  ),
                  items: _reasons
                      .map((reason) => DropdownMenuItem(value: reason, child: Text(reason)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                    });
                  },
                  validator: (value) =>
                      value == null || value.isEmpty ? "Please select a reason" : null,
                ),
                const SizedBox(height: 20),

                AnimatedOpacity(
                  opacity: _selectedReason != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: TextFormField(
                    controller: _explanationController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Brief Explanation",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_selectedReason == "Other" &&
                          (value == null || value.trim().isEmpty)) {
                        return "Explanation required for 'Other'";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                _buildDateButton("Start: ${_formatDateTime(_startDate)}", true, Colors.greenAccent),
                const SizedBox(height: 15),
                _buildDateButton("End: ${_formatDateTime(_endDate)}", false, Colors.orangeAccent),
                const SizedBox(height: 30),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          key: const ValueKey("submit_btn"),
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffD7BBF5),
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Submit"),
                        ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, bool isStart, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _pickDateTime(context, isStart),
        icon: const Icon(Icons.calendar_today),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffEBD8FF),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
      ),
    );
  }
}
