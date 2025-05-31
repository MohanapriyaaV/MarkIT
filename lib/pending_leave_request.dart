import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animations/animations.dart';

class PendingLeaveRequestPage extends StatelessWidget {
  const PendingLeaveRequestPage({super.key});

  Future<List<Map<String, dynamic>>> fetchUserLeaves() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('DEBUG: No user logged in');
        return [];
      }

      debugPrint('DEBUG: Current user ID: ${user.uid}');
      debugPrint('DEBUG: User email: ${user.email}');

      final firestore = FirebaseFirestore.instance;

      // Updated: Access nested subcollection 'userLeaves' under leaveapplication/{user.uid}
      final snapshot = await firestore
          .collection('leaveapplication')
          .doc(user.uid)
          .collection('userLeaves')
          .where('status', isEqualTo: 'Pending')
          .get();

      debugPrint('DEBUG: Found ${snapshot.docs.length} pending leave requests');

      final results = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['docId'] = doc.id;
        debugPrint('DEBUG: Document ID: ${doc.id}');
        debugPrint('DEBUG: Document data: $data');
        return data;
      }).toList();

      // Sort by startDateTime descending (most recent first)
      results.sort((a, b) {
        final aTime = a['startDateTime'] as Timestamp?;
        final bTime = b['startDateTime'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      debugPrint('DEBUG: Returning ${results.length} leave requests');
      return results;
    } catch (e, stackTrace) {
      debugPrint('DEBUG: Error fetching leaves: $e');
      debugPrint('DEBUG: Stack trace: $stackTrace');
      return [];
    }
  }

  String formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Invalid Date';
      }
      return DateFormat('dd/MM/yyyy, h:mm a').format(date);
    } catch (e) {
      debugPrint('DEBUG: Error formatting date: $e');
      return 'Invalid Date';
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orangeAccent;
      case 'approved':
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Leave Requests"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchUserLeaves(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('DEBUG: FutureBuilder error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text("Error: ${snapshot.error}"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      (context as Element).reassemble();
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, color: Colors.grey, size: 48),
                  const SizedBox(height: 16),
                  const Text("No pending leave requests found."),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      (context as Element).reassemble();
                    },
                    child: const Text("Refresh"),
                  ),
                ],
              ),
            );
          }

          final leaveData = snapshot.data!;
          debugPrint('DEBUG: Displaying ${leaveData.length} leave requests');

          return ListView.builder(
            itemCount: leaveData.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final leave = leaveData[index];
              final status = leave['status']?.toString() ?? 'pending';
              final color = getStatusColor(status);

              return OpenContainer(
                closedElevation: 0,
                openElevation: 2,
                transitionType: ContainerTransitionType.fade,
                closedBuilder: (context, action) => Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: color.withOpacity(0.2),
                      child: Icon(Icons.event_note, color: color),
                    ),
                    title: Text(
                      leave['reason']?.toString() ?? 'Leave Request',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("START DATE : ${formatDateTime(leave['startDateTime'])}"),
                          Text("END DATE   : ${formatDateTime(leave['endDateTime'])}"),
                        ],
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        border: Border.all(color: color),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ),
                openBuilder: (context, action) => DetailPage(leave: leave),
              );
            },
          );
        },
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final Map<String, dynamic> leave;
  const DetailPage({super.key, required this.leave});

  String formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Invalid Date';
      }
      return DateFormat('dd/MM/yyyy, h:mm a').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  int calculateDays(dynamic start, dynamic end) {
    try {
      DateTime startDate, endDate;

      if (start is Timestamp && end is Timestamp) {
        startDate = start.toDate();
        endDate = end.toDate();
      } else {
        return 0;
      }

      return endDate.difference(startDate).inDays + 1;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reason = leave['reason']?.toString() ?? 'N/A';
    final status = leave['status']?.toString() ?? 'N/A';
    final explanation = leave['explanation']?.toString() ?? 'N/A';
    final start = leave['startDateTime'];
    final end = leave['endDateTime'];
    final appliedAt = leave['appliedAt'];

    final numDays = calculateDays(start, end);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Leave Details"),
        backgroundColor: Colors.deepPurple.shade50,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text(
              reason,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            detailItem("Status", status.toUpperCase()),
            detailItem("Start Date", formatDateTime(start)),
            detailItem("End Date", formatDateTime(end)),
            detailItem("Applied At", formatDateTime(appliedAt)),
            detailItem("No. of Days", numDays > 0 ? "$numDays day(s)" : "N/A"),
            detailItem("Explanation", explanation),
          ],
        ),
      ),
    );
  }

  Widget detailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
