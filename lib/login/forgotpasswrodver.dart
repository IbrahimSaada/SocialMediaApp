import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'new_password_page.dart';
import '../services/PasswordResetService.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ForgotpasswrodverPage(emailOrPhone: ''),
    ));

class ForgotpasswrodverPage extends StatefulWidget {
  final String emailOrPhone;
  const ForgotpasswrodverPage({super.key, required this.emailOrPhone});

  @override
  _ForgotpasswrodverPageState createState() => _ForgotpasswrodverPageState();
}

class _ForgotpasswrodverPageState extends State<ForgotpasswrodverPage> {
  final int codeLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index + 1 < codeLength) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index - 1 >= 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  void _verifyCode() async {
    String code = _controllers.map((controller) => controller.text).join();
    try {
      bool isValid = await PasswordResetService().verifyUser(
        widget.emailOrPhone,
        code,
      );
      if (isValid) {
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => NewpasswordPage(
                  emailOrPhone: widget.emailOrPhone, verificationCode: code)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid verification code')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _resendCode() async {
    try {
      await PasswordResetService().requestPasswordReset(widget.emailOrPhone);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code resent')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
            colors: [
              primaryColor.withOpacity(0.9),
              primaryColor.withOpacity(0.8),
              primaryColor.withOpacity(0.4),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 80),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: const Text(
                      "Verify Your Account",
                      style: TextStyle(color: Colors.white, fontSize: 40),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 60),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(codeLength, (index) {
                          return Container(
                            width: 40,
                            height: 50,
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
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  counterText: "", // Hide the counter text
                                  hintText: "",
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(fontSize: 24),
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                onChanged: (value) => _onChanged(value, index),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 40),
                      FadeInUp(
                        duration: const Duration(milliseconds: 1600),
                        child: MaterialButton(
                          onPressed: _verifyCode,
                          height: 50,
                          color: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Center(
                            child: Text(
                              "Verify",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeInUp(
                        duration: const Duration(milliseconds: 1600),
                        child: MaterialButton(
                          onPressed: _resendCode,
                          height: 50,
                          color: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Center(
                            child: Text(
                              "Resend Code",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
    );
  }
}
