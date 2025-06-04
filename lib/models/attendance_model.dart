import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single attendance record (per date/session).
class AttendanceRecord {
  final DateTime timestamp;
  final String remark;
  final bool fn; // Forenoon session
  final bool an; // Afternoon session

  AttendanceRecord({
    required this.timestamp,
    required this.remark,
    this.fn = false,
    this.an = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'remark': remark,
      'FN': fn,
      'AN': an,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
      remark: map['remark'] ?? '',
      fn: map['FN'] ?? false,
      an: map['AN'] ?? false,
    );
  }
}

/// Represents an employee's basic details.
class Employee {
  final String id;
  final String name;

  Employee({
    required this.id,
    required this.name,
  });

  factory Employee.fromMap(Map<String, dynamic> map, String id) {
    return Employee(
      id: id,
      name: map['name'] ?? 'Employee',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}

/// Represents all attendance records for a specific employee.
class AttendanceDocument {
  final String empId;
  final Map<String, AttendanceRecord> records;

  AttendanceDocument({
    required this.empId,
    required this.records,
  });

  Map<String, dynamic> toMap() {
    return {
      'empId': empId,
      'records': records.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  factory AttendanceDocument.fromMap(Map<String, dynamic> map) {
    final recordsMap = Map<String, dynamic>.from(map['records'] ?? {});
    final records = <String, AttendanceRecord>{};

    recordsMap.forEach((key, value) {
      records[key] = AttendanceRecord.fromMap(Map<String, dynamic>.from(value));
    });

    return AttendanceDocument(
      empId: map['empId'] ?? '',
      records: records,
    );
  }
}

/// Summarizes monthly attendance count for an employee.
class MonthlySummary {
  final String empId;
  final String month; // e.g., "2024-06"
  final int count;

  MonthlySummary({
    required this.empId,
    required this.month,
    required this.count,
  });

  Map<String, dynamic> toMap() {
    return {
      'empId': empId,
      'month': month,
      'count': count,
    };
  }

  factory MonthlySummary.fromMap(Map<String, dynamic> map) {
    return MonthlySummary(
      empId: map['empId'] ?? '',
      month: map['month'] ?? '',
      count: map['count'] ?? 0,
    );
  }
}

/// Eligibility result for marking attendance.
class AttendanceEligibility {
  final bool isSunday;
  final bool isEligibleTime;
  final String? session; // 'FN' or 'AN'
  final bool isEarly;
  final bool isLateFN;
  final bool isTooLate;
  final String? lateMessage;
  final Duration? timeRemaining;

  AttendanceEligibility({
    required this.isSunday,
    required this.isEligibleTime,
    this.session,
    required this.isEarly,
    required this.isLateFN,
    required this.isTooLate,
    this.lateMessage,
    this.timeRemaining,
  });
}