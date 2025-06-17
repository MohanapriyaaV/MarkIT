import 'package:cloud_firestore/cloud_firestore.dart';

class FaceDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> hasFaceData(String userId) async {
    final doc = await _firestore.collection('face_data').doc(userId).get();
    return doc.exists;
  }
}
