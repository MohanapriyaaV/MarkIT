import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplyLeavePage extends StatefulWidget {
  const ApplyLeavePage({Key? key}) : super(key: key);

  @override
  State<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<ApplyLeavePage> {
  int numberOfDays = 1;
  bool isFullDay = true; // For single day leave
  String halfDayType = 'FN'; // FN or AN
  
  // Enhanced fields for cross-day half-day support
  bool isStartFullDay = true;
  bool isEndFullDay = true;
  String startHalfDayType = 'FN'; // FN or AN
  String endHalfDayType = 'AN'; // FN or AN
  
  DateTime? startDate;
  DateTime? endDate;
  String? selectedReason;
  final TextEditingController explanationController = TextEditingController();

  final List<String> leaveReasons = [
    'Sick Leave',
    'Casual Leave',
    'Personal Leave',
    'Emergency Leave',
    'Medical Leave',
  ];

  bool _isSelectable(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Must be at least tomorrow and not Sunday
    return dateOnly.isAfter(today) && date.weekday != DateTime.sunday;
  }

  DateTime _getNextSelectableDate(DateTime startFrom) {
    DateTime candidate = startFrom;
    int attempts = 0;
    const maxAttempts = 60;
    
    while (!_isSelectable(candidate) && attempts < maxAttempts) {
      candidate = candidate.add(const Duration(days: 1));
      attempts++;
    }
    
    return candidate;
  }

  Future<void> _pickStartDate() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      DateTime firstDate = today.add(const Duration(days: 1));
      DateTime lastDate = today.add(const Duration(days: 365));
      DateTime initialDate = _getNextSelectableDate(firstDate);
      
      if (initialDate.isAfter(lastDate)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No valid dates available for selection'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      final pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        selectableDayPredicate: _isSelectable,
        helpText: 'Select Start Date',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).primaryColor,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate != null && mounted) {
        setState(() {
          startDate = pickedDate;
          if (numberOfDays == 1) {
            endDate = startDate;
          } else {
            _calculateEndDate();
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking start date: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error selecting date. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickEndDate() async {
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start date first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      DateTime firstDate = startDate!;
      DateTime lastDate = startDate!.add(const Duration(days: 365));
      DateTime initialDate = _getNextSelectableDate(firstDate);
      
      if (initialDate.isAfter(lastDate)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No valid end dates available for selection'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      final pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        selectableDayPredicate: (date) => _isSelectable(date) && !date.isBefore(startDate!),
        helpText: 'Select End Date',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).primaryColor,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate != null && mounted) {
        setState(() {
          endDate = pickedDate;
          _calculateNumberOfDays();
        });
      }
    } catch (e) {
      debugPrint('Error picking end date: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error selecting end date. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _calculateEndDate() {
    if (startDate == null) return;
    
    if (numberOfDays == 1) {
      endDate = startDate;
    } else {
      DateTime calculatedEndDate = startDate!;
      int daysAdded = 0;
      
      while (daysAdded < numberOfDays - 1) {
        calculatedEndDate = calculatedEndDate.add(const Duration(days: 1));
        if (_isSelectable(calculatedEndDate)) {
          daysAdded++;
        }
      }
      endDate = calculatedEndDate;
    }
  }

  void _calculateNumberOfDays() {
    if (startDate == null || endDate == null) return;
    
    int days = 0;
    DateTime current = startDate!;
    
    while (!current.isAfter(endDate!)) {
      if (_isSelectable(current)) {
        days++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    numberOfDays = days;
  }

  double _calculateLeaveDuration() {
    if (startDate == null || endDate == null) return 0.0;
    
    if (numberOfDays == 1) {
      // Single day leave
      return isFullDay ? 1.0 : 0.5;
    } else {
      // Multi-day leave
      double totalDays = 0.0;
      
      // Start day calculation
      if (isStartFullDay) {
        totalDays += 1.0;
      } else {
        totalDays += 0.5;
      }
      
      // Middle days (full days)
      if (numberOfDays > 2) {
        totalDays += (numberOfDays - 2) * 1.0;
      }
      
      // End day calculation (only if different from start day)
      if (numberOfDays > 1) {
        if (isEndFullDay) {
          totalDays += 1.0;
        } else {
          totalDays += 0.5;
        }
      }
      
      return totalDays;
    }
  }

  DateTime _getStartDateTime() {
    if (startDate == null) return DateTime.now();
    
    if (numberOfDays == 1) {
      // Single day logic
      if (isFullDay) {
        return DateTime(startDate!.year, startDate!.month, startDate!.day, 9, 0);
      } else {
        if (halfDayType == 'FN') {
          return DateTime(startDate!.year, startDate!.month, startDate!.day, 9, 0);
        } else {
          return DateTime(startDate!.year, startDate!.month, startDate!.day, 13, 0);
        }
      }
    } else {
      // Multi-day logic
      if (isStartFullDay) {
        return DateTime(startDate!.year, startDate!.month, startDate!.day, 9, 0);
      } else {
        if (startHalfDayType == 'FN') {
          return DateTime(startDate!.year, startDate!.month, startDate!.day, 9, 0);
        } else {
          return DateTime(startDate!.year, startDate!.month, startDate!.day, 13, 0);
        }
      }
    }
  }

  DateTime _getEndDateTime() {
    if (endDate == null) return DateTime.now();
    
    if (numberOfDays == 1) {
      // Single day logic
      if (isFullDay) {
        return DateTime(endDate!.year, endDate!.month, endDate!.day, 18, 0);
      } else {
        if (halfDayType == 'FN') {
          return DateTime(endDate!.year, endDate!.month, endDate!.day, 13, 0);
        } else {
          return DateTime(endDate!.year, endDate!.month, endDate!.day, 18, 0);
        }
      }
    } else {
      // Multi-day logic
      if (isEndFullDay) {
        return DateTime(endDate!.year, endDate!.month, endDate!.day, 18, 0);
      } else {
        if (endHalfDayType == 'FN') {
          return DateTime(endDate!.year, endDate!.month, endDate!.day, 13, 0);
        } else {
          return DateTime(endDate!.year, endDate!.month, endDate!.day, 18, 0);
        }
      }
    }
  }

  bool _validateForm() {
    if (startDate == null ||
        selectedReason == null ||
        explanationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (numberOfDays > 1 && endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select end date'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    // Check 24-hour advance requirement
    final startDateTime = _getStartDateTime();
    final now = DateTime.now();
    if (startDateTime.difference(now).inHours < 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave must be applied at least 24 hours in advance'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _submitLeaveApplication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_validateForm()) return;

    final startDateTime = _getStartDateTime();
    final endDateTime = _getEndDateTime();
    final leaveDuration = _calculateLeaveDuration();

    final leaveData = {
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'numberOfDays': numberOfDays,
      'leaveDuration': leaveDuration, // Actual leave duration in days (can be fractional)
      'isFullDay': numberOfDays == 1 ? isFullDay : null,
      'halfDayType': numberOfDays == 1 && !isFullDay ? halfDayType : null,
      'isStartFullDay': numberOfDays > 1 ? isStartFullDay : null,
      'isEndFullDay': numberOfDays > 1 ? isEndFullDay : null,
      'startHalfDayType': numberOfDays > 1 && !isStartFullDay ? startHalfDayType : null,
      'endHalfDayType': numberOfDays > 1 && !isEndFullDay ? endHalfDayType : null,
      'reason': selectedReason,
      'explanation': explanationController.text.trim(),
      'status': 'Pending',
      'appliedAt': Timestamp.now(),
      'userID': user.uid,
    };

    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      await FirebaseFirestore.instance
          .collection('leaveapplication')
          .doc(user.uid)
          .collection('userLeaves')
          .add(leaveData);

      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success dialog
        _showSuccessDialog();
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
        
        debugPrint('Error submitting leave: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error submitting leave. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    String leaveDetails = _getLeaveDetailsText();
    
   showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => SingleChildScrollView(
    child: AlertDialog(
      title: const Text(
        'Leave Applied Successfully!',
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            leaveDetails,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'HR will reply to you within 16 hours from the leave applied.',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            Navigator.of(context).pop(); // Go back to dashboard
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('OK'),
        ),
      ],
    ),
  ),
);

  }

  String _getLeaveDetailsText() {
    if (startDate == null || endDate == null) return '';
    
    String startDateStr = _formatDate(startDate!);
    String endDateStr = _formatDate(endDate!);
    double leaveDuration = _calculateLeaveDuration();
    
    if (numberOfDays == 1) {
      if (isFullDay) {
        return 'You have applied for a full day leave on $startDateStr ($leaveDuration day)';
      } else {
        String timeStr = halfDayType == 'FN' ? '9:00 AM to 1:00 PM' : '1:00 PM to 6:00 PM';
        String halfStr = halfDayType == 'FN' ? 'Forenoon' : 'Afternoon';
        return 'You have applied for a half day ($halfStr) leave on $startDateStr\nTime: $timeStr ($leaveDuration day)';
      }
    } else {
      String details = 'You have applied for leave from $startDateStr to $endDateStr ($leaveDuration days)\n\n';
      
      // Start day details
      if (isStartFullDay) {
        details += 'Start: Full day on $startDateStr (9:00 AM - 6:00 PM)\n';
      } else {
        String startTime = startHalfDayType == 'FN' ? '9:00 AM - 1:00 PM' : '1:00 PM - 6:00 PM';
        String startHalf = startHalfDayType == 'FN' ? 'Forenoon' : 'Afternoon';
        details += 'Start: $startHalf on $startDateStr ($startTime)\n';
      }
      
      // End day details (if different from start)
      if (numberOfDays > 1) {
        if (isEndFullDay) {
          details += 'End: Full day on $endDateStr (9:00 AM - 6:00 PM)';
        } else {
          String endTime = endHalfDayType == 'FN' ? '9:00 AM - 1:00 PM' : '1:00 PM - 6:00 PM';
          String endHalf = endHalfDayType == 'FN' ? 'Forenoon' : 'Afternoon';
          details += 'End: $endHalf on $endDateStr ($endTime)';
        }
      }
      
      return details;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  void dispose() {
    explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Leave'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Number of Days Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Number of Days",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text("Days: ", style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: numberOfDays > 1 ? () {
                                  setState(() {
                                    numberOfDays--;
                                    if (numberOfDays == 1) {
                                      endDate = startDate;
                                    } else {
                                      _calculateEndDate();
                                    }
                                  });
                                } : null,
                                icon: const Icon(Icons.remove),
                                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  numberOfDays.toString(),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                onPressed: numberOfDays < 30 ? () {
                                  setState(() {
                                    numberOfDays++;
                                    _calculateEndDate();
                                  });
                                } : null,
                                icon: const Icon(Icons.add),
                                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (startDate != null && endDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_calculateLeaveDuration()} days',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Day Type Card (only for single day)
            if (numberOfDays == 1) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Day Type",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Full Day'),
                              subtitle: const Text('9:00 AM - 6:00 PM'),
                              value: true,
                              groupValue: isFullDay,
                              onChanged: (value) {
                                setState(() {
                                  isFullDay = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Half Day'),
                              subtitle: const Text('FN or AN'),
                              value: false,
                              groupValue: isFullDay,
                              onChanged: (value) {
                                setState(() {
                                  isFullDay = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      if (!isFullDay) ...[
                        const SizedBox(height: 12),
                        const Text("Half Day Type", style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Forenoon (FN)'),
                                subtitle: const Text('9:00 AM - 1:00 PM'),
                                value: 'FN',
                                groupValue: halfDayType,
                                onChanged: (value) {
                                  setState(() {
                                    halfDayType = value!;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Afternoon (AN)'),
                                subtitle: const Text('1:00 PM - 6:00 PM'),
                                value: 'AN',
                                groupValue: halfDayType,
                                onChanged: (value) {
                                  setState(() {
                                    halfDayType = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Multi-day leave configuration
            if (numberOfDays > 1) ...[
              // Start Day Configuration
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Start Day Configuration",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Full Day'),
                              subtitle: const Text('9:00 AM - 6:00 PM'),
                              value: true,
                              groupValue: isStartFullDay,
                              onChanged: (value) {
                                setState(() {
                                  isStartFullDay = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Half Day'),
                              subtitle: const Text('FN or AN'),
                              value: false,
                              groupValue: isStartFullDay,
                              onChanged: (value) {
                                setState(() {
                                  isStartFullDay = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                     if (!isStartFullDay) ...[
  const SizedBox(height: 12),
  const Text("Start Half Day Type", style: TextStyle(fontWeight: FontWeight.w500)),
  const SizedBox(height: 8),
  Row(
    children: [
      if (numberOfDays == 1) ...[
        Expanded(
          child: RadioListTile<String>(
            title: const Text('Forenoon (FN)'),
            subtitle: const Text('9:00 AM - 1:00 PM'),
            value: 'FN',
            groupValue: startHalfDayType,
            onChanged: (value) {
              setState(() {
                startHalfDayType = value!;
              });
            },
          ),
        ),
      ],
      Expanded(
        child: RadioListTile<String>(
          title: const Text('Afternoon (AN)'),
          subtitle: const Text('1:00 PM - 6:00 PM'),
          value: 'AN',
          groupValue: startHalfDayType,
          onChanged: (value) {
            setState(() {
              startHalfDayType = value!;
            });
          },
        ),
      ),
    ],
  ),
],


                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // End Day Configuration
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "End Day Configuration",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Full Day'),
                              subtitle: const Text('9:00 AM - 6:00 PM'),
                              value: true,
                              groupValue: isEndFullDay,
                              onChanged: (value) {
                                setState(() {
                                  isEndFullDay = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Half Day'),
                              subtitle: const Text('FN or AN'),
                              value: false,
                              groupValue: isEndFullDay,
                              onChanged: (value) {
                                setState(() {
                                  isEndFullDay = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                 if (!isEndFullDay) ...[
  const SizedBox(height: 12),
  const Text("End Half Day Type", style: TextStyle(fontWeight: FontWeight.w500)),
  const SizedBox(height: 8),
  Row(
    children: [
      Expanded(
        child: RadioListTile<String>(
          title: const Text('Forenoon (FN)'),
          subtitle: const Text('9:00 AM - 1:00 PM'),
          value: 'FN',
          groupValue: endHalfDayType,
          onChanged: (value) {
            setState(() {
              endHalfDayType = value!;
            });
          },
        ),
      ),
    ],
  ),
],



                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Date Selection Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      numberOfDays == 1 ? "Select Date" : "Select Dates",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickStartDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(startDate != null ? _formatDate(startDate!) : 'Select Start Date'),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    if (numberOfDays > 1) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickEndDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(endDate != null ? _formatDate(endDate!) : 'Select End Date'),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                    if (numberOfDays == 1 && startDate != null && endDate != null) ...[
                      const SizedBox(height: 12),
                      const Text("End Date", style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(_formatDate(endDate!)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Leave Details Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Leave Details",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text("Reason", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: leaveReasons
                          .map((reason) => DropdownMenuItem(
                                value: reason,
                                child: Text(reason),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value;
                        });
                      },
                      hint: const Text("Choose Reason"),
                    ),
                    const SizedBox(height: 16),
                    const Text("Explanation", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: explanationController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Provide additional explanation for your leave request",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Leave Summary Card (if dates are selected)
            if (startDate != null && endDate != null) ...[
              Card(
                elevation: 4,
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Leave Summary",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getLeaveDetailsText(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button
            ElevatedButton(
              onPressed: _submitLeaveApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Submit Leave Application',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}