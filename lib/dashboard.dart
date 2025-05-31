import 'package:flutter/material.dart';
import 'apply_leave_page.dart'; // Your existing Apply Leave page
import 'profile_summary_page.dart'; // Your existing Profile Summary page
import 'emergency_page.dart'; // Emergency Leave page
import 'pending_leave_request.dart'; // NEW: Pending Leave Request Page
import 'attendance_page.dart'; // Add this import
import 'attendance_overview.dart'; // ✅ Import the new attendance overview page

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_DashboardButton> dashboardButtons = [
      _DashboardButton("Profile Summary", Icons.person, Colors.purple),
      _DashboardButton("Mark Present", Icons.check_circle, Colors.green),
      _DashboardButton("Apply Leave", Icons.edit_calendar, Colors.blue),
      _DashboardButton(
        "Apply Emergency Leave",
        Icons.warning_amber,
        Colors.redAccent,
      ),
      _DashboardButton(
        "Pending Leave Requests",
        Icons.pending_actions,
        Colors.orange,
      ),
      _DashboardButton("Leave Overview", Icons.view_list, Colors.indigo),
      _DashboardButton("Attendance Overview", Icons.analytics, Colors.teal),
      _DashboardButton("Notifications", Icons.notifications, Colors.pink),
      _DashboardButton("Calendar", Icons.calendar_today, Colors.deepPurple),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xffEBD8FF),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: dashboardButtons.length,
                  itemBuilder: (context, index) {
                    final item = dashboardButtons[index];
                    return _buildDashboardButton(context, item);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardButton(BuildContext context, _DashboardButton item) {
    return GestureDetector(
      onTap: () {
        if (item.title == "Apply Leave") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ApplyLeavePage()),
          );
        } else if (item.title == "Profile Summary") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileSummaryPage()),
          );
        } else if (item.title == "Apply Emergency Leave") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EmergencyLeavePage()),
          );
        } else if (item.title == "Pending Leave Requests") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PendingLeaveRequestPage(),
            ),
          );
        } else if (item.title == "Mark Present") {
          // Get empId from route arguments
          final String? empId =
              ModalRoute.of(context)?.settings.arguments as String?;
          if (empId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AttendancePage(empId: empId),
              ),
            );
          }
        } else if (item.title == "Attendance Overview") {
          final String? empId =
              ModalRoute.of(context)?.settings.arguments as String?;
          if (empId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AttendanceOverviewPage(empId: empId),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Navigating to ${item.title}...")),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 40, color: item.color),
            const SizedBox(height: 12),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: item.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardButton {
  final String title;
  final IconData icon;
  final Color color;

  _DashboardButton(this.title, this.icon, this.color);
}
