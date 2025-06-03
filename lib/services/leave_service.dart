import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/leave_application.dart';
import '../models/leave_request.dart';

class LeaveService {
  static const List<String> leaveReasons = [
    'Sick Leave',
    'Casual Leave',
    'Personal Leave',
    'Emergency Leave',
    'Medical Leave',
  ];

  // Method to get leave reasons list
  static List<String> getLeaveReasons() {
    return leaveReasons;
  }

  // Method to get available half-day options for start day
  static List<String> getStartHalfDayOptions(int numberOfDays) {
    if (numberOfDays == 1) {
      // Single day - both options available
      return ['FN', 'AF'];
    } else {
      // Multi-day - only AF (Afternoon) for start day
      return ['AF'];
    }
  }

  // Method to get available half-day options for end day
  static List<String> getEndHalfDayOptions(int numberOfDays) {
    if (numberOfDays == 1) {
      // Single day - both options available
      return ['FN', 'AF'];
    } else {
      // Multi-day - only FN (Forenoon) for end day
      return ['FN'];
    }
  }

  // Method to get default half-day option for start day
  static String getDefaultStartHalfDayOption(int numberOfDays) {
    if (numberOfDays == 1) {
      return 'FN'; // Default to Forenoon for single day
    } else {
      return 'AF'; // Only option for multi-day start
    }
  }

  // Method to get default half-day option for end day
  static String getDefaultEndHalfDayOption(int numberOfDays) {
    if (numberOfDays == 1) {
      return 'AF'; // Default to Afternoon for single day
    } else {
      return 'FN'; // Only option for multi-day end
    }
  }

  // Method to validate half-day selections
  static bool isValidHalfDaySelection({
    required int numberOfDays,
    required String startHalfDayType,
    required String endHalfDayType,
    required bool isStartFullDay,
    required bool isEndFullDay,
  }) {
    // If both are full days, no validation needed
    if (isStartFullDay && isEndFullDay) return true;

    if (numberOfDays == 1) {
      // Single day - any combination is valid
      return true;
    } else {
      // Multi-day validation
      bool startValid = isStartFullDay || startHalfDayType == 'AF';
      bool endValid = isEndFullDay || endHalfDayType == 'FN';
      return startValid && endValid;
    }
  }

  // Date validation methods
  static bool isSelectable(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Must be at least tomorrow and not Sunday
    return dateOnly.isAfter(today) && date.weekday != DateTime.sunday;
  }

  static DateTime getNextSelectableDate(DateTime startFrom) {
    DateTime candidate = startFrom;
    int attempts = 0;
    const maxAttempts = 60;
    
    while (!isSelectable(candidate) && attempts < maxAttempts) {
      candidate = candidate.add(const Duration(days: 1));
      attempts++;
    }
    
    return candidate;
  }

