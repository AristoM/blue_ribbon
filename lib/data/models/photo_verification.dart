enum VerificationStatus { pending, analyzing, success, issue }

class PhotoVerificationStep {
  final String id;
  final String title;
  final String description;
  final String referenceImageUrl;
  final List<String> checks;
  final Map<String, dynamic> commonIssues;
  VerificationStatus status;
  String? capturedImagePath;
  PhotoVerificationResult? result;

  PhotoVerificationStep({
    required this.id,
    required this.title,
    required this.description,
    required this.referenceImageUrl,
    this.checks = const [],
    this.commonIssues = const {},
    this.status = VerificationStatus.pending,
    this.capturedImagePath,
    this.result,
  });

  factory PhotoVerificationStep.fromJson(Map<String, dynamic> json) {
    return PhotoVerificationStep(
      id: json['id']?.toString() ?? '',
      title: (json['name'] ?? json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      referenceImageUrl: (json['reference_image'] ?? json['reference_image_url'] ?? '').toString(),
      checks: json['checks'] != null ? List<String>.from(json['checks']) : [],
      commonIssues: json['common_issues'] ?? {},
      status: _parseStatus(json['status']),
    );
  }

  static VerificationStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'analyzing':
        return VerificationStatus.analyzing;
      case 'success':
        return VerificationStatus.success;
      case 'issue':
        return VerificationStatus.issue;
      default:
        return VerificationStatus.pending;
    }
  }
}

class PhotoVerificationResult {
  final double confidenceScore;
  final String status;
  final String? issueCode;
  final String? issueTitle;
  final String? issueDescription;
  final List<String> howToFix;

  PhotoVerificationResult({
    required this.confidenceScore,
    required this.status,
    this.issueCode,
    this.issueTitle,
    this.issueDescription,
    this.howToFix = const [],
  });

  factory PhotoVerificationResult.fromJson(Map<String, dynamic> json) {
    final issues = json['issues'] as List? ?? [];
    final firstIssue =
        issues.isNotEmpty ? issues[0] as Map<String, dynamic> : null;

    return PhotoVerificationResult(
      confidenceScore: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'fail',
      issueCode: firstIssue?['issue_id'],
      issueTitle: firstIssue?['name'],
      issueDescription: firstIssue?['description'],
      howToFix: firstIssue?['fix_instructions'] != null
          ? List<String>.from(firstIssue!['fix_instructions'])
          : [],
    );
  }
}
