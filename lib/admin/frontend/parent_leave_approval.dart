import 'package:flutter/material.dart';
// Import your existing pages
import 'leave_approvals_page.dart'; // Your first file
import 'approved_rejected_leavea_page.dart'; // Your second file

class TabbedLeaveApprovalsPage extends StatefulWidget {
  const TabbedLeaveApprovalsPage({super.key});

  @override
  State<TabbedLeaveApprovalsPage> createState() => _TabbedLeaveApprovalsPageState();
}

class _TabbedLeaveApprovalsPageState extends State<TabbedLeaveApprovalsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Approvals'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Removed refresh button as data updates in real-time from Firestore
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'Pending Approvals',
              icon: Icon(Icons.pending_actions),
            ),
            Tab(
              text: 'History',
              icon: Icon(Icons.history),
            ),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          LeaveApprovalsPage(),
          ApprovedRejectedLeavesPage(),
        ],
      ),
    );
  }
}