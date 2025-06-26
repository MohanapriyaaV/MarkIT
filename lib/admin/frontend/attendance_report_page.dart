import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceReportPage extends StatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  bool _isLoading = false;

  Future<void> exportAndSendReport() async {
    setState(() => _isLoading = true);

    try {
      // Step 1: Prepare CSV
      final attendanceDocs = await FirebaseFirestore.instance.collection('attendance').get();

      List<String> dateHeaders = List.generate(30, (i) {
        final d = DateTime(2025, 6, i + 1);
        return "${d.day.toString().padLeft(2, '0')} ${_monthShort(d.month)}";
      });

      List<List<dynamic>> csvData = [
        [
          "S.No", "Project", "Shift", "Employee No", "Mob No", "Counselor", "Name",
          "DOJ", "Designation", "Floor", "Status", ...dateHeaders,
          "Present", "LOP", "Half Day", "Absent"
        ]
      ];

      int serial = 1;

      for (var doc in attendanceDocs.docs) {
        final data = doc.data();
        final empId = data['empId'];
        final records = Map<String, dynamic>.from(data['records'] ?? {});

        final empSnapshot = await FirebaseFirestore.instance.collection('employeeInfo').doc(empId).get();
        final empData = empSnapshot.data();
        if (empData == null) continue;

        List<dynamic> row = [
          serial++,
          empData['department'] ?? '',
          empData['shiftTiming']?['session1Login'] != null ? "Day" : '',
          empData['userId'] ?? '',
          empData['phoneNumber'] ?? '',
          empData['Manager'] ?? '',
          empData['name'] ?? '',
          empData['JoiningDate'] ?? '',
          empData['role'] ?? '',
          empData['location'] ?? '',
          'Active',
        ];

        int present = 0, lop = 0, halfDay = 0, absent = 0;

        for (int i = 1; i <= 30; i++) {
          final dateKey = "2025-06-${i.toString().padLeft(2, '0')}";
          if (records.containsKey(dateKey)) {
            final r = records[dateKey];
            if (r['present'] == true) {
              row.add("P");
              present++;
            } else if (r['FN'] == true || r['AN'] == true) {
              row.add("H");
              halfDay++;
            } else {
              row.add("A");
              absent++;
            }
          } else {
            row.add("");
          }
        }

        row.addAll([present, lop, halfDay, absent]);
        csvData.add(row);
      }

      // Step 2: Save locally
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/attendance_report_june_2025.csv';
      final file = File(filePath);
      await file.writeAsString(const ListToCsvConverter().convert(csvData));

      // Step 3: Send Email
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final smtpServer = gmail('mohanapriya7114@gmail.com', 'nojkjrqhocqqoimk'); // replace with your email and app password
      final message = Message()
        ..from = Address('your.email@gmail.com', 'MarkIT System')
        ..recipients.add(user.email!)
        ..subject = 'Attendance Report – June 2025'
        ..text = 'Hi,\n\nPlease find attached the attendance report for June 2025.\n\nRegards,\nMarkIT System'
        ..attachments = [FileAttachment(file)];

      await send(message, smtpServer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("📧 Report sent to ${user.email}")),
        );
      }
    } catch (e) {
      print("❌ Email sending failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to send report.")),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  String _monthShort(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Attendance Report"),
        backgroundColor: const Color(0xFFDC143C),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDC143C), Color(0xFFB22222)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.email, size: 64, color: Colors.white),
                      const SizedBox(height: 20),
                      const Text(
                        'Send Attendance Report via Email',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const Column(
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Sending...',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            )
                          : ElevatedButton.icon(
                              icon: const Icon(Icons.send),
                              label: const Text("Send Report"),
                              onPressed: exportAndSendReport,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFDC143C),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
