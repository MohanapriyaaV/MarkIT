import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTeam(TeamModel team) async {
    // Check for duplicate members in other teams
    final duplicateMembers = await _findDuplicateMembers(team.members);
    if (duplicateMembers.isNotEmpty) {
      throw Exception("The following members are already assigned to another team: ${duplicateMembers.join(", ")}");
    }
    final teamRef = _firestore.collection('teams').doc();
    final updatedTeam = team.copyWith(teamId: teamRef.id);
    // Build admins array from all 5 admin roles (skip nulls)
    final admins = [
      updatedTeam.projectManagerId,
      updatedTeam.assistantProjectManagerId,
      updatedTeam.projectLeadId,
      updatedTeam.assistantManagerHRId,
      updatedTeam.managerHRId,
      updatedTeam.adminId, // Add director's UID to admins array
    ].whereType<String>().toSet().toList(); // Use set to avoid duplicates
    final teamMap = updatedTeam.toMap();
    teamMap['admins'] = admins;
    // Set adminId to the director's UID (the creator of the team)
    teamMap['adminId'] = updatedTeam.adminId;
    await teamRef.set(teamMap);
    await _updateMembers(updatedTeam);
  }

  Future<void> updateTeam(TeamModel team) async {
    // Check for duplicate members in other teams (excluding current team)
    final duplicateMembers = await _findDuplicateMembers(team.members, excludeTeamId: team.teamId);
    if (duplicateMembers.isNotEmpty) {
      throw Exception("The following members are already assigned to another team: ${duplicateMembers.join(", ")}");
    }
    if (team.teamId.isEmpty) {
      throw Exception("Team ID cannot be empty for update.");
    }
    // Build admins array from all 5 admin roles (skip nulls)
    final admins = [
      team.projectManagerId,
      team.assistantProjectManagerId,
      team.projectLeadId,
      team.assistantManagerHRId,
      team.managerHRId,
      team.adminId, // Add director's UID to admins array
    ].whereType<String>().toSet().toList(); // Use set to avoid duplicates
    final teamMap = team.toMap();
    teamMap['admins'] = admins;
    // Set adminId to the director's UID (the creator of the team)
    teamMap['adminId'] = team.adminId;
    await _firestore.collection('teams').doc(team.teamId).update(teamMap);
    await _updateMembers(team);
  }

  Future<void> deleteTeam(String teamId) async {
    if (teamId.isEmpty) {
      throw Exception("Team ID cannot be empty for delete.");
    }
    await _firestore.collection('teams').doc(teamId).delete();
  }

  Future<List<TeamModel>> getTeamsByAdmin(String adminId) async {
    final snapshot = await _firestore
        .collection('teams')
        .where('adminId', isEqualTo: adminId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return TeamModel.fromMap({...data, 'teamId': doc.id});
    }).toList();
  }

  Future<List<TeamModel>> getAllTeams() async {
    try {
      final snapshot = await _firestore.collection('teams').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TeamModel.fromMap({...data, 'teamId': doc.id});
      }).toList();
    } catch (e) {
      print("🔥 Error fetching all teams: $e");
      return [];
    }
  }

  Future<TeamModel?> getTeamById(String teamId) async {
    if (teamId.isEmpty) return null;
    final doc = await _firestore.collection('teams').doc(teamId).get();
    if (doc.exists && doc.data() != null) {
      return TeamModel.fromMap({...doc.data()!, 'teamId': doc.id});
    }
    return null;
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

  bool hasTeamEditPermission(TeamModel team, String userId) {
    return team.adminId == userId ||
        team.projectManagerId == userId ||
        team.assistantProjectManagerId == userId ||
        team.projectLeadId == userId ||
        team.generalProjectManagerId == userId ||
        team.assistantManagerHRId == userId ||
        team.managerHRId == userId;
  }

  Future<List<String>> _findDuplicateMembers(List<String> members, {String? excludeTeamId}) async {
    final snapshot = await _firestore.collection('teams').get();
    final Set<String> assignedMembers = {};
    for (final doc in snapshot.docs) {
      if (excludeTeamId != null && doc.id == excludeTeamId) continue;
      final data = doc.data();
      final teamMembers = List<String>.from(data['members'] ?? []);
      assignedMembers.addAll(teamMembers);
    }
    return members.where((m) => assignedMembers.contains(m)).toList();
  }
}
