import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '***REMOVED***/home/home.dart';
import '***REMOVED***/login/forgotpassword.dart';
import '../login/register.dart';
import '../services/LoginService.dart';
import '../services/BannedException.dart';
import 'verification_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the text fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // For 'Remember me' functionality
  bool _rememberMe = false;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // UI states
  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorMessage;

  // For checking if user is already logged in
  final LoginService _loginService = LoginService();

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyLoggedIn(); // 1) Skip login if user is already logged in
    _loadSavedCredentials();   // 2) Load saved email/password if any
  }

  /// 1) If user is already logged in (valid token), skip login page
  Future<void> _checkIfAlreadyLoggedIn() async {
    final bool isLoggedIn = await _loginService.isLoggedIn();
    if (isLoggedIn) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  /// 2) Load saved email and password (if any) from secure storage
  Future<void> _loadSavedCredentials() async {
    try {
      // If you'd like to store the "rememberMe" bool:
      final rememberMeValue = await _secureStorage.read(key: 'rememberMe');
      final bool savedRemember = (rememberMeValue == 'true');

      if (savedRemember) {
        // Only load if rememberMe was previously 'true'
        final savedEmail = await _secureStorage.read(key: 'savedEmail');
        final savedPassword = await _secureStorage.read(key: 'savedPassword');

        if (savedEmail != null && savedPassword != null) {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          _rememberMe = true;

          // Show a Snackbar to confirm credentials were loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  /// Saves email and password + rememberMe in secure storage
  Future<void> _saveCredentials(String email, String password) async {
    await _secureStorage.write(key: 'savedEmail', value: email);
    await _secureStorage.write(key: 'savedPassword', value: password);
    // Also store the "rememberMe" preference
    await _secureStorage.write(key: 'rememberMe', value: 'true');
    debugPrint('Credentials + rememberMe=true saved securely.');
  }

  /// Deletes email and password, sets rememberMe=false
  Future<void> _deleteCredentials() async {
    await _secureStorage.delete(key: 'savedEmail');
    await _secureStorage.delete(key: 'savedPassword');
    await _secureStorage.write(key: 'rememberMe', value: 'false');
    debugPrint('Credentials removed, rememberMe=false.');
  }

  /// Main login logic
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Optional: quick admin login check
    if (_emailController.text.trim() == 'admin@gmail.com' &&
        _passwordController.text.trim() == 'admin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomePage()),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _loginService.loginUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // If login succeeds:
      if (_rememberMe) {
        await _saveCredentials(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await _deleteCredentials();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on BannedException catch (bex) {
      // If user is banned, navigate to banned screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BannedScreen(
            banReason: bex.reason,
            banExpiresAt: bex.expiresAt,
          ),
        ),
      );
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('No network connection')) {
        errorMessage = 'No network connection. Please check your internet.';
      } else if (errorMessage.contains('Server error')) {
        errorMessage = 'Server error occurred. Please try again later.';
      } else if (errorMessage.contains('Account not verified')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VerificationPage(
              email: _emailController.text.trim(),
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      } else if (errorMessage.contains("Unauthorized")) {
        errorMessage = "The password you’ve entered is incorrect";
      } else {
        errorMessage = "Login failed. $errorMessage";
      }
      setState(() => _errorMessage = errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [primaryColor, primaryColor],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              // Title: "Login" & "Welcome back"
              const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Login",
                      style: TextStyle(color: Colors.white, fontSize: 40),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Welcome Back",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // White container with form
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 60),

                        // Fields container
                        FadeInUp(
                          duration: const Duration(milliseconds: 1400),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(225, 95, 27, .3),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Email field
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      hintText: "Enter Your Email",
                                      hintStyle: TextStyle(color: Colors.grey),
                                      border: InputBorder.none,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                // Password field
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscureText,
                                    decoration: InputDecoration(
                                      hintText: "Password",
                                      hintStyle: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                      border: InputBorder.none,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureText
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureText = !_obscureText;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Remember me (Checkbox) - aligned to the LEFT
                        FadeInUp(
                          duration: const Duration(milliseconds: 1500),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Error message (if any)
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 20),
                          FadeInUp(
                            duration: const Duration(milliseconds: 1500),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        const SizedBox(height: 30),

                        // LOGIN BUTTON
                        FadeInUp(
                          duration: const Duration(milliseconds: 1600),
                          child: MaterialButton(
                            onPressed: _isLoading ? null : _login,
                            height: 50,
                            color: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  )
                                : const Center(
                                    child: Text(
                                      "Login",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Register
                        FadeInUp(
                          duration: const Duration(milliseconds: 1500),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Don't have account?",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Forgot Password
                        FadeInUp(
                          duration: const Duration(milliseconds: 1500),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotpasswrodhomePage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),
                      ],
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
}

// -------------------------------------------------
// BannedScreen remains unchanged below
// -------------------------------------------------
class BannedScreen extends StatelessWidget {
  final String banReason;
  final String banExpiresAt;

  const BannedScreen({
    required this.banReason,
    required this.banExpiresAt,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF45F67),
      body: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.block,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Account Banned',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Reason: $banReason',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ban Expires At: $banExpiresAt',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.black45,
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ).copyWith(
                      backgroundColor:
                          MaterialStateProperty.resolveWith<Color>(
                        (states) {
                          if (states.contains(MaterialState.pressed)) {
                            return Colors.deepOrange;
                          }
                          return Colors.redAccent;
                        },
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
