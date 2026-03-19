enum VerificationStatus { pending, analyzing, success, issue }

class PhotoVerificationStep {
  final String id;
  final String title;
  final String description;
  final String referenceImageUrl;
  VerificationStatus status;
  String? capturedImagePath;
  PhotoVerificationResult? result;

  PhotoVerificationStep({
    required this.id,
    required this.title,
    required this.description,
    required this.referenceImageUrl,
    this.status = VerificationStatus.pending,
    this.capturedImagePath,
    this.result,
  });

  factory PhotoVerificationStep.fromJson(Map<String, dynamic> json) {
    return PhotoVerificationStep(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      referenceImageUrl: json['reference_image_url'] ?? '',
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
  final String? issueCode;
  final String? issueTitle;
  final String? issueDescription;
  final List<String> howToFix;

  PhotoVerificationResult({
    required this.confidenceScore,
    this.issueCode,
    this.issueTitle,
    this.issueDescription,
    this.howToFix = const [],
  });

  factory PhotoVerificationResult.fromJson(Map<String, dynamic> json) {
    return PhotoVerificationResult(
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      issueCode: json['issue_code'],
      issueTitle: json['issue_title'],
      issueDescription: json['issue_description'],
      howToFix: json['how_to_fix'] != null
          ? List<String>.from(json['how_to_fix'])
          : [],
    );
  }
}
