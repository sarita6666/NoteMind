import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NoteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  NoteService() {
    _db.settings = const Settings(persistenceEnabled: false);
  }
  Future<void> toggleLike(String noteId, String userId) async {
    final docRef = FirebaseFirestore.instance.collection("notes").doc(noteId);

    final doc = await docRef.get();

    if (!doc.exists) return;

    final data = doc.data()!;
    List likes = data["likes"] ?? [];

    if (likes.contains(userId)) {
      // quitar like
      await docRef.update({
        "likes": FieldValue.arrayRemove([userId]),
      });
    } else {
      // agregar like
      await docRef.update({
        "likes": FieldValue.arrayUnion([userId]),
      });
    }
  }

  Future<void> updateComment({
    required String noteId,
    required String commentId,
    required String text,
  }) async {
    await FirebaseFirestore.instance
        .collection('notes')
        .doc(noteId)
        .collection('comments')
        .doc(commentId)
        .update({"text": text, "edited": true});
  }

  Future<void> deleteComment({
    required String noteId,
    required String commentId,
  }) async {
    await FirebaseFirestore.instance
        .collection('notes')
        .doc(noteId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  Future<void> addComment({
    required String noteId,
    required String text,
    required String userName,
    required String userRole,
    required String userId,
    String? parentId,
    String? parentUserName,
  }) async {
    await _db.collection("notes").doc(noteId).collection("comments").add({
      "text": text,
      "userName": userName,
      "userRole": userRole,
      "userId": userId,
      "parentId": parentId,
      "parentUserName": parentUserName,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getComments(String noteId) {
    return _db
        .collection("notes")
        .doc(noteId)
        .collection("comments")
        .orderBy("createdAt")
        .snapshots();
  }

  Future<void> create(NoteModel note) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final userDoc = await _db.collection("users").doc(user.uid).get();
    final userData = userDoc.data();

    final docRef = _db.collection("notes").doc();

    await docRef.set({
      ...note.toMap(),
      "userName": userData?["name"] ?? "Usuario",
      "userRole": userData?["role"] ?? "Sin rol",
    });
  }

  Stream<List<NoteModel>> getNotes(String userId) {
    return _db.collection("notes").snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => NoteModel.fromMap(doc.data(), doc.id))
          .where((note) => note.userId == userId)
          .toList();
    });
  }

  Stream<List<NoteModel>> getAllNotes() {
    return _db.collection("notes").snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => NoteModel.fromMap(doc.data(), doc.id))
          .where((note) => note.isPublic == true)
          .toList();
    });
  }

  Future<void> delete(String id) async {
    await _db.collection("notes").doc(id).delete();
  }

  Future<void> update(NoteModel note) async {
    final data = note.toMap();
    data.remove("createdAt"); // 🔥 evita sobrescribir fecha

    await _db.collection("notes").doc(note.id).update(data);
  }
}
