// attendance_report_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/attendance_report_model.dart';

class AttendanceReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _senderEmail = 'vistaesglobal@gmail.com';
  static const String _senderPassword = 'vtoqyklrxhewjfha';
  static const String _senderName = 'MarkIT System';

  Future<CsvReportData> generateCsvData(DateTime selectedMonth) async {
    print("📤 Generating attendance report for: ${DateFormat('MMMM yyyy').format(selectedMonth)}");
    
    final year = selectedMonth.year;
    final month = selectedMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);

    // Generate date headers
    List<String> dateHeaders = List.generate(daysInMonth, (i) {
      final d = DateTime(year, month, i + 1);
      return "${d.day.toString().padLeft(2, '0')} ${_getMonthShort(d.month)}";
    });

    // Create CSV headers
    List<List<dynamic>> csvData = [
      [
        "S.No", "Employee No", "Name", "Mob No", "DOJ", "Designation", "Project",
        "Shift", "Counselor", ...dateHeaders, "Present", "LOP", "Half Day", "Absent"
      ]
    ];

    // Fetch attendance data
    final attendanceReports = await _fetchAttendanceReports();
    print("📊 Total attendance documents fetched: ${attendanceReports.length}");

    int serial = 1;
    int skippedRecords = 0;

    for (var report in attendanceReports) {
      if (report == null) {
        skippedRecords++;
        continue;
      }

      // Calculate attendance stats
      final stats = report.calculateStats(year, month);
      final dayStatuses = report.getDayStatusList(year, month);

      // Create CSV row
      List<dynamic> row = [
        serial++,
        report.empId,
        report.name,
        report.phoneNumber,
        report.joiningDate,
        report.role,
        report.teamId,
        report.formattedShift,
        report.manager,
        ...dayStatuses,
        stats.present,
        stats.lop,
        stats.halfDay,
        stats.absent,
      ];

      csvData.add(row);
      print("✅ Added data row for: ${report.name}");
    }

    print("✅ Report rows: ${csvData.length - 1}, Skipped: $skippedRecords");
    
    return CsvReportData(
      data: csvData,
      totalRows: csvData.length - 1,
      skippedRecords: skippedRecords,
    );
  }

  Future<List<AttendanceReportModel?>> _fetchAttendanceReports() async {
    final attendanceDocs = await _firestore.collection('attendance').get();
    List<AttendanceReportModel?> reports = [];

    for (var doc in attendanceDocs.docs) {
      final attendanceData = doc.data();
      final empId = attendanceData['empId'];
      
      print("🔍 Processing empId: $empId");

      if (empId == null) {
        print("⚠️ Skipped: empId is null");
        reports.add(null);
        continue;
      }

      // Fetch employee data
      final empSnapshot = await _firestore
          .collection('employeeInfo')
          .where('empId', isEqualTo: empId)
          .limit(1)
          .get();

      if (empSnapshot.docs.isEmpty) {
        print("❌ No employee data found for empId: $empId");
        reports.add(null);
        continue;
      }

      final employeeData = empSnapshot.docs.first.data();
      
      // Create model
      final report = AttendanceReportModel.fromFirestore(
        employeeData: employeeData,
        attendanceData: attendanceData,
      );

      reports.add(report);
    }

    return reports;
  }

  Future<File> _createCsvFile(CsvReportData csvData, DateTime selectedMonth) async {
    final formattedMonth = DateFormat('MMMM_yyyy').format(selectedMonth);
    final fileName = 'attendance_report_$formattedMonth.csv';

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    
    await file.writeAsString(const ListToCsvConverter().convert(csvData.data));
    print("📁 CSV written to: $filePath");
    
    return file;
  }

  Future<void> sendReportByEmail(CsvReportData csvData, DateTime selectedMonth) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    if (!csvData.hasData) {
      throw Exception("No data to send");
    }

    // Create CSV file
    final csvFile = await _createCsvFile(csvData, selectedMonth);

    // Setup email
    final smtpServer = gmail(_senderEmail, _senderPassword);
    final message = Message()
      ..from = Address(_senderEmail, _senderName)
      ..recipients.add(user.email!)
      ..subject = 'Attendance Report – ${DateFormat('MMMM yyyy').format(selectedMonth)}'
      ..text = _getEmailBody(selectedMonth)
      ..attachments = [FileAttachment(csvFile)];

    // Send email
    await send(message, smtpServer);
    print("📨 Email sent to ${user.email}");
  }

  Future<File> exportCsvFile(CsvReportData csvData, DateTime selectedMonth) async {
    if (!csvData.hasData) {
      throw Exception("No data to export");
    }

    return await _createCsvFile(csvData, selectedMonth);
  }

  String _getEmailBody(DateTime selectedMonth) {
    return '''Hi,

Please find attached the attendance report for ${DateFormat('MMMM yyyy').format(selectedMonth)}.

Regards,
MarkIT System''';
  }

  String _getMonthShort(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}