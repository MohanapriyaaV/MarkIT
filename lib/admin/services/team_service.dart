import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/team_model.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTeam(TeamModel team) async {
    final teamRef = _firestore.collection('teams').doc();
    final updatedTeam = team.copyWith(teamId: teamRef.id);
    await teamRef.set(updatedTeam.toMap());
    await _updateMembers(updatedTeam);
  }

  Future<void> updateTeam(TeamModel team) async {
    await _firestore.collection('teams').doc(team.teamId).update(team.toMap());
    await _updateMembers(team);
  }

  Future<void> _updateMembers(TeamModel team) async {
    for (String userId in team.members) {
      await _firestore.collection('employeeInfo').doc(userId).update({
        'teamId': team.teamId,
        'shiftTiming': {
          'session1Login': Timestamp.fromDate(team.session1Login),
          'session1Logout': Timestamp.fromDate(team.session1Logout),
          'session2Login': Timestamp.fromDate(team.session2Login),
          'session2Logout': Timestamp.fromDate(team.session2Logout),
          'graceTimeInMinutes': team.graceTimeInMinutes,
        },
        'leaveLimits': {
          'noLOPDays': team.noLOPDays,
          'emergencyLeaves': team.emergencyLeaves,
        },
      });
    }
  }

  Future<List<TeamModel>> getTeamsByAdmin(String adminId) async {
    final snapshot = await _firestore
        .collection('teams')
        .where('adminId', isEqualTo: adminId)
        .get();

    return snapshot.docs
        .map((doc) => TeamModel.fromMap(doc.data()))
        .toList();
  }

  /// ✅ UPDATED: Fetch all teams (no filtering by current user)
  Future<List<TeamModel>> getAllTeams() async {
    try {
      final snapshot = await _firestore.collection('teams').get();
      return snapshot.docs
          .map((doc) => TeamModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print("🔥 Error fetching all teams: $e");
      return [];
    }
  }

  Future<void> deleteTeam(String teamId) async {
    await _firestore.collection('teams').doc(teamId).delete();
  }

  Future<TeamModel?> getTeamById(String teamId) async {
    final doc = await _firestore.collection('teams').doc(teamId).get();
    if (doc.exists && doc.data() != null) {
      return TeamModel.fromMap(doc.data()!);
    }
    return null;
  }
}
