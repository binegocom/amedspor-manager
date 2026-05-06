class ReportModel {
  final String id;
  final String reporterId;
  final String targetType;
  final String targetId;
  final String reason;
  final String detail;
  final String status;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.detail,
    required this.status,
    required this.createdAt,
  });

  factory ReportModel.fromMap(String id, Map<String, dynamic> map) {
    return ReportModel(
      id: id,
      reporterId: map['reporterId'] ?? '',
      targetType: map['targetType'] ?? '',
      targetId: map['targetId'] ?? '',
      reason: map['reason'] ?? '',
      detail: map['detail'] ?? '',
      status: map['status'] ?? 'reviewing',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'detail': detail,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
