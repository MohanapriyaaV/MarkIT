// attendance_report_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceReportModel {
  final String empId;
  final String name;
  final String phoneNumber;
  final String joiningDate;
  final String role;
  final String teamId;
  final String manager;
  final ShiftTiming? shiftTiming;
  final Map<String, AttendanceRecord> records;

  AttendanceReportModel({
    required this.empId,
    required this.name,
    required this.phoneNumber,
    required this.joiningDate,
    required this.role,
    required this.teamId,
    required this.manager,
    this.shiftTiming,
    required this.records,
  });

  factory AttendanceReportModel.fromFirestore({
    required Map<String, dynamic> employeeData,
    required Map<String, dynamic> attendanceData,
  }) {
    final records = <String, AttendanceRecord>{};
    final attendanceRecords = Map<String, dynamic>.from(attendanceData['records'] ?? {});
    
    attendanceRecords.forEach((key, value) {
      records[key] = AttendanceRecord.fromMap(value);
    });

    return AttendanceReportModel(
      empId: employeeData['empId'] ?? '',
      name: employeeData['name'] ?? '',
      phoneNumber: employeeData['phoneNumber'] ?? '',
      joiningDate: employeeData['JoiningDate'] ?? '',
      role: employeeData['role'] ?? '',
      teamId: employeeData['teamId'] ?? '',
      manager: employeeData['Manager'] ?? '',
      shiftTiming: employeeData['shiftTiming'] != null 
          ? ShiftTiming.fromMap(employeeData['shiftTiming'])
          : null,
      records: records,
    );
  }

  String get formattedShift {
    if (shiftTiming?.session1Login != null && shiftTiming?.session2Logout != null) {
      return "${shiftTiming!.formatTime(shiftTiming!.session1Login)} - ${shiftTiming!.formatTime(shiftTiming!.session2Logout)}";
    }
    return '';
  }

  AttendanceStats calculateStats(int year, int month) {
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    int present = 0, lop = 0, halfDay = 0, absent = 0;

    for (int i = 1; i <= daysInMonth; i++) {
      final dateKey = "$year-${month.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}";
      if (records.containsKey(dateKey)) {
        final record = records[dateKey]!;
        if (record.present) {
          present++;
        } else if (record.fn || record.an) {
          halfDay++;
        } else {
          absent++;
        }
      }
    }

    return AttendanceStats(
      present: present,
      lop: lop,
      halfDay: halfDay,
      absent: absent,
    );
  }

  List<String> getDayStatusList(int year, int month) {
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    List<String> dayStatuses = [];

    for (int i = 1; i <= daysInMonth; i++) {
      final dateKey = "$year-${month.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}";
      if (records.containsKey(dateKey)) {
        final record = records[dateKey]!;
        if (record.present) {
          dayStatuses.add("P");
        } else if (record.fn || record.an) {
          dayStatuses.add("H");
        } else {
          dayStatuses.add("A");
        }
      } else {
        dayStatuses.add("");
      }
    }

    return dayStatuses;
  }
}

class AttendanceRecord {
  final bool present;
  final bool fn; // First half
  final bool an; // Second half

  AttendanceRecord({
    required this.present,
    required this.fn,
    required this.an,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      present: map['present'] ?? false,
      fn: map['FN'] ?? false,
      an: map['AN'] ?? false,
    );
  }
}

class ShiftTiming {
  final dynamic session1Login;
  final dynamic session2Logout;

  ShiftTiming({
    required this.session1Login,
    required this.session2Logout,
  });

  factory ShiftTiming.fromMap(Map<String, dynamic> map) {
    return ShiftTiming(
      session1Login: map['session1Login'],
      session2Logout: map['session2Logout'],
    );
  }

  String formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = (timestamp as Timestamp).toDate();
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
  }
}

class AttendanceStats {
  final int present;
  final int lop;
  final int halfDay;
  final int absent;

  AttendanceStats({
    required this.present,
    required this.lop,
    required this.halfDay,
    required this.absent,
  });
}

class CsvReportData {
  final List<List<dynamic>> data;
  final int totalRows;
  final int skippedRecords;

  CsvReportData({
    required this.data,
    required this.totalRows,
    required this.skippedRecords,
  });

  bool get hasData => data.length > 1;
}