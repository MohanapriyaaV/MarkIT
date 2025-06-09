import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/login_service.dart';
import '../models/login_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _logoController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoAnimation;

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    // Initialize animation controllers
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Create animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.bounceOut),
    );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  // FIXED: Enhanced login method with better error handling and fallback strategy
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Authenticate with Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;
      print('=== LOGIN SUCCESS ===');
      print('User authenticated with UID: $uid');

      // Try to fetch user data from multiple sources with fallback strategy
      Map<String, dynamic>? userData = await _getUserDataWithFallback(uid, email);

      if (userData != null) {
        // Extract and clean the role from userData
        final rawRole = userData['role']?.toString() ?? 'Process Associates';
        String cleanRole = RoleService.fixRoleData(rawRole);
        
        print('=== USER DATA FOUND ===');
        print('Raw role: "$rawRole"');
        print('Clean role: "$cleanRole"');
        print('Full user data: $userData');
        
        // Create UserModel with actual data
        final userModel = UserModel(
          uid: uid,
          email: email,
          name: userData['name']?.toString() ?? email.split('@')[0],
          role: cleanRole,
          isAdmin: RoleService.isAdminRole(cleanRole),
          department: userData['department']?.toString(),
          domain: userData['domain']?.toString(),
          manager: userData['Manager']?.toString() ?? userData['manager']?.toString(),
          location: userData['location']?.toString(),
          phoneNumber: userData['phoneNumber']?.toString(),
          joiningDate: userData['JoiningDate']?.toString() ?? userData['joiningDate']?.toString(),
          emergencyLeave: userData['emergency_leave'] as int? ?? userData['emergencyLeave'] as int? ?? 0,
        );

        print('=== USER MODEL CREATED ===');
        print('User model: $userModel');
        print('User role: "${userModel.role}"');
        print('Is admin: ${userModel.isAdmin}');
        print('=========================');
        
        _navigateToDashboard(userModel);
      } else {
        // FALLBACK: Create default user if no data found
        print('=== NO USER DATA FOUND - CREATING DEFAULT ===');
        await _createDefaultUserData(uid, email);
        final defaultUser = UserModel(
          uid: uid,
          email: email,
          name: email.split('@')[0],
          role: 'Process Associates',
          isAdmin: false,
        );
        _navigateToDashboard(defaultUser);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'No internet connection.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many failed attempts. Please try again later.';
      } else {
        errorMessage = 'Login failed. ${e.message}';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('Something went wrong. Please try again.');
      print('Login error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // NEW: Comprehensive method to get user data with multiple fallback strategies
  Future<Map<String, dynamic>?> _getUserDataWithFallback(String uid, String email) async {
    Map<String, dynamic>? userData;

    // Strategy 1: Try to get data from employeeInfo by email
    print('=== STRATEGY 1: Fetch by email from employeeInfo ===');
    userData = await _getEmployeeDataByEmail(email);
    if (userData != null) {
      print('SUCCESS: Found data by email in employeeInfo');
      return userData;
    }

    // Strategy 2: Try to get data from employeeInfo by UID (if empId field matches UID)
    print('=== STRATEGY 2: Fetch by UID from employeeInfo ===');
    userData = await _getEmployeeDataByEmpId(uid);
    if (userData != null) {
      print('SUCCESS: Found data by UID in employeeInfo');
      return userData;
    }

    // Strategy 3: Try to get data from users collection
    print('=== STRATEGY 3: Fetch from users collection ===');
    userData = await _getUserDataFromUsersCollection(uid);
    if (userData != null) {
      print('SUCCESS: Found data in users collection');
      return userData;
    }

    // Strategy 4: Try to search employeeInfo without specific query (get all and filter)
    print('=== STRATEGY 4: Search all employeeInfo documents ===');
    userData = await _findEmployeeDataBySearch(email, uid);
    if (userData != null) {
      print('SUCCESS: Found data by searching all employeeInfo documents');
      return userData;
    }

    print('=== ALL STRATEGIES FAILED ===');
    return null;
  }

  // IMPROVED: Fetch employee data from employeeInfo collection by email with better error handling
  Future<Map<String, dynamic>?> _getEmployeeDataByEmail(String email) async {
    try {
      print('Fetching employee data by email: "$email"');
      
      final querySnapshot = await _firestore
          .collection('employeeInfo')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        print('Found employee data by email: $data');
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching employee data by email: $e');
      // Don't return null immediately, let other strategies try
      return null;
    }
  }

  // IMPROVED: Fetch employee data by empId with better error handling
  Future<Map<String, dynamic>?> _getEmployeeDataByEmpId(String empId) async {
    try {
      print('Fetching employee data by empId: "$empId"');
      
      final doc = await _firestore.collection('employeeInfo').doc(empId).get();

      if (doc.exists) {
        final data = doc.data()!;
        print('Found employee data by empId: $data');
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching employee data by empId: $e');
      return null;
    }
  }

  // NEW: Fetch data from users collection
  Future<Map<String, dynamic>?> _getUserDataFromUsersCollection(String uid) async {
    try {
      print('Fetching user data from users collection: "$uid"');
      
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        print('Found user data in users collection: $data');
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching user data from users collection: $e');
      return null;
    }
  }

  // NEW: Search strategy - get all employeeInfo documents and find matching one
  Future<Map<String, dynamic>?> _findEmployeeDataBySearch(String email, String uid) async {
    try {
      print('Searching all employeeInfo documents for email: "$email" or empId: "$uid"');
      
      // Get all documents (limit to reasonable number for performance)
      final querySnapshot = await _firestore
          .collection('employeeInfo')
          .limit(100)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        
        // Check if email matches
        if (data['email']?.toString().toLowerCase() == email.toLowerCase()) {
          print('Found matching document by email: $data');
          return data;
        }
        
        // Check if empId matches
        if (data['empId']?.toString() == uid) {
          print('Found matching document by empId: $data');
          return data;
        }
      }
      
      print('No matching document found in search');
      return null;
    } catch (e) {
      print('Error in search strategy: $e');
      return null;
    }
  }

  // IMPROVED: Create default user data with better error handling
  Future<void> _createDefaultUserData(String uid, String email) async {
    try {
      print('Creating default user data for: $uid');
      
      // Try to create in users collection
      try {
        await _firestore.collection('users').doc(uid).set({
          'email': email,
          'name': email.split('@')[0],
          'role': 'Process Associates',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('Created default data in users collection');
      } catch (e) {
        print('Could not create in users collection: $e');
      }

      // Try to create in employeeInfo collection
      try {
        final employeeQuery = await _firestore
            .collection('employeeInfo')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (employeeQuery.docs.isEmpty) {
          await _firestore.collection('employeeInfo').add({
            'email': email,
            'name': email.split('@')[0],
            'role': 'Process Associates',
            'empId': uid,
            'department': '',
            'domain': '',
            'Manager': '',
            'location': '',
            'phoneNumber': '',
            'JoiningDate': '',
            'emergency_leave': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('Created default data in employeeInfo collection');
        }
      } catch (e) {
        print('Could not create in employeeInfo collection: $e');
      }

    } catch (e) {
      print('Error creating default user data: $e');
      // Don't throw error, continue with login
    }
  }

  // Navigate to dashboard with user data
  void _navigateToDashboard(UserModel user) {
    // Try to update last login time (don't fail if this doesn't work)
    _updateLastLogin(user.uid).catchError((e) {
      print('Could not update last login: $e');
    });

    // Debug the data being passed
    final userMap = user.toMap();
    print('=== NAVIGATION DEBUG ===');
    print('User model: $user');
    print('Data being passed to dashboard: $userMap');
    print('User is admin: ${user.isAdmin}');
    print('User role: "${user.role}"');
    print('RoleService says admin: ${RoleService.isAdminRole(user.role)}');
    print('Display name: ${RoleService.getDisplayName(user.role)}');
    print('========================');

    // Navigate to appropriate dashboard based on admin status
    Navigator.pushReplacementNamed(
  context,
  '/dashboard',
  arguments: {
    ...userMap,
    'isAdmin': user.isAdmin,
    'showAdminFeatures': user.isAdmin,
  },
);

    // Show welcome message with role information
    String welcomeMessage =
        'Welcome back, ${user.name}! (${RoleService.getDisplayName(user.role)})';
    if (user.isAdmin) {
      welcomeMessage += ' - Admin Access Granted';
    }

    _showSuccessSnackBar(welcomeMessage);
  }

  // IMPROVED: Update last login timestamp with error handling
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last login: $e');
      // Don't throw error, just log it
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFFF6B6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4A90E2), // Lighter blue
              Color(0xFF5C7CFA), // Medium blue-purple
              Color(0xFF7B68EE), // Medium slate blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background circles
            _buildBackgroundDecorations(),

            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo section
                      _buildAnimatedLogo(),

                      SizedBox(height: screenHeight * 0.01),

                      // Login form
                      _buildLoginForm(screenWidth),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.03),
            ),
          ),
        ),
        Positioned(
          top: 200,
          left: -50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedLogo() {
    return ScaleTransition(
      scale: _logoAnimation,
      child: FadeTransition(
        opacity: _logoAnimation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 19),
              child: Image.asset(
                'assets/images/VistaLogo1.png',
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.business,
                      size: 65,
                      color: Color(0xFF4A90E2),
                    ),
                  );
                },
              ),
            ),
            Image.asset(
              'assets/images/VistaLogo2.png',
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.corporate_fare,
                    size: 75,
                    color: Color(0xFF4A90E2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(double screenWidth) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: screenWidth * 0.85,
            constraints: const BoxConstraints(maxWidth: 350),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(-8, -8),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'WELCOME!!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Login to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Email TextField
                  _buildStyledTextField(
                    controller: _emailController,
                    labelText: 'Username / Email',
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 20),

                  // Password TextField
                  _buildStyledTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    prefixIcon: Icons.vpn_key_outlined,
                    isPassword: true,
                  ),

                  const SizedBox(height: 12),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF5C7CFA),
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Login Button
                  _buildLoginButton(),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Sign Up Button
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF5C7CFA),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 16,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF5C7CFA),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF5C7CFA)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[50]?.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF5C7CFA), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF5C7CFA), Color(0xFF7B68EE)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C7CFA).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}