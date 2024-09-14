// ignore_for_file: file_names

class ReportRequest {
  int reportedBy;
  int reportedUser;
  String contentType;
  int contentId;
  String reportReason;
  String resolutionDetails;

  ReportRequest({
    required this.reportedBy,
    required this.reportedUser,
    required this.contentType,
    required this.contentId,
    required this.reportReason,
    required this.resolutionDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportedBy': reportedBy,
      'reportedUser': reportedUser,
      'contentType': contentType,
      'contentId': contentId,
      'reportReason': reportReason,
      'resolution_details': resolutionDetails,
    };
  }
}
