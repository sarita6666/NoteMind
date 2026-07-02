import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<void> createOrUpdateUser({
    required String uid,
    required String name,
    required String email,
    String bio = "",
    String? photoUrl,
  }) async {
    final data = {'name': name, 'email': email, 'bio': bio, 'uid': uid};

    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
    }

    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot> getUser(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Stream<List<Map<String, dynamic>>> searchUsers(String query) {
    return _db.collection("users").snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data["uid"] = doc.id; // 🔥 ASEGURA UID
            return data;
          })
          .where((user) {
            final name = (user["name"] ?? "").toLowerCase();
            final email = (user["email"] ?? "").toLowerCase();

            return name.contains(query.toLowerCase()) ||
                email.contains(query.toLowerCase());
          })
          .toList();
    });
  }
}
