import 'package:flutter/material.dart';
import '***REMOVED***/services/LoginService.dart';
import '***REMOVED***/services/GenerateReportService.dart';
import '***REMOVED***/models/ReportRequest_model.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';

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
      contentType: 'Post', // Assuming content type is 'Post'
      contentId: contentId,
      reportReason: reportReason,
      resolutionDetails: '',
    );

    try {
      final reportService =
          ReportService(); // Create an instance of ReportService
      await reportService
          .createReport(reportRequest); // Use the instance to call the method
          // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully')),
      );
    } catch (error) {
      if (error.toString().contains('Session expired')) {
        // ignore: use_build_context_synchronously
        handleSessionExpired(context);  // 1. Handle session expired globally
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          // ignore: use_build_context_synchronously
          const SnackBar(content: Text('Failed to submit report')),
        );
      }
    }
  }

  showDialog(
    // ignore: use_build_context_synchronously
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
            'Report Post',
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
              leading:
                  const Icon(Icons.report_problem, color: Colors.redAccent, size: 28),
              title: const Text('Spam',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () {
                Navigator.of(context).pop();
                submitReport('Spam');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.visibility_off, color: Colors.redAccent, size: 28),
              title: const Text('Inappropriate Content',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () {
                Navigator.of(context).pop();
                submitReport('Inappropriate Content');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.redAccent, size: 28),
              title: const Text('Misinformation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () {
                Navigator.of(context).pop();
                submitReport('Misinformation');
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.redAccent, size: 28),
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
              leading: const Icon(Icons.shield, color: Colors.redAccent, size: 28),
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
            ListTile(
              leading:
                  const Icon(Icons.help_outline, color: Colors.redAccent, size: 28),
              title: const Text('Other',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () {
                Navigator.of(context).pop();
                submitReport('Other');
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
