import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaveUtils {
  static String formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Invalid Date';
      }
      return DateFormat('dd/MM/yyyy, h:mm a').format(date);
    } catch (e) {
      debugPrint('DEBUG: Error formatting date: $e');
      return 'Invalid Date';
    }
  }

  static String formatDateOnly(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Invalid Date';
      }
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      debugPrint('DEBUG: Error formatting date: $e');
      return 'Invalid Date';
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9500); // Orange
      case 'approved':
      case 'accepted':
        return const Color(0xFF34C759); // Green
      case 'rejected':
        return const Color(0xFFFF3B30); // Red
      case 'expired':
        return const Color(0xFF8E8E93); // Gray
      default:
        return const Color(0xFF6B73FF); // Default purple
    }
  }

  static int calculateDays(dynamic start, dynamic end) {
    try {
      DateTime startDate, endDate;

      if (start is Timestamp && end is Timestamp) {
        startDate = start.toDate();
        endDate = end.toDate();
      } else if (start is DateTime && end is DateTime) {
        startDate = start;
        endDate = end;
      } else {
        return 0;
      }

      return endDate.difference(startDate).inDays + 1;
    } catch (e) {
      debugPrint('DEBUG: Error calculating days: $e');
      return 0;
    }
  }
}
