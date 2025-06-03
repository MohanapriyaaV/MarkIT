import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/leave_service.dart';
import '../models/leave_application.dart';

class ApplyLeavePage extends StatefulWidget {
  const ApplyLeavePage({Key? key}) : super(key: key);

  @override
  State<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<ApplyLeavePage> {
  int numberOfDays = 1;
  bool isFullDay = true;
  String halfDayType = 'FN';
  bool isStartFullDay = true;
  bool isEndFullDay = true;
  String startHalfDayType = 'FN';
  String endHalfDayType = 'AF';
  DateTime? startDate;
  DateTime? endDate;
  String? selectedReason;
  final TextEditingController explanationController = TextEditingController();

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF6B46C1), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _updateHalfDayDefaults();
  }

  void _updateHalfDayDefaults() {
    setState(() {
      final startOptions = LeaveService.getStartHalfDayOptions(numberOfDays);
      if (!startOptions.contains(startHalfDayType)) {
        startHalfDayType = LeaveService.getDefaultStartHalfDayOption(numberOfDays);
      }
      final endOptions = LeaveService.getEndHalfDayOptions(numberOfDays);
      if (!endOptions.contains(endHalfDayType)) {
        endHalfDayType = LeaveService.getDefaultEndHalfDayOption(numberOfDays);
      }
      if (numberOfDays == 1) halfDayType = startHalfDayType;
    });
  }

  Future<void> _pickStartDate() async {
    final result = await LeaveService.pickStartDate(
      context: context,
      currentStartDate: startDate,
      numberOfDays: numberOfDays,
    );
    if (result != null && mounted) {
      setState(() {
        startDate = result['startDate'];
        endDate = result['endDate'];
      });
    }
  }

  Future<void> _pickEndDate() async {
    final result = await LeaveService.pickEndDate(
      context: context,
      startDate: startDate,
    );
    if (result != null && mounted) {
      setState(() {
        endDate = result['endDate'];
        numberOfDays = result['numberOfDays'];
        _updateHalfDayDefaults();
      });
    }
  }

  void _updateNumberOfDays(int newDays) {
    setState(() {
      numberOfDays = newDays;
      if (startDate != null) {
        endDate = LeaveService.calculateEndDate(startDate!, numberOfDays);
      }
      _updateHalfDayDefaults();
    });
  }

  Future<void> _submitLeaveApplication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('User not authenticated');
      return;
    }

    final startDateTime = LeaveService.getStartDateTime(
      startDate: startDate!,
      numberOfDays: numberOfDays,
      isFullDay: isFullDay,
      halfDayType: halfDayType,
      isStartFullDay: isStartFullDay,
      startHalfDayType: startHalfDayType,
    );

    final isValid = LeaveService.validateForm(
      startDate: startDate,
      endDate: endDate,
      selectedReason: selectedReason,
      explanation: explanationController.text,
      numberOfDays: numberOfDays,
      startDateTime: startDateTime,
      isStartFullDay: isStartFullDay,
      isEndFullDay: isEndFullDay,
      startHalfDayType: startHalfDayType,
      endHalfDayType: endHalfDayType,
    );

    if (!isValid) {
      final errorMessage = LeaveService.getValidationError(
        startDate: startDate,
        endDate: endDate,
        selectedReason: selectedReason,
        explanation: explanationController.text,
        numberOfDays: numberOfDays,
        startDateTime: startDateTime,
        isStartFullDay: isStartFullDay,
        isEndFullDay: isEndFullDay,
        startHalfDayType: startHalfDayType,
        endHalfDayType: endHalfDayType,
      );
      _showSnackBar(errorMessage);
      return;
    }

    final leaveApplication = LeaveApplication(
      startDateTime: startDateTime,
      endDateTime: LeaveService.getEndDateTime(
        endDate: endDate!,
        numberOfDays: numberOfDays,
        isFullDay: isFullDay,
        halfDayType: halfDayType,
        isEndFullDay: isEndFullDay,
        endHalfDayType: endHalfDayType,
      ),
      numberOfDays: numberOfDays,
      leaveDuration: LeaveService.calculateLeaveDuration(
        numberOfDays: numberOfDays,
        isFullDay: isFullDay,
        isStartFullDay: isStartFullDay,
        isEndFullDay: isEndFullDay,
      ),
      isFullDay: numberOfDays == 1 ? isFullDay : null,
      halfDayType: numberOfDays == 1 && !isFullDay ? halfDayType : null,
      isStartFullDay: numberOfDays > 1 ? isStartFullDay : null,
      isEndFullDay: numberOfDays > 1 ? isEndFullDay : null,
      startHalfDayType: numberOfDays > 1 && !isStartFullDay ? startHalfDayType : null,
      endHalfDayType: numberOfDays > 1 && !isEndFullDay ? endHalfDayType : null,
      reason: selectedReason!,
      explanation: explanationController.text.trim(),
      status: 'Pending',
      appliedAt: DateTime.now(),
      userID: user.uid,
    );

    try {
      _showLoadingDialog();
      await LeaveService.submitLeaveApplication(leaveApplication);
      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar('Error submitting leave. Please try again.');
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: backgroundGradient.scale(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Submitting your leave...', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    String leaveDetails = LeaveService.getLeaveDetailsText(
      startDate: startDate,
      endDate: endDate,
      numberOfDays: numberOfDays,
      isFullDay: isFullDay,
      halfDayType: halfDayType,
      isStartFullDay: isStartFullDay,
      isEndFullDay: isEndFullDay,
      startHalfDayType: startHalfDayType,
      endHalfDayType: endHalfDayType,
      leaveDuration: LeaveService.calculateLeaveDuration(
        numberOfDays: numberOfDays,
        isFullDay: isFullDay,
        isStartFullDay: isStartFullDay,
        isEndFullDay: isEndFullDay,
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: backgroundGradient.scale(0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Leave Applied Successfully!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  leaveDetails, 
                  style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500), 
                  textAlign: TextAlign.center
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '✨ HR will reply within 16 hours',
                  style: TextStyle(fontSize: 13, color: Colors.white, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6B46C1),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 8,
                ),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Container(
        decoration: BoxDecoration(
          gradient: backgroundGradient.scale(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          message, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
        ),
      ),
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
    ),
  );
}
  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: backgroundGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 16),
        Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildRadioOption(String title, String subtitle, bool value, bool groupValue, ValueChanged<bool?> onChanged) {
    final isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B46C1).withOpacity(0.1) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF6B46C1) : Colors.grey.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFF6B46C1),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Apply Leave',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              
              // Main Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Number of Days
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Number of Days', Icons.calendar_month),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: backgroundGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: numberOfDays > 1 ? () => _updateNumberOfDays(numberOfDays - 1) : null,
                                      icon: Icon(Icons.remove, color: numberOfDays > 1 ? Colors.white : Colors.white54),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Text(numberOfDays.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                    IconButton(
                                      onPressed: numberOfDays < 30 ? () => _updateNumberOfDays(numberOfDays + 1) : null,
                                      icon: Icon(Icons.add, color: numberOfDays < 30 ? Colors.white : Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              if (startDate != null && endDate != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: backgroundGradient, 
                                    borderRadius: BorderRadius.circular(25)
                                  ),
                                  child: Text(
                                    '${LeaveService.calculateLeaveDuration(numberOfDays: numberOfDays, isFullDay: isFullDay, isStartFullDay: isStartFullDay, isEndFullDay: isEndFullDay)} days',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Day Type for single day
                    if (numberOfDays == 1)
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Day Type', Icons.schedule),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _buildRadioOption('Full Day', '9:00 AM - 6:00 PM', true, isFullDay, (v) => setState(() => isFullDay = v!))),
                                const SizedBox(width: 16),
                                Expanded(child: _buildRadioOption('Half Day', 'FN or AF', false, isFullDay, (v) => setState(() => isFullDay = v!))),
                              ],
                            ),
                            if (!isFullDay) ...[
                              const SizedBox(height: 20),
                              ...LeaveService.getStartHalfDayOptions(numberOfDays).map(
                                (option) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      halfDayType = option;
                                      startHalfDayType = option;
                                      endHalfDayType = option;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: halfDayType == option ? const Color(0xFF6B46C1).withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: halfDayType == option ? const Color(0xFF6B46C1) : Colors.grey.withOpacity(0.3), width: 2),
                                      ),
                                      child: Row(
                                        children: [
                                          Radio<String>(
                                            value: option,
                                            groupValue: halfDayType,
                                            onChanged: (v) => setState(() {
                                              halfDayType = v!;
                                              startHalfDayType = v;
                                              endHalfDayType = v;
                                            }),
                                            activeColor: const Color(0xFF6B46C1),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  option == 'FN' ? 'Forenoon (FN)' : 'Afternoon (AF)',
                                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 15),
                                                ),
                                                Text(
                                                  option == 'FN' ? '9:00 AM - 1:00 PM' : '1:00 PM - 6:00 PM',
                                                  style: TextStyle(color: Colors.black54, fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Multi-day configurations
                    if (numberOfDays > 1) ...[
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Start Day', Icons.play_arrow),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _buildRadioOption('Full Day', '9:00 AM - 6:00 PM', true, isStartFullDay, (v) => setState(() => isStartFullDay = v!))),
                                const SizedBox(width: 16),
                                Expanded(child: _buildRadioOption('Half Day', 'Afternoon only', false, isStartFullDay, (v) => setState(() => isStartFullDay = v!))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('End Day', Icons.stop),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _buildRadioOption('Full Day', '9:00 AM - 6:00 PM', true, isEndFullDay, (v) => setState(() => isEndFullDay = v!))),
                                const SizedBox(width: 16),
                                Expanded(child: _buildRadioOption('Half Day', 'Forenoon only', false, isEndFullDay, (v) => setState(() => isEndFullDay = v!))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Date Selection
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(numberOfDays == 1 ? 'Select Date' : 'Select Dates', Icons.date_range),
                          const SizedBox(height: 20),
                          _buildDateButton('Start Date', startDate, _pickStartDate),
                          if (numberOfDays > 1) ...[
                            const SizedBox(height: 16),
                            _buildDateButton('End Date', endDate, _pickEndDate),
                          ],
                        ],
                      ),
                    ),

                    // Leave Details
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Leave Details', Icons.description),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.05),
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: selectedReason,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(20),
                                hintText: 'Choose Reason',
                                hintStyle: TextStyle(color: Colors.black54),
                              ),
                              style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
                              dropdownColor: Colors.white,
                              items: LeaveService.getLeaveReasons()
                                  .map((reason) => DropdownMenuItem(
                                    value: reason, 
                                    child: Text(reason, style: const TextStyle(color: Colors.black87))
                                  ))
                                  .toList(),
                              onChanged: (value) => setState(() => selectedReason = value),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.05),
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: explanationController,
                              maxLines: 4,
                              style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(20),
                                hintText: 'Provide additional explanation...',
                                hintStyle: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Leave Summary
                    if (startDate != null && endDate != null)
                      _buildCard(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: backgroundGradient,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.summarize, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text('Leave Summary', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                LeaveService.getLeaveDetailsText(
                                  startDate: startDate,
                                  endDate: endDate,
                                  numberOfDays: numberOfDays,
                                  isFullDay: isFullDay,
                                  halfDayType: halfDayType,
                                  isStartFullDay: isStartFullDay,
                                  isEndFullDay: isEndFullDay,
                                  startHalfDayType: startHalfDayType,
                                  endHalfDayType: endHalfDayType,
                                  leaveDuration: LeaveService.calculateLeaveDuration(
                                    numberOfDays: numberOfDays,
                                    isFullDay: isFullDay,
                                    isStartFullDay: isStartFullDay,
                                    isEndFullDay: isEndFullDay,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Submit Button
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        gradient: backgroundGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2), 
                            blurRadius: 15, 
                            offset: const Offset(0, 8)
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submitLeaveApplication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 64),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text(
                          'Submit Leave Application',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF6B46C1)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  Text(
                    date != null ? LeaveService.formatDate(date) : 'Select $label',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 16),
          ],
        ),
      ),
    );
  }
}