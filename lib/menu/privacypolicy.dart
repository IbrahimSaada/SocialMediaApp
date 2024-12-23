import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFFF45F67);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome to Our Privacy Policy",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Your privacy is critically important to us. This policy outlines how we collect, use, and protect your information.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 16),
              _buildSection(
                title: "Information We Collect",
                content:
                    "We may collect personal information, such as your name, email address, and profile details, when you register and interact with our platform. Non-personal information, such as device type and usage patterns, may also be collected.",
              ),
              SizedBox(height: 16),
              _buildSection(
                title: "How We Use Your Information",
                content:
                    "We use your information to improve your experience, provide personalized services, and ensure the security of our platform. Your data is never sold or shared with third parties without your explicit consent.",
              ),
              SizedBox(height: 16),
              _buildSection(
                title: "Your Data Protection Rights",
                content:
                    "You have the right to access, update, and delete your personal information. If you have any concerns about how we handle your data, please contact us at support@example.com.",
              ),
              SizedBox(height: 16),
              _buildSection(
                title: "Cookies and Tracking Technologies",
                content:
                    "We use cookies to improve functionality and provide analytics about site usage. You can manage your cookie preferences through your browser settings.",
              ),
              SizedBox(height: 16),
              _buildSection(
                title: "Policy Updates",
                content:
                    "We may update this Privacy Policy periodically to reflect changes in our practices or for legal and regulatory reasons. Please review this page regularly for updates.",
              ),
              SizedBox(height: 24),
              Center(
                child: Text(
                  "Thank you for trusting us with your information!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
