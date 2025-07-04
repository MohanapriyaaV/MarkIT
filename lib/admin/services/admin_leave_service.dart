import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all teams where this admin is in the admins list
  Future<List<Map<String, dynamic>>> fetchTeamsForAdmin(String adminUid) async {
    final teamsSnapshot = await _firestore
        .collection('teams')
        .where('admins', arrayContains: adminUid)
        .get();
    return teamsSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Fetch all pending leaves for all members of the given teams
  Future<List<Map<String, dynamic>>> fetchPendingLeavesForTeams(List<Map<String, dynamic>> teams) async {
    List<Map<String, dynamic>> pendingLeaves = [];
    List<Future<List<Map<String, dynamic>>>> futures = [];
    for (final team in teams) {
      final List members = team['members'] ?? [];
      for (final memberId in members) {
        futures.add(
          _firestore
              .collection('leaveapplication')
              .doc(memberId)
              .collection('userLeaves')
              .where('status', isEqualTo: 'Pending')
              .get()
              .then((leavesSnapshot) => leavesSnapshot.docs.map((leaveDoc) {
                    final leaveData = leaveDoc.data();
                    leaveData['leaveId'] = leaveDoc.id;
                    leaveData['employeeId'] = memberId;
                    leaveData['teamId'] = team['id'] ?? team['teamId'];
                    return leaveData;
                  }).toList()),
        );
      }
    }
    final results = await Future.wait(futures);
    pendingLeaves = results.expand((x) => x).toList();
    return pendingLeaves;
  }

  // Approve a leave and record the admin info
  Future<void> approveLeave({
    required String memberId,
    required String leaveId,
    required String adminId,
    required String adminName,
    required String adminRole,
  }) async {
    await _firestore
        .collection('leaveapplication')
        .doc(memberId)
        .collection('userLeaves')
        .doc(leaveId)
        .update({
          'status': 'Approved',
          'approvedBy': adminId,
          'approvedByName': adminName,
          'approvedByRole': adminRole,
          'approvedAt': FieldValue.serverTimestamp(),
        });
  }

  // Fetch all approved leaves for teams this admin manages
  Future<List<Map<String, dynamic>>> fetchApprovedLeavesForTeams(List<Map<String, dynamic>> teams) async {
    List<Map<String, dynamic>> approvedLeaves = [];
    List<Future<List<Map<String, dynamic>>>> futures = [];
    for (final team in teams) {
      final List members = team['members'] ?? [];
      for (final memberId in members) {
        futures.add(
          _firestore
              .collection('leaveapplication')
              .doc(memberId)
              .collection('userLeaves')
              .where('status', isEqualTo: 'Approved')
              .get()
              .then((leavesSnapshot) => leavesSnapshot.docs.map((leaveDoc) {
                    final leaveData = leaveDoc.data();
                    leaveData['leaveId'] = leaveDoc.id;
                    leaveData['employeeId'] = memberId;
                    leaveData['teamId'] = team['id'] ?? team['teamId'];
                    return leaveData;
                  }).toList()),
        );
      }
    }
    final results = await Future.wait(futures);
    approvedLeaves = results.expand((x) => x).toList();
    return approvedLeaves;
  }
}
