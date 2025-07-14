import 'package:flutter/material.dart';
import 'attendance_report_page.dart';
import 'team_list_page.dart';
import 'parent_leave_approval.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const AdminDashboard({super.key, this.userData});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _gradientController;
  late AnimationController _shimmerController;
  late AnimationController _waveController;
  late AnimationController _breatheController;
  late AnimationController _floatController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _gradientAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _breatheAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _gradientController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _breatheController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );
    
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
    
    _breatheAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    
    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
    _gradientController.repeat(reverse: true);
    _shimmerController.repeat();
    _waveController.repeat();
    _breatheController.repeat(reverse: true);
    _floatController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _gradientController.dispose();
    _shimmerController.dispose();
    _waveController.dispose();
    _breatheController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: AnimatedBuilder(
        animation: Listenable.merge([_gradientController, _waveController]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFFF8FAFB), const Color(0xFFECFDF5), _gradientAnimation.value)!,
                  Color.lerp(const Color(0xFFECFDF5), const Color(0xFFF0FDFA), _gradientAnimation.value)!,
                  Color.lerp(const Color(0xFFF0FDFA), const Color(0xFFE6FFFA), _gradientAnimation.value)!,
                  Color.lerp(const Color(0xFFE6FFFA), const Color(0xFFF8FAFB), _gradientAnimation.value)!,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
                transform: GradientRotation(_waveAnimation.value * 0.1),
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildAdminAppBar(),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: _buildAdminContent(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminAppBar() {
    String adminName = "Admin";
    String adminRole = "Administrator";

    if (widget.userData != null) {
      adminName = widget.userData!['name'] ?? 'Admin';
      adminRole = widget.userData!['role'] ?? 'Administrator';
    }

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value * 0.5),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0F766E),
                  Color(0xFF0D9488),
                  Color(0xFF14B8A6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFF14B8A6).withOpacity(0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _breatheController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _breatheAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              return ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: const [
                                      Colors.white,
                                      Color(0xFFB2F5EA),
                                      Colors.white,
                                    ],
                                    stops: [
                                      (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
                                      _shimmerAnimation.value.clamp(0.0, 1.0),
                                      (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'Admin Dashboard',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Welcome back, $adminName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationController.value * 6.283,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminContent() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatsSection(),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value * 0.02 + 0.98,
                child: Text(
                  'Admin Functions',
                  style: TextStyle(
                    color: const Color(0xFF0F766E),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildAdminFunctionsGrid(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: AnimatedBuilder(
                  animation: _floatController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnimation.value * 0.3),
                      child: _buildStatCard(
                        title: 'Total Users',
                        value: '125',
                        icon: Icons.people_outline,
                        gradientColors: [const Color(0xFF0F766E), const Color(0xFF0D9488)],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: AnimatedBuilder(
                  animation: _floatController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -_floatAnimation.value * 0.3),
                      child: _buildStatCard(
                        title: 'Pending Requests',
                        value: '8',
                        icon: Icons.pending_actions_outlined,
                        gradientColors: [const Color(0xFF14B8A6), const Color(0xFF06B6D4)],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return AnimatedBuilder(
      animation: _breatheController,
      builder: (context, child) {
        return Transform.scale(
          scale: _breatheAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: gradientColors[1].withOpacity(0.2),
                  blurRadius: 28,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value * 0.05 + 0.95,
                          child: Text(
                            value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminFunctionsGrid() {
    final adminFunctions = [
      {
        'title': 'User Management',
        'icon': Icons.people_outline,
        'gradientColors': [const Color(0xFF0F766E), const Color(0xFF0D9488)],
        'description': 'Manage user accounts',
      },
      {
        'title': 'Leave Approvals',
        'icon': Icons.approval_outlined,
        'gradientColors': [const Color(0xFF14B8A6), const Color(0xFF06B6D4)],
        'description': 'Approve/reject leave requests',
      },
      {
        'title': 'Attendance Reports',
        'icon': Icons.analytics_outlined,
        'gradientColors': [const Color(0xFF0891B2), const Color(0xFF0E7490)],
        'description': 'View attendance analytics',
      },
      {
        'title': 'Admin Notifications',
        'icon': Icons.notifications_active_outlined,
        'gradientColors': [const Color(0xFF0F766E), const Color(0xFF115E59)],
        'description': 'Manage admin notifications',
      },
      {
        'title': 'Holiday Calendar',
        'icon': Icons.calendar_today_outlined,
        'gradientColors': [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
        'description': 'Manage holidays',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.95,
      ),
      itemCount: adminFunctions.length,
      itemBuilder: (context, index) {
        final function = adminFunctions[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 900 + (index * 150)),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      (index.isEven ? 1 : -1) * _floatAnimation.value * 0.2,
                      _floatAnimation.value * 0.3,
                    ),
                    child: _buildAdminFunctionCard(
                      title: function['title'] as String,
                      icon: function['icon'] as IconData,
                      gradientColors: function['gradientColors'] as List<Color>,
                      description: function['description'] as String,
                      index: index,
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminFunctionCard({
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required String description,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: _breatheController,
      builder: (context, child) {
        return Transform.scale(
          scale: _breatheAnimation.value * 0.01 + 0.99,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: gradientColors[1].withOpacity(0.2),
                  blurRadius: 28,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _handleAdminFunctionTap(title),
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 700 + (index * 100)),
                        curve: Curves.bounceOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value * 0.03 + 0.97,
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.2),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Icon(icon, size: 26, color: Colors.white),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            height: 1.1,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleAdminFunctionTap(String functionTitle) {
    // Add haptic feedback
    // HapticFeedback.lightImpact();
    
    if (functionTitle == 'User Management') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => TeamListPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    } else if (functionTitle == 'Leave Approvals') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const TabbedLeaveApprovalsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }  else if (functionTitle == 'Attendance Reports') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AttendanceReportPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.construction,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$functionTitle functionality coming soon!',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(0xFF374151),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}