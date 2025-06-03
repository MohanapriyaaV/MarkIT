class LeaveRequest {
  final String? id;
  final String? reason;
  final String? status;
  final String? explanation;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final DateTime? appliedAt;
  final double? leaveDuration;
  final int? numberOfDays;
  final bool? isFullDay;
  final bool? isStartFullDay;
  final bool? isEndFullDay;
  final String? startHalfDayType;
  final String? endHalfDayType;

  LeaveRequest({
    this.id,
    this.reason,
    this.status,
    this.explanation,
    this.startDateTime,
    this.endDateTime,
    this.appliedAt,
    this.leaveDuration,
    this.numberOfDays,
    this.isFullDay,
    this.isStartFullDay,
    this.isEndFullDay,
    this.startHalfDayType,
    this.endHalfDayType,
  });

  factory LeaveRequest.fromMap(Map<String, dynamic> map, String documentId) {
    return LeaveRequest(
      id: documentId,
      reason: map['reason'],
      status: map['status'] ?? 'pending',
      explanation: map['explanation'],
      startDateTime: map['startDateTime']?.toDate(),
      endDateTime: map['endDateTime']?.toDate(),
      appliedAt: map['appliedAt']?.toDate(),
      leaveDuration: map['leaveDuration']?.toDouble(),
      numberOfDays: map['numberOfDays'],
      isFullDay: map['isFullDay'],
      isStartFullDay: map['isStartFullDay'],
      isEndFullDay: map['isEndFullDay'],
      startHalfDayType: map['startHalfDayType'],
      endHalfDayType: map['endHalfDayType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reason': reason,
      'status': status,
      'explanation': explanation,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'appliedAt': appliedAt,
      'leaveDuration': leaveDuration,
      'numberOfDays': numberOfDays,
      'isFullDay': isFullDay,
      'isStartFullDay': isStartFullDay,
      'isEndFullDay': isEndFullDay,
      'startHalfDayType': startHalfDayType,
      'endHalfDayType': endHalfDayType,
    };
  }
}