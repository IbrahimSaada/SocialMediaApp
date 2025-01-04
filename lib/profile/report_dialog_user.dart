import 'package:flutter/material.dart';
import 'package:myapp/services/LoginService.dart';
import 'package:myapp/services/GenerateReportService.dart' as ReportServiceFile; // Rename if needed
import 'package:myapp/models/ReportRequest_model.dart';
import 'package:myapp/maintenance/expiredtoken.dart';
import 'package:myapp/services/SessionExpiredException.dart';

void showReportDialog({
  required BuildContext context,
  required int reportedUser,
  required int contentId,
}) async {
  final userId = await LoginService().getUserId();

  // Function to handle report submission
  void submitReport(String reportReason) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final reportRequest = ReportRequest(
      reportedBy: userId,
      reportedUser: reportedUser,
      contentType: 'users',
      contentId: contentId,
      reportReason: reportReason,
      resolutionDetails: '',
    );

    final reportService = ReportServiceFile.ReportService();

    try {
      await reportService.createReport(reportRequest);
      // If successful
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully')),
      );
    } on SessionExpiredException {
      // Handle session expiration
      if (context.mounted) {
        handleSessionExpired(context);
      }
    } catch (error) {
      final errStr = error.toString();
      if (errStr.startsWith('Exception: BLOCKED:')) {
        // Handle BLOCKED scenario if needed
        final reason = errStr.replaceFirst('Exception: BLOCKED:', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action not allowed: $reason')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit report')),
        );
      }
    }
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF45F67)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
          padding: const EdgeInsets.all(12.0),
          child: const Text(
            'Report User',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_problem,
                  color: Colors.redAccent, size: 28),
              title: const Text('Spam',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () {
                Navigator.of(context).pop();
                submitReport('Spam');
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off,
                  color: Colors.redAccent, size: 28),
              title: const Text('Inappropriate Content',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () {
                Navigator.of(context).pop();
                submitReport('Inappropriate Content');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.info, color: Colors.redAccent, size: 28),
              title: const Text('Misinformation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () {
                Navigator.of(context).pop();
                submitReport('Misinformation');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.flag, color: Colors.redAccent, size: 28),
              title: const Text('Harassment or Bullying',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () {
                Navigator.of(context).pop();
                submitReport('Harassment or Bullying');
              },
            ),
            ListTile(
              leading: const Icon(Icons.error, color: Colors.redAccent, size: 28),
              title: const Text('Hate Speech',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () {
                Navigator.of(context).pop();
                submitReport('Hate Speech');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.shield, color: Colors.redAccent, size: 28),
              title: const Text('Violence',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () {
                Navigator.of(context).pop();
                submitReport('Violence');
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.redAccent, size: 28),
              title: const Text('Copyright Violation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () {
                Navigator.of(context).pop();
                submitReport('Copyright Violation');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFFF45F67), fontSize: 16)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      );
    },
  );
}
