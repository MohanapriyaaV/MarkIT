import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AttendanceOverviewPage extends StatelessWidget {
  final String empId;

  const AttendanceOverviewPage({super.key, required this.empId});

  Future<Map<String, dynamic>> _fetchAttendanceData() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

    final totalAttendanceSnapshot =
        await firestore
            .collection('attendance')
            .where('empId', isEqualTo: empId)
            .get();
    final totalPresentDays = totalAttendanceSnapshot.docs.length;

    final monthlySummarySnapshot =
        await firestore
            .collection('monthly_attendance_summaries')
            .where('empId', isEqualTo: empId)
            .where('month', isEqualTo: currentMonth)
            .limit(1)
            .get();

    final monthlyPresentDays =
        monthlySummarySnapshot.docs.isNotEmpty
            ? monthlySummarySnapshot.docs.first['count'] ?? 0
            : 0;

    return {
      'totalPresentDays': totalPresentDays,
      'monthlyPresentDays': monthlyPresentDays,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[50],
      appBar: AppBar(
        title: const Text('Attendance Overview'),
        backgroundColor: Colors.purple[700],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAttendanceData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final now = DateTime.now();
          final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Attendance Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildAttendancePieChart(
                        title:
                            'Monthly Attendance\n(${DateFormat('MMMM yyyy').format(now)})',
                        presentDays: data['monthlyPresentDays'],
                        totalDays: lastDayOfMonth,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildAttendancePieChart(
                        title: 'Total Attendance\n(Year)',
                        presentDays: data['totalPresentDays'],
                        totalDays: 365,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  'Current Month: ${data['monthlyPresentDays']} days present',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Total Present Days: ${data['totalPresentDays']} days',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttendancePieChart({
    required String title,
    required int presentDays,
    required int totalDays,
  }) {
    final absentDays = totalDays - presentDays;
    final presentPercentage = (presentDays / totalDays) * 100;
    final absentPercentage = (absentDays / totalDays) * 100;

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.purple[700],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 1.2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: presentDays.toDouble(),
                  title:
                      '$presentDays\n(${presentPercentage.toStringAsFixed(1)}%)',
                  color: Colors.green,
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  titlePositionPercentageOffset: 0.6,
                ),
                PieChartSectionData(
                  value: absentDays.toDouble(),
                  title:
                      '$absentDays\n(${absentPercentage.toStringAsFixed(1)}%)',
                  color: Colors.red,
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  titlePositionPercentageOffset: 0.6,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
