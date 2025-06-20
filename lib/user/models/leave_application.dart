import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveApplication {
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int numberOfDays;
  final double leaveDuration;
  final bool? isFullDay;
  final String? halfDayType;
  final bool? isStartFullDay;
  final bool? isEndFullDay;
  final String? startHalfDayType;
  final String? endHalfDayType;
  final String reason;
  final String explanation;
  final String status;
  final DateTime appliedAt;
  final String userID;
  final String teamId;

  LeaveApplication({
    required this.startDateTime,
    required this.endDateTime,
    required this.numberOfDays,
    required this.leaveDuration,
    this.isFullDay,
    this.halfDayType,
    this.isStartFullDay,
    this.isEndFullDay,
    this.startHalfDayType,
    this.endHalfDayType,
    required this.reason,
    required this.explanation,
    required this.status,
    required this.appliedAt,
    required this.userID,
    required this.teamId,
  });

  Map<String, dynamic> toMap() {
    return {
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'numberOfDays': numberOfDays,
      'leaveDuration': leaveDuration,
      'isFullDay': isFullDay,
      'halfDayType': halfDayType,
      'isStartFullDay': isStartFullDay,
      'isEndFullDay': isEndFullDay,
      'startHalfDayType': startHalfDayType,
      'endHalfDayType': endHalfDayType,
      'reason': reason,
      'explanation': explanation,
      'status': status,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'userID': userID,
      'teamId': teamId,
    };
  }
}