  // Method to pick start date
  static Future<Map<String, dynamic>?> pickStartDate({
    required BuildContext context,
    required DateTime? currentStartDate,
    required int numberOfDays,
  }) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentStartDate ?? getNextSelectableDate(DateTime.now().add(const Duration(days: 1))),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: isSelectable,
    );

    if (pickedDate != null) {
      final DateTime? endDate = calculateEndDate(pickedDate, numberOfDays);
      return {
        'startDate': pickedDate,
        'endDate': endDate,
      };
    }
    return null;
  }

  // Method to pick end date
  static Future<Map<String, dynamic>?> pickEndDate({
    required BuildContext context,
    required DateTime? startDate,
  }) async {
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start date first'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: startDate.add(const Duration(days: 1)),
      firstDate: startDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: isSelectable,
    );

    if (pickedDate != null) {
      final int numberOfDays = calculateNumberOfDays(startDate, pickedDate);
      return {
        'endDate': pickedDate,
        'numberOfDays': numberOfDays,
      };
    }
    return null;
  }

  // Date calculation methods
  static DateTime? calculateEndDate(DateTime? startDate, int numberOfDays) {
    if (startDate == null) return null;
    
    if (numberOfDays == 1) {
      return startDate;
    } else {
      DateTime calculatedEndDate = startDate;
      int daysAdded = 0;
      
      while (daysAdded < numberOfDays - 1) {
        calculatedEndDate = calculatedEndDate.add(const Duration(days: 1));
        if (isSelectable(calculatedEndDate)) {
          daysAdded++;
        }
      }
      return calculatedEndDate;
    }
  }

  static int calculateNumberOfDays(DateTime startDate, DateTime endDate) {
    int days = 0;
    DateTime current = startDate;
    
    while (!current.isAfter(endDate)) {
      if (isSelectable(current)) {
        days++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    return days;
  }

  // Leave duration calculation
  static double calculateLeaveDuration({
    required int numberOfDays,
    required bool isFullDay,
    required bool isStartFullDay,
    required bool isEndFullDay,
  }) {
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

  // DateTime calculation methods
  static DateTime getStartDateTime({
    required DateTime startDate,
    required int numberOfDays,
    required bool isFullDay,
    required String halfDayType,
    required bool isStartFullDay,
    required String startHalfDayType,
  }) {
    if (numberOfDays == 1) {
      // Single day logic
      if (isFullDay) {
        return DateTime(startDate.year, startDate.month, startDate.day, 9, 0);
      } else {
        if (halfDayType == 'FN') {
          return DateTime(startDate.year, startDate.month, startDate.day, 9, 0);
        } else {
          return DateTime(startDate.year, startDate.month, startDate.day, 13, 0);
        }
      }
    } else {
      // Multi-day logic
      if (isStartFullDay) {
        return DateTime(startDate.year, startDate.month, startDate.day, 9, 0);
      } else {
        // For multi-day, start half-day can only be AF (Afternoon)
        if (startHalfDayType == 'FN') {
          return DateTime(startDate.year, startDate.month, startDate.day, 9, 0);
        } else {
          return DateTime(startDate.year, startDate.month, startDate.day, 13, 0);
        }
      }
    }
  }

  static DateTime getEndDateTime({
    required DateTime endDate,
    required int numberOfDays,
    required bool isFullDay,
    required String halfDayType,
    required bool isEndFullDay,
    required String endHalfDayType,
  }) {
    if (numberOfDays == 1) {
      // Single day logic
      if (isFullDay) {
        return DateTime(endDate.year, endDate.month, endDate.day, 18, 0);
      } else {
        if (halfDayType == 'FN') {
          return DateTime(endDate.year, endDate.month, endDate.day, 13, 0);
        } else {
          return DateTime(endDate.year, endDate.month, endDate.day, 18, 0);
        }
      }
    } else {
      // Multi-day logic
      if (isEndFullDay) {
        return DateTime(endDate.year, endDate.month, endDate.day, 18, 0);
      } else {
        // For multi-day, end half-day can only be FN (Forenoon)
        if (endHalfDayType == 'FN') {
          return DateTime(endDate.year, endDate.month, endDate.day, 13, 0);
        } else {
          return DateTime(endDate.year, endDate.month, endDate.day, 18, 0);
        }
      }
    }
  }

  // Validation methods
  static bool validateForm({
    required DateTime? startDate,
    required DateTime? endDate,
    required String? selectedReason,
    required String explanation,
    required int numberOfDays,
    required DateTime startDateTime,
    required bool isStartFullDay,
    required bool isEndFullDay,
    required String startHalfDayType,
    required String endHalfDayType,
  }) {
    if (startDate == null || selectedReason == null || explanation.trim().isEmpty) {
      return false;
    }

    if (numberOfDays > 1 && endDate == null) {
      return false;
    }

    // Check 24-hour advance requirement
    final now = DateTime.now();
    if (startDateTime.difference(now).inHours < 24) {
      return false;
    }

    // Validate half-day selections for multi-day leaves
    if (!isValidHalfDaySelection(
      numberOfDays: numberOfDays,
      startHalfDayType: startHalfDayType,
      endHalfDayType: endHalfDayType,
      isStartFullDay: isStartFullDay,
      isEndFullDay: isEndFullDay,
    )) {
      return false;
    }

    return true;
  }

  static String getValidationError({
    required DateTime? startDate,
    required DateTime? endDate,
    required String? selectedReason,
    required String explanation,
    required int numberOfDays,
    required DateTime startDateTime,
    required bool isStartFullDay,
    required bool isEndFullDay,
    required String startHalfDayType,
    required String endHalfDayType,
  }) {
    if (startDate == null || selectedReason == null || explanation.trim().isEmpty) {
      return 'Please fill all fields';
    }

    if (numberOfDays > 1 && endDate == null) {
      return 'Please select end date';
    }

    // Check 24-hour advance requirement
    final now = DateTime.now();
    if (startDateTime.difference(now).inHours < 24) {
      return 'Leave must be applied at least 24 hours in advance';
    }

    // Validate half-day selections for multi-day leaves
    if (!isValidHalfDaySelection(
      numberOfDays: numberOfDays,
      startHalfDayType: startHalfDayType,
      endHalfDayType: endHalfDayType,
      isStartFullDay: isStartFullDay,
      isEndFullDay: isEndFullDay,
    )) {
      if (numberOfDays > 1) {
        return 'For multi-day leave: Start half-day must be Afternoon (AF) and End half-day must be Forenoon (FN)';
      }
    }

    return '';
  }

  // Leave details text generation
  static String getLeaveDetailsText({
    required DateTime? startDate,
    required DateTime? endDate,
    required int numberOfDays,
    required bool isFullDay,
    required String halfDayType,
    required bool isStartFullDay,
    required bool isEndFullDay,
    required String startHalfDayType,
    required String endHalfDayType,
    required double leaveDuration,
  }) {
    if (startDate == null || endDate == null) return '';
    
    String startDateStr = formatDate(startDate);
    String endDateStr = formatDate(endDate);
    
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

  // Utility methods
  static String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  // Firebase operations
  static Future<void> submitLeaveApplication(LeaveApplication leaveApplication) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await FirebaseFirestore.instance
        .collection('leaveapplication')
        .doc(user.uid)
        .collection('userLeaves')
        .add(leaveApplication.toMap());
  }

  // NEW METHOD: Fetch user's leave requests from Firebase
  static Future<List<LeaveRequest>> fetchUserLeaves() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('leaveapplication')
          .doc(user.uid)
          .collection('userLeaves')
          .orderBy('appliedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return LeaveRequest.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch leave requests: $e');
    }
  }
}