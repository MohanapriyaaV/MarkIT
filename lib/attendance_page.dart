import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  final String empId; // Firebase UID

  const AttendancePage({super.key, required this.empId});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool _attendanceMarked = false;
  String _statusMessage = "";
  String? _employeeName; // Will hold the fetched name

  @override
  void initState() {
    super.initState();
    fetchEmployeeName();
  }

  Future<void> fetchEmployeeName() async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('employeeInfo')
              .doc(widget.empId)
              .get();

      if (docSnapshot.exists) {
        setState(() {
          _employeeName = docSnapshot.data()?['name'] ?? 'Employee';
        });
      } else {
        setState(() {
          _employeeName = 'Employee';
        });
      }
    } catch (e) {
      print('Error fetching employee name: $e');
      setState(() {
        _employeeName = 'Employee';
      });
    }
  }

  Future<void> markAttendance() async {
    print('markAttendance function called');

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String userUID = widget.empId.trim();
    final DateTime now = DateTime.now();
    final String today = DateFormat('yyyy-MM-dd').format(now);
    final String currentMonth = DateFormat('yyyy-MM').format(now);

    try {
      final docRef = firestore.collection('attendance').doc(userUID);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;

        if (data.containsKey('records') &&
            data['records'] is Map<String, dynamic>) {
          final records = Map<String, dynamic>.from(data['records']);
          if (records.containsKey(today)) {
            setState(() {
              _attendanceMarked = true;
              _statusMessage = "Attendance already marked today.";
            });
            print("Attendance already marked in existing document.");
            return;
          } else {
            records[today] = {'present': true, 'timestamp': now};
            await docRef.update({'records': records});
          }
        } else {
          await docRef.update({
            'records': {
              today: {'present': true, 'timestamp': now},
            },
          });
        }
        print("Updated existing attendance document.");
      } else {
        await docRef.set({
          'empId': userUID,
          'records': {
            today: {'present': true, 'timestamp': now},
          },
        });
        print("Created new attendance document with userUID as doc ID.");
      }

      // Monthly summary logic
      final monthlySummaryQuery = firestore
          .collection('monthly_attendance_summaries')
          .where('empId', isEqualTo: userUID)
          .where('month', isEqualTo: currentMonth)
          .limit(1);
      final monthlySummarySnapshot = await monthlySummaryQuery.get();

      if (monthlySummarySnapshot.docs.isNotEmpty) {
        await monthlySummarySnapshot.docs.first.reference.update({
          'count': FieldValue.increment(1),
        });
        print("Monthly summary updated.");
      } else {
        await firestore.collection('monthly_attendance_summaries').add({
          'empId': userUID,
          'month': currentMonth,
          'count': 1,
        });
        print("Created new monthly summary.");
      }

      setState(() {
        _attendanceMarked = true;
        _statusMessage = "Attendance marked successfully!";
      });

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: userUID,
        );
      });
    } catch (e) {
      setState(() {
        print('Error marking attendance: $e');
        _statusMessage = "Error marking attendance: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color purple = const Color(0xFF6A1B9A);

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(
        backgroundColor: purple,
        title: const Text("Mark Attendance"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Welcome, ${_employeeName ?? '...'}",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: purple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Today: ${DateFormat.yMMMMd().format(DateTime.now())}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  if (!_attendanceMarked)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: markAttendance,
                      child: const Text(
                        "Mark as Present",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  if (_attendanceMarked)
                    Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _statusMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
