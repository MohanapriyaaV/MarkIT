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
          // Common refresh button for both tabs
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              // Get the current tab index
              final currentTab = _tabController.index;

              // We need to rebuild the entire tabbed view to refresh data
              setState(() {
                // This will trigger a rebuild of the tab views
              });

              // Show a snackbar to indicate refresh
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Refreshing ${currentTab == 0 ? 'pending approvals' : 'history'}...'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
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