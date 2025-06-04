import 'package:flutter/material.dart';
import 'apply_leave_page.dart'; // Your existing Apply Leave page
import 'profile_summary_page.dart'; // Your existing Profile Summary page
import 'emergency_page.dart'; // Emergency Leave page
import 'pending_leave_request.dart'; // NEW: Pending Leave Request Page
import 'attendance_page.dart'; // Add this import
import 'attendance_overview.dart'; // ✅ Import the new attendance overview page

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_DashboardButton> dashboardButtons = [
      _DashboardButton(
        "Profile Summary",
        Icons.person_outline,
        const LinearGradient(
          colors: [Color(0xFF6A5ACD), Color(0xFF9370DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _DashboardButton(
        "Mark Present",
        Icons.check_circle_outline,
        const LinearGradient(
          colors: [Color(0xFF32CD32), Color(0xFF00FA9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _DashboardButton(
        "Apply Leave",
        Icons.event_note_outlined,
        const LinearGradient(
          colors: [Color(0xFF4169E1), Color(0xFF6495ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _DashboardButton(
        "Apply Emergency Leave",
        Icons.warning_amber_outlined,
        const LinearGradient(
          colors: [Color(0xFFFF6347), Color(0xFFFF7F50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _DashboardButton(
        "Pending Leave Requests",
        Icons.pending_actions_outlined,
        const LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _DashboardButton(
        "Leave Overview",
        Icons.view_list_outlined,
        const LinearGradient(
          colors: [Color(0xFF4B0082), Color(0xFF663399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _DashboardButton(
        "Attendance Overview",
        Icons.analytics_outlined,
        const LinearGradient(
          colors: [Color(0xFF20B2AA), Color(0xFF48D1CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _DashboardButton(
        "Notifications",
        Icons.notifications_outlined,
        const LinearGradient(
          colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _DashboardButton(
        "Calendar",
        Icons.calendar_today_outlined,
        const LinearGradient(
          colors: [Color(0xFF8A2BE2), Color(0xFFBA55D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFE9ECEF),
              Color(0xFFF1F3F4),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildCustomAppBar(),
              // Dashboard Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildDashboardGrid(dashboardButtons),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A5ACD), Color(0xFF9370DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Have a productive day',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.dashboard_customize,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid(List<_DashboardButton> dashboardButtons) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.1,
        ),
        itemCount: dashboardButtons.length,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 100)),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: _buildEnhancedDashboardButton(
                  context,
                  dashboardButtons[index],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEnhancedDashboardButton(
      BuildContext context, _DashboardButton item) {
    return GestureDetector(
      onTap: () => _handleButtonTap(context, item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: item.gradient,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: item.gradient.colors.first.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 10,
              offset: const Offset(-5, -5),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: () => _handleButtonTap(context, item),
            splashColor: Colors.white.withOpacity(0.3),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: 0.3,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleButtonTap(BuildContext context, _DashboardButton item) {
    // Add haptic feedback
    // HapticFeedback.lightImpact();

    if (item.title == "Apply Leave") {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ApplyLeavePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else if (item.title == "Profile Summary") {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ProfileSummaryPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else if (item.title == "Apply Emergency Leave") {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const EmergencyLeavePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(scale: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else if (item.title == "Pending Leave Requests") {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const PendingLeaveRequestPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else if (item.title == "Mark Present") {
      // Get empId from route arguments
      final String? empId =
          ModalRoute.of(context)?.settings.arguments as String?;
      if (empId != null) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                AttendancePage(empId: empId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } else if (item.title == "Attendance Overview") {
  final String? empId =
      ModalRoute.of(context)?.settings.arguments as String?;
  if (empId != null) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AttendanceOverviewScreen(empId: empId),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.3),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
} else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Navigating to ${item.title}..."),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: item.gradient.colors.first,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _DashboardButton {
  final String title;
  final IconData icon;
  final LinearGradient gradient;

  _DashboardButton(this.title, this.icon, this.gradient);
}