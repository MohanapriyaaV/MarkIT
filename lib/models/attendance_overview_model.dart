// models/attendance_overview_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceOverviewData {
  final double currentMonthRate;
  final double punctualityScore;
  final int earlyAttendanceCount;
  final int currentMonthAttendedDays;
  final int currentMonthWorkingDays;
  final List<MonthlyTrend> monthlyTrends;
  final MonthlyTrend? bestMonth;
  final MonthlyTrend? worstMonth;
  final List<DailyAttendance> recentTrends;
  final double monthOverMonthChange;

  AttendanceOverviewData({
    required this.currentMonthRate,
    required this.punctualityScore,
    required this.earlyAttendanceCount,
    required this.currentMonthAttendedDays,
    required this.currentMonthWorkingDays,
    required this.monthlyTrends,
    this.bestMonth,
    this.worstMonth,
    required this.recentTrends,
    required this.monthOverMonthChange,
  });

  factory AttendanceOverviewData.fromMap(Map<String, dynamic> map) {
    return AttendanceOverviewData(
      currentMonthRate: (map['currentMonthRate'] ?? 0.0).toDouble(),
      punctualityScore: (map['punctualityScore'] ?? 0.0).toDouble(),
      earlyAttendanceCount: map['earlyAttendanceCount'] ?? 0,
      currentMonthAttendedDays: map['currentMonthAttendedDays'] ?? 0,
      currentMonthWorkingDays: map['currentMonthWorkingDays'] ?? 0,
      monthlyTrends: (map['monthlyTrends'] as List<dynamic>? ?? [])
          .map((e) => MonthlyTrend.fromMap(e as Map<String, dynamic>))
          .toList(),
      bestMonth: map['bestMonth'] != null 
          ? MonthlyTrend.fromMap(map['bestMonth'] as Map<String, dynamic>)
          : null,
      worstMonth: map['worstMonth'] != null 
          ? MonthlyTrend.fromMap(map['worstMonth'] as Map<String, dynamic>)
          : null,
      recentTrends: (map['recentTrends'] as List<dynamic>? ?? [])
          .map((e) => DailyAttendance.fromMap(e as Map<String, dynamic>))
          .toList(),
      monthOverMonthChange: (map['monthOverMonthChange'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentMonthRate': currentMonthRate,
      'punctualityScore': punctualityScore,
      'earlyAttendanceCount': earlyAttendanceCount,
      'currentMonthAttendedDays': currentMonthAttendedDays,
      'currentMonthWorkingDays': currentMonthWorkingDays,
      'monthlyTrends': monthlyTrends.map((e) => e.toMap()).toList(),
      'bestMonth': bestMonth?.toMap(),
      'worstMonth': worstMonth?.toMap(),
      'recentTrends': recentTrends.map((e) => e.toMap()).toList(),
      'monthOverMonthChange': monthOverMonthChange,
    };
  }
}

class MonthlyTrend {
  final String month;
  final String monthName;
  final double attendanceRate;
  final int totalAttendedDays;
  final int totalWorkingDays;
  final int totalSessions;

  MonthlyTrend({
    required this.month,
    required this.monthName,
    required this.attendanceRate,
    required this.totalAttendedDays,
    required this.totalWorkingDays,
    required this.totalSessions,
  });

  factory MonthlyTrend.fromMap(Map<String, dynamic> map) {
    return MonthlyTrend(
      month: map['month'] ?? '',
      monthName: map['monthName'] ?? '',
      attendanceRate: (map['attendanceRate'] ?? 0.0).toDouble(),
      totalAttendedDays: map['totalAttendedDays'] ?? 0,
      totalWorkingDays: map['totalWorkingDays'] ?? 0,
      totalSessions: map['totalSessions'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'monthName': monthName,
      'attendanceRate': attendanceRate,
      'totalAttendedDays': totalAttendedDays,
      'totalWorkingDays': totalWorkingDays,
      'totalSessions': totalSessions,
    };
  }
}

class DailyAttendance {
  final String date;
  final bool fnAttended;
  final bool anAttended;
  final bool hasEarlyAttendance;
  final String? fnRemark;
  final String? anRemark;
  final DateTime? fnTimestamp;
  final DateTime? anTimestamp;

  DailyAttendance({
    required this.date,
    required this.fnAttended,
    required this.anAttended,
    required this.hasEarlyAttendance,
    this.fnRemark,
    this.anRemark,
    this.fnTimestamp,
    this.anTimestamp,
  });

  factory DailyAttendance.fromMap(Map<String, dynamic> map) {
    return DailyAttendance(
      date: map['date'] ?? '',
      fnAttended: map['fnAttended'] ?? false,
      anAttended: map['anAttended'] ?? false,
      hasEarlyAttendance: map['hasEarlyAttendance'] ?? false,
      fnRemark: map['fnRemark'],
      anRemark: map['anRemark'],
      fnTimestamp: map['fnTimestamp'] is Timestamp 
          ? (map['fnTimestamp'] as Timestamp).toDate()
          : null,
      anTimestamp: map['anTimestamp'] is Timestamp 
          ? (map['anTimestamp'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'fnAttended': fnAttended,
      'anAttended': anAttended,
      'hasEarlyAttendance': hasEarlyAttendance,
      'fnRemark': fnRemark,
      'anRemark': anRemark,
      'fnTimestamp': fnTimestamp != null ? Timestamp.fromDate(fnTimestamp!) : null,
      'anTimestamp': anTimestamp != null ? Timestamp.fromDate(anTimestamp!) : null,
    };
  }

  bool get hasAttendance => fnAttended || anAttended;
  int get sessionsAttended => (fnAttended ? 1 : 0) + (anAttended ? 1 : 0);
}

// Updated models to work with existing attendance system
class Employee {
  final String empId;
  final String name;
  final String department;
  final String? email;
  final String? phone;

  Employee({
    required this.empId,
    required this.name,
    required this.department,
    this.email,
    this.phone,
  });

  factory Employee.fromMap(Map<String, dynamic> map, String empId) {
    return Employee(
      empId: empId,
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      email: map['email'],
      phone: map['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'department': department,
      'email': email,
      'phone': phone,
    };
  }
}

class AttendanceRecord {
  final bool fn;
  final bool an;
  final DateTime? fnTimestamp;
  final DateTime? anTimestamp;
  final String? fnRemark;
  final String? anRemark;

  AttendanceRecord({
    required this.fn,
    required this.an,
    this.fnTimestamp,
    this.anTimestamp,
    this.fnRemark,
    this.anRemark,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      fn: map['FN'] ?? false,
      an: map['AN'] ?? false,
      fnTimestamp: map['fnTimestamp'] is Timestamp 
          ? (map['fnTimestamp'] as Timestamp).toDate()
          : null,
      anTimestamp: map['anTimestamp'] is Timestamp 
          ? (map['anTimestamp'] as Timestamp).toDate()
          : null,
      fnRemark: map['fnRemark'],
      anRemark: map['anRemark'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'FN': fn,
      'AN': an,
      'fnTimestamp': fnTimestamp != null ? Timestamp.fromDate(fnTimestamp!) : null,
      'anTimestamp': anTimestamp != null ? Timestamp.fromDate(anTimestamp!) : null,
      'fnRemark': fnRemark,
      'anRemark': anRemark,
    };
  }
}

class AttendanceDocument {
  final String empId;
  final Map<String, AttendanceRecord> records;

  AttendanceDocument({
    required this.empId,
    required this.records,
  });

  factory AttendanceDocument.fromMap(Map<String, dynamic> map) {
    final recordsMap = <String, AttendanceRecord>{};
    if (map['records'] != null) {
      final records = map['records'] as Map<String, dynamic>;
      records.forEach((key, value) {
        recordsMap[key] = AttendanceRecord.fromMap(value as Map<String, dynamic>);
      });
    }

    return AttendanceDocument(
      empId: map['empId'] ?? '',
      records: recordsMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'empId': empId,
      'records': records.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}

class AttendanceEligibility {
  final bool isSunday;
  final bool isEligibleTime;
  final String session;
  final bool isEarly;
  final bool isLateFN;
  final bool isTooLate;
  final Duration? timeRemaining;
  final String? lateMessage;

  AttendanceEligibility({
    required this.isSunday,
    required this.isEligibleTime,
    required this.session,
    this.isEarly = false,
    this.isLateFN = false,
    this.isTooLate = false,
    this.timeRemaining,
    this.lateMessage,
  });
}