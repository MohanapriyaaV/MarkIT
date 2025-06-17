import 'package:cloud_firestore/cloud_firestore.dart';
class TeamModel {
  final String teamId;
  final String teamName;
  final String adminId;
  final String projectManagerId;
  final String assistantProjectManagerId;
  final String projectLeadId;
  final String? assistantManagerHRId; // NEW
  final String? managerHRId; // NEW
  final List<String> members;
  final DateTime session1Login;
  final DateTime session1Logout;
  final DateTime session2Login;
  final DateTime session2Logout;
  final int graceTimeInMinutes;
  final int noLOPDays;
  final int emergencyLeaves;

  TeamModel({
    required this.teamId,
    required this.teamName,
    required this.adminId,
    required this.projectManagerId,
    required this.assistantProjectManagerId,
    required this.projectLeadId,
    this.assistantManagerHRId,
    this.managerHRId,
    required this.members,
    required this.session1Login,
    required this.session1Logout,
    required this.session2Login,
    required this.session2Logout,
    required this.graceTimeInMinutes,
    required this.noLOPDays,
    required this.emergencyLeaves,
  });

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'adminId': adminId,
      'projectManagerId': projectManagerId,
      'assistantProjectManagerId': assistantProjectManagerId,
      'projectLeadId': projectLeadId,
      'assistantManagerHRId': assistantManagerHRId,
      'managerHRId': managerHRId,
      'members': members,
      'session1Login': Timestamp.fromDate(session1Login),
      'session1Logout': Timestamp.fromDate(session1Logout),
      'session2Login': Timestamp.fromDate(session2Login),
      'session2Logout': Timestamp.fromDate(session2Logout),
      'graceTimeInMinutes': graceTimeInMinutes,
      'noLOPDays': noLOPDays,
      'emergencyLeaves': emergencyLeaves,
    };
  }

  factory TeamModel.fromMap(Map<String, dynamic> map) {
    return TeamModel(
      teamId: map['teamId'] ?? '',
      teamName: map['teamName'] ?? '',
      adminId: map['adminId'] ?? '',
      projectManagerId: map['projectManagerId'] ?? '',
      assistantProjectManagerId: map['assistantProjectManagerId'] ?? '',
      projectLeadId: map['projectLeadId'] ?? '',
      assistantManagerHRId: map['assistantManagerHRId'],
      managerHRId: map['managerHRId'],
      members: List<String>.from(map['members'] ?? []),
      session1Login: (map['session1Login'] as Timestamp?)?.toDate() ?? DateTime.now(),
      session1Logout: (map['session1Logout'] as Timestamp?)?.toDate() ?? DateTime.now(),
      session2Login: (map['session2Login'] as Timestamp?)?.toDate() ?? DateTime.now(),
      session2Logout: (map['session2Logout'] as Timestamp?)?.toDate() ?? DateTime.now(),
      graceTimeInMinutes: map['graceTimeInMinutes'] ?? 0,
      noLOPDays: map['noLOPDays'] ?? 0,
      emergencyLeaves: map['emergencyLeaves'] ?? 0,
    );
  }

  TeamModel copyWith({
    String? teamId,
    String? teamName,
    String? adminId,
    String? projectManagerId,
    String? assistantProjectManagerId,
    String? projectLeadId,
    String? assistantManagerHRId,
    String? managerHRId,
    List<String>? members,
    DateTime? session1Login,
    DateTime? session1Logout,
    DateTime? session2Login,
    DateTime? session2Logout,
    int? graceTimeInMinutes,
    int? noLOPDays,
    int? emergencyLeaves,
  }) {
    return TeamModel(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      adminId: adminId ?? this.adminId,
      projectManagerId: projectManagerId ?? this.projectManagerId,
      assistantProjectManagerId: assistantProjectManagerId ?? this.assistantProjectManagerId,
      projectLeadId: projectLeadId ?? this.projectLeadId,
      assistantManagerHRId: assistantManagerHRId ?? this.assistantManagerHRId,
      managerHRId: managerHRId ?? this.managerHRId,
      members: members ?? this.members,
      session1Login: session1Login ?? this.session1Login,
      session1Logout: session1Logout ?? this.session1Logout,
      session2Login: session2Login ?? this.session2Login,
      session2Logout: session2Logout ?? this.session2Logout,
      graceTimeInMinutes: graceTimeInMinutes ?? this.graceTimeInMinutes,
      noLOPDays: noLOPDays ?? this.noLOPDays,
      emergencyLeaves: emergencyLeaves ?? this.emergencyLeaves,
    );
  }
}
