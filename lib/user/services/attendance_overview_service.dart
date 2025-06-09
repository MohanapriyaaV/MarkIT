// services/attendance_overview_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/attendance_overview_model.dart';

class AttendanceOverviewService {
  static final _firestore = FirebaseFirestore.instance;

  /// Get comprehensive attendance overview data
  static Future<AttendanceOverviewData> getAttendanceOverview(String empId) async {
    try {
      final now = DateTime.now();
      final currentMonth = DateFormat('yyyy-MM').format(now);
      
      // Get attendance records
      final attendanceDoc = await _getAttendanceRecord(empId);
      if (attendanceDoc == null) {
        return _getEmptyOverviewData();
      }

      // Calculate current month statistics
      final currentMonthStats = await _getCurrentMonthStats(empId, now, attendanceDoc);
      
      // Get monthly trends (last 6 months)
      final monthlyTrends = await _getMonthlyTrends(empId, attendanceDoc);
      
      // Calculate month-over-month comparison
      final monthOverMonthChange = _calculateMonthOverMonthChange(monthlyTrends);
      
      // Get recent trends (current month days)
      final recentTrends = _getRecentTrends(attendanceDoc.records, now);
      
      // Find best and worst months
      final bestMonth = _getBestMonth(monthlyTrends);
      final worstMonth = _getWorstMonth(monthlyTrends);

      return AttendanceOverviewData(
        currentMonthRate: currentMonthStats['attendanceRate'],
        punctualityScore: currentMonthStats['punctualityScore'],
        earlyAttendanceCount: currentMonthStats['earlyAttendanceCount'],
        currentMonthAttendedDays: currentMonthStats['attendedDays'],
        currentMonthWorkingDays: currentMonthStats['workingDays'],
        monthlyTrends: monthlyTrends,
        bestMonth: bestMonth,
        worstMonth: worstMonth,
        recentTrends: recentTrends,
        monthOverMonthChange: monthOverMonthChange,
      );
    } catch (e) {
      throw Exception('Failed to get attendance overview: $e');
    }
  }

  /// Get attendance document for employee
  static Future<AttendanceDocument?> _getAttendanceRecord(String empId) async {
    try {
      final doc = await _firestore.collection('attendance').doc(empId).get();
      return doc.exists ? AttendanceDocument.fromMap(doc.data()!) : null;
    } catch (e) {
      throw Exception('Failed to fetch attendance record: $e');
    }
  }

  /// Calculate current month statistics
  static Future<Map<String, dynamic>> _getCurrentMonthStats(
    String empId,
    DateTime now,
    AttendanceDocument attendanceDoc,
  ) async {
    final currentMonth = DateFormat('yyyy-MM').format(now);
    
    // Get current month records
    final currentMonthRecords = attendanceDoc.records.entries
        .where((entry) => entry.key.startsWith(currentMonth))
        .toList();

    // Calculate attended days and sessions
    int attendedDays = 0;
    int earlyAttendanceCount = 0;
    int totalSessions = 0;

    for (final entry in currentMonthRecords) {
      final record = entry.value;
      final hasAttendance = record.fn || record.an;
      
      if (hasAttendance) {
        attendedDays++;
      }

      // Count sessions
      if (record.fn) totalSessions++;
      if (record.an) totalSessions++;

      // Check for early attendance (before 8:30 AM or has remark)
      if (record.fn && 
          ((record.fnTimestamp != null && _isEarlyAttendance(record.fnTimestamp!)) ||
           (record.fnRemark != null && record.fnRemark!.isNotEmpty))) {
        earlyAttendanceCount++;
      }
      
      if (record.an && 
          ((record.anTimestamp != null && _isEarlyAttendance(record.anTimestamp!)) ||
           (record.anRemark != null && record.anRemark!.isNotEmpty))) {
        earlyAttendanceCount++;
      }
    }

    final workingDays = _getWorkingDaysInMonth(now.year, now.month);
    final attendanceRate = workingDays > 0 ? (attendedDays / workingDays) * 100 : 0.0;
    final punctualityScore = totalSessions > 0 ? (earlyAttendanceCount / totalSessions) * 100 : 0.0;

    return {
      'attendanceRate': attendanceRate,
      'punctualityScore': punctualityScore,
      'earlyAttendanceCount': earlyAttendanceCount,
      'attendedDays': attendedDays,
      'workingDays': workingDays,
      'totalSessions': totalSessions,
    };
  }

