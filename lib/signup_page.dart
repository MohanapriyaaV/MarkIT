import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'employee_details_page.dart';
import 'login.dart';

class SimpleSignUpPage extends StatefulWidget {
  const SimpleSignUpPage({super.key});

  @override
  State<SimpleSignUpPage> createState() => _SimpleSignUpPageState();
}

class _SimpleSignUpPageState extends State<SimpleSignUpPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _checkIfEmailExists(String email) async {
    // FirebaseAuth throws if email exists in sign-up but we want a pre-check:
    // We'll try to fetch sign-in methods to detect if email is registered.
    try {
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      // Assume email doesn't exist if error occurs here
      return false;
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (!email.endsWith('@vistaes.com')) {
      _showSnackBar('Email must be a @vistaes.com address');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    // Check if email already exists in Firebase Auth
    final emailExists = await _checkIfEmailExists(email);
    if (emailExists) {
      _showSnackBar('Email already registered. Please log in.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final String uid = userCredential.user!.uid;

      // Firestore: Create initial user profile with default values
      await FirebaseFirestore.instance.collection('employeeInfo').doc(uid).set({
        'email': email,
        'empId': uid,
        'name': '',
        'department': '',
        'phoneNumber': '',
        'role': '',
        'location': '',
        'JoiningDate': '',
        'Manager': '',
        'emergency_leave': 0,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmployeeFormPage(uid: uid, email: email),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showSnackBar('This email is already registered. Please log in.');
      } else {
        _showSnackBar('Sign up failed: ${e.message}');
      }
    } catch (e) {
      _showSnackBar('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.deepPurple,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffEBD8FF), Color(0xffF7F0FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 40, bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Row matching LoginPage
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Image.asset('assets/images/VistaLogo1.png', height: 80),
                    ),
                    Image.asset('assets/images/VistaLogo2.png', height: 80),
                  ],
                ),
                const SizedBox(height: 30),
                SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: screenWidth * 0.75,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'CREATE ACCOUNT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.mail_outline),
                              labelText: 'Email',
                              hintText: 'Enter your @vistaes.com email',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.vpn_key_outlined),
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.vpn_key_outlined),
                              labelText: 'Confirm Password',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 215, 183, 245),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Sign Up',
                                    style: TextStyle(fontSize: 18),
                                  ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginPage()),
                                    );
                                  },
                            child: const Text(
                              'Already have an account? Log in',
                              style: TextStyle(color: Colors.deepPurple),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
