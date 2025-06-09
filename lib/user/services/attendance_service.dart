import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Employee?> fetchEmployeeData(String empId) async {
    try {
      final snap = await _firestore.collection('employeeInfo').doc(empId).get();
      if (snap.exists && snap.data() != null) {
        return Employee.fromMap(snap.data()!, empId);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch employee data: $e');
    }
  }

  AttendanceEligibility checkEligibility() {
    final now = DateTime.now();
    final isSunday = now.weekday == DateTime.sunday;

    // Define attendance time windows - Updated according to requirements
    final fnStart = DateTime(now.year, now.month, now.day, 7, 0);   // 7:00 AM
    final fnEnd = DateTime(now.year, now.month, now.day, 9, 5);     // 9:05 AM
    final anStart = DateTime(now.year, now.month, now.day, 12, 0);  // 12:00 PM
    final anEnd = DateTime(now.year, now.month, now.day, 13, 5);    // 1:05 PM

    // Early attendance threshold (before 8:30 AM)
    final earlyThreshold = DateTime(now.year, now.month, now.day, 8, 30);

    String? session;
    bool isEarly = false;
    bool isLateFN = false;
    bool isTooLate = false;
    String? lateMessage;
    Duration? timeRemaining;
    bool isEligibleTime = false;

    if (now.isBefore(fnStart)) {
      // Too early for any session
      session = 'FN';
      timeRemaining = fnStart.difference(now);
      isEligibleTime = false;
      lateMessage = "⏰ Attendance starts at 7:00 AM. Please wait.";
    } else if (now.isBefore(fnEnd)) {
      // FN session window (7:00 AM - 9:05 AM)
      session = 'FN';
      isEligibleTime = true;
      timeRemaining = fnEnd.difference(now);
      
      if (now.isBefore(earlyThreshold)) {
        isEarly = true;
      }
    } else if (now.isBefore(anStart)) {
      // Between FN end and AN start - Late for FN
      session = 'FN';
      isEligibleTime = false;
      isLateFN = true;
      lateMessage = "⏰ FN session ended (9:05 AM). Please mark attendance for AF session before 1:05 PM.";
    } else if (now.isBefore(anEnd)) {
      // AN session window (12:00 PM - 1:05 PM)
      session = 'AN';
      isEligibleTime = true;
      timeRemaining = anEnd.difference(now);
    } else {
      // Too late for any session
      session = 'AN';
      isTooLate = true;
      isEligibleTime = false;
      lateMessage = "⏰ AF session ended (1:05 PM). Please mark attendance tomorrow before 9:05 AM.";
    }

    return AttendanceEligibility(
      isSunday: isSunday,
      isEligibleTime: isEligibleTime,
      session: session,
      isEarly: isEarly,
      isLateFN: isLateFN,
      isTooLate: isTooLate,
      lateMessage: lateMessage,
      timeRemaining: timeRemaining,
    );
  }

  Future<String> markAttendance(String empId, String? remark) async {
    try {
      final uid = empId.trim();
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final month = DateFormat('yyyy-MM').format(now);

      final eligibility = checkEligibility();

      if (eligibility.isSunday) {
        return "🌅 Today is Sunday. No attendance required.";
      }

      if (!eligibility.isEligibleTime) {
        return eligibility.lateMessage ?? "⏰ Attendance window is closed.";
      }

      final session = eligibility.session ?? 'FN';
      String statusMessage = '';

      // Check if attendance already marked for this session today
      final existingRecord = await getAttendanceRecord(uid);
      if (existingRecord != null && existingRecord.records.containsKey(today)) {
        final todayRecord = existingRecord.records[today]!;
        if ((session == 'FN' && todayRecord.fn) || (session == 'AN' && todayRecord.an)) {
          return "✅ Attendance already marked for $session session today!";
        }
      }

      final docRef = _firestore.collection('attendance').doc(uid);
      final rec = {
        'timestamp': now,
        'remark': remark ?? '',
        session: true,
      };

      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final records = Map<String, dynamic>.from(data['records'] ?? {});
        final day = Map<String, dynamic>.from(records[today] ?? {});
        day.addAll(rec);
        records[today] = day;
        await docRef.update({'records': records});
      } else {
        await docRef.set({
          'empId': uid,
          'records': {today: rec},
        });
      }

      await _updateMonthlySummary(uid, month);

      if (eligibility.isEarly) {
        statusMessage = "✅ Early attendance marked for $session session!";
        if (remark != null && remark.isNotEmpty) {
          statusMessage += " Reason: $remark";
        }
      } else {
        statusMessage = "✅ Attendance marked for $session session!";
      }

      if (eligibility.timeRemaining != null && eligibility.isEligibleTime) {
        final hours = eligibility.timeRemaining!.inHours;
        final minutes = eligibility.timeRemaining!.inMinutes % 60;
        if (hours > 0) {
          statusMessage += " ⏳ Time remaining: ${hours}h ${minutes}m";
        } else {
          statusMessage += " ⏳ Time remaining: ${minutes}m";
        }
      }

      return statusMessage;
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  Future<void> _updateMonthlySummary(String empId, String month) async {
    try {
      final q = await _firestore
          .collection('monthly_attendance_summaries')
          .where('empId', isEqualTo: empId)
          .where('month', isEqualTo: month)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        await q.docs.first.reference.update({'count': FieldValue.increment(1)});
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

  Future<AttendanceDocument?> getAttendanceRecord(String empId) async {
    try {
      final doc = await _firestore.collection('attendance').doc(empId).get();
      if (doc.exists && doc.data() != null) {
        return AttendanceDocument.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch attendance record: $e');
    }
  }

  Future<List<MonthlySummary>> getMonthlySummaries(String empId) async {
    try {
      final q = await _firestore
          .collection('monthly_attendance_summaries')
          .where('empId', isEqualTo: empId)
          .get();

      return q.docs.map((doc) => MonthlySummary.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to fetch monthly summaries: $e');
    }
  }
} 