  /// Get monthly trends for the last 6 months
  static Future<List<MonthlyTrend>> _getMonthlyTrends(
    String empId,
    AttendanceDocument attendanceDoc,
  ) async {
    final trends = <MonthlyTrend>[];
    final now = DateTime.now();
    
    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final monthStr = DateFormat('yyyy-MM').format(targetDate);
      final monthName = DateFormat('MMM yyyy').format(targetDate);
      
      // Get records for this month
      final monthRecords = attendanceDoc.records.entries
          .where((entry) => entry.key.startsWith(monthStr))
          .toList();

      int attendedDays = 0;
      int totalSessions = 0;

      for (final entry in monthRecords) {
        final record = entry.value;
        if (record.fn || record.an) {
          attendedDays++;
        }
        if (record.fn) totalSessions++;
        if (record.an) totalSessions++;
      }

      final workingDays = _getWorkingDaysInMonth(targetDate.year, targetDate.month);
      final attendanceRate = workingDays > 0 ? (attendedDays / workingDays) * 100 : 0.0;

      trends.add(MonthlyTrend(
        month: monthStr,
        monthName: monthName,
        attendanceRate: attendanceRate,
        totalAttendedDays: attendedDays,
        totalWorkingDays: workingDays,
        totalSessions: totalSessions,
      ));
    }
    
    return trends;
  }

  /// Calculate month-over-month change percentage
  static double _calculateMonthOverMonthChange(List<MonthlyTrend> trends) {
    if (trends.length < 2) return 0.0;
    
    final currentMonth = trends.last.attendanceRate;
    final previousMonth = trends[trends.length - 2].attendanceRate;
    
    if (previousMonth == 0) return 0.0;
    
    return ((currentMonth - previousMonth) / previousMonth) * 100;
  }

  /// Get recent attendance trends for current month
  static List<DailyAttendance> _getRecentTrends(
    Map<String, AttendanceRecord> records, 
    DateTime now,
  ) {
    final recentTrends = <DailyAttendance>[];
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final record = records[dateStr];
      
      final hasEarlyAttendance = record != null && (
        (record.fn && 
         ((record.fnTimestamp != null && _isEarlyAttendance(record.fnTimestamp!)) ||
          (record.fnRemark != null && record.fnRemark!.isNotEmpty))) ||
        (record.an && 
         ((record.anTimestamp != null && _isEarlyAttendance(record.anTimestamp!)) ||
          (record.anRemark != null && record.anRemark!.isNotEmpty)))
      );

      recentTrends.add(DailyAttendance(
        date: dateStr,
        fnAttended: record?.fn ?? false,
        anAttended: record?.an ?? false,
        hasEarlyAttendance: hasEarlyAttendance,
        fnRemark: record?.fnRemark,
        anRemark: record?.anRemark,
        fnTimestamp: record?.fnTimestamp,
        anTimestamp: record?.anTimestamp,
      ));
    }
    
    return recentTrends;
  }

  /// Get working days in a month (excluding Sundays)
  static int _getWorkingDaysInMonth(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    int workingDays = 0;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (date.weekday != DateTime.sunday) {
        workingDays++;
      }
    }
    
    return workingDays;
  }

  /// Check if attendance is early (before 8:30 AM)
  static bool _isEarlyAttendance(DateTime timestamp) {
    final earlyThreshold = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
      8,
      30,
    );
    return timestamp.isBefore(earlyThreshold);
  }

  /// Find the best performing month
  static MonthlyTrend? _getBestMonth(List<MonthlyTrend> trends) {
    if (trends.isEmpty) return null;
    
    return trends.reduce((a, b) {
      return a.attendanceRate > b.attendanceRate ? a : b;
    });
  }

  /// Find the worst performing month
  static MonthlyTrend? _getWorstMonth(List<MonthlyTrend> trends) {
    if (trends.isEmpty) return null;
    
    return trends.reduce((a, b) {
      return a.attendanceRate < b.attendanceRate ? a : b;
    });
  }

  /// Get empty overview data when no records exist
  static AttendanceOverviewData _getEmptyOverviewData() {
    return AttendanceOverviewData(
      currentMonthRate: 0.0,
      punctualityScore: 0.0,
      earlyAttendanceCount: 0,
      currentMonthAttendedDays: 0,
      currentMonthWorkingDays: 0,
      monthlyTrends: [],
      bestMonth: null,
      worstMonth: null,
      recentTrends: [],
      monthOverMonthChange: 0.0,
    );
  }

  /// Update monthly summary with proper session counting
  static Future<void> updateMonthlySummary(String empId, String month) async {
    try {
      final q = await _firestore
          .collection('monthly_attendance_summaries')
          .where('empId', isEqualTo: empId)
          .where('month', isEqualTo: month)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        await q.docs.first.reference.update({
          'count': FieldValue.increment(1)
        });
      } else {
        await _firestore.collection('monthly_attendance_summaries').add({
          'empId': empId,
          'month': month,
          'count': 1,
        });
      }
    } catch (e) {
      throw Exception('Failed to update monthly summary: $e');
    }
  }

  /// Get monthly summary data
  static Future<Map<String, dynamic>?> getMonthlySummary(String empId, String month) async {
    try {
      final q = await _firestore
          .collection('monthly_attendance_summaries')
          .where('empId', isEqualTo: empId)
          .where('month', isEqualTo: month)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        return q.docs.first.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get monthly summary: $e');
    }
  }
}