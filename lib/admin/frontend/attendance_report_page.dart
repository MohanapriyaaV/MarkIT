import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceReportPage extends StatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  bool _isLoading = false;
  DateTime _selectedMonth = DateTime.now();
  List<List<dynamic>> _latestCsvData = [];

  Future<List<List<dynamic>>> generateCsvData() async {
    print("📤 Generating attendance report for: ${DateFormat('MMMM yyyy').format(_selectedMonth)}");
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);

    final attendanceDocs = await FirebaseFirestore.instance.collection('attendance').get();
    print("📊 Total attendance documents fetched: ${attendanceDocs.docs.length}");

    List<String> dateHeaders = List.generate(daysInMonth, (i) {
      final d = DateTime(year, month, i + 1);
      return "${d.day.toString().padLeft(2, '0')} ${_monthShort(d.month)}";
    });

    List<List<dynamic>> csvData = [
      [
        "S.No", "Employee No", "Name", "Mob No", "DOJ", "Designation", "Project",
        "Shift", "Counselor", ...dateHeaders, "Present", "LOP", "Half Day", "Absent"
      ]
    ];

    int serial = 1;
    int skippedRecords = 0;

    for (var doc in attendanceDocs.docs) {
      final data = doc.data();
      final empId = data['empId'];
      print("🔍 Processing empId: $empId");

      if (empId == null) {
        print("⚠️ Skipped: empId is null");
        skippedRecords++;
        continue;
      }

      final empSnapshot = await FirebaseFirestore.instance
          .collection('employeeInfo')
          .where('empId', isEqualTo: empId)
          .limit(1)
          .get();

      if (empSnapshot.docs.isEmpty) {
        print("❌ No employee data found for empId: $empId");
        skippedRecords++;
        continue;
      }

      final empData = empSnapshot.docs.first.data();
      final records = Map<String, dynamic>.from(data['records'] ?? {});

      final session1 = empData['shiftTiming']?['session1Login'];
      final session2 = empData['shiftTiming']?['session2Logout'];
      final shift = (session1 != null && session2 != null)
          ? "${_formatTime(session1)} - ${_formatTime(session2)}"
          : '';

      List<dynamic> row = [
        serial++,
        empData['empId'] ?? '',
        empData['name'] ?? '',
        empData['phoneNumber'] ?? '',
        empData['JoiningDate'] ?? '',
        empData['role'] ?? '',
        empData['teamId'] ?? '',
        shift,
        empData['Manager'] ?? '',
      ];

      int present = 0, lop = 0, halfDay = 0, absent = 0;

      for (int i = 1; i <= daysInMonth; i++) {
        final dateKey = "$year-${month.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}";
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
      print("✅ Added data row for: ${empData['name']}");
    }

    print("✅ Report rows: ${csvData.length - 1}, Skipped: $skippedRecords");
    return csvData;
  }

  Future<void> exportAndSendReport() async {
    setState(() => _isLoading = true);

    try {
      final csvData = await generateCsvData();
      if (csvData.length <= 1) {
        print("⚠️ No attendance rows added to the report.");
        setState(() => _isLoading = false);
        return;
      }

      final formattedMonth = DateFormat('MMMM_yyyy').format(_selectedMonth);
      final fileName = 'attendance_report_$formattedMonth.csv';

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(const ListToCsvConverter().convert(csvData));
      print("📁 CSV written to: $filePath");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final smtpServer = gmail('mohanapriya7114@gmail.com', 'nojkjrqhocqqoimk');
      final message = Message()
        ..from = Address('mohanapriya7114@gmail.com', 'MarkIT System')
        ..recipients.add(user.email!)
        ..subject = 'Attendance Report – ${DateFormat('MMMM yyyy').format(_selectedMonth)}'
        ..text = 'Hi,\n\nPlease find attached the attendance report for ${DateFormat('MMMM yyyy').format(_selectedMonth)}.\n\nRegards,\nMarkIT System'
        ..attachments = [FileAttachment(file)];

      await send(message, smtpServer);
      print("📨 Email sent to ${user.email}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("📧 Report sent to ${user.email}")),
        );
      }
    } catch (e, stack) {
      print("❌ Email sending failed: $e");
      print("📛 Stacktrace: $stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to send report.")),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void previewReport() async {
    setState(() => _isLoading = true);
    _latestCsvData = await generateCsvData();
    setState(() => _isLoading = false);

    if (_latestCsvData.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ No data to preview.")),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Preview Report")),
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: _latestCsvData.first.map((e) => DataColumn(label: Text(e.toString()))).toList(),
              rows: _latestCsvData.skip(1).map((row) {
                return DataRow(
                  cells: row.map((e) => DataCell(Text(e.toString()))).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = (timestamp as Timestamp).toDate();
      return DateFormat('hh:mm a').format(date);
    } catch (_) {
      return '';
    }
  }

  String _monthShort(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      helpText: 'Select Month and Year',
      fieldHintText: 'Month/Year',
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    }
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
                Text(
                  'Selected: ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _pickMonth,
                  child: const Text('Pick Month'),
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Processing...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.preview),
                            label: const Text("Preview Report"),
                            onPressed: previewReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFDC143C),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
