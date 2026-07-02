import 'package:cloud_firestore/cloud_firestore.dart';

class AIChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createChat(String userId) async {
    final doc = await _db.collection("ai_chats").add({
      "userId": userId,
      "createdAt": FieldValue.serverTimestamp(),
      "title": "Nuevo chat",
    });

    return doc.id;
  }

  Future<void> saveMessage({
    required String chatId,
    required String sender,
    required String text,
  }) async {
    await _db.collection("ai_chats").doc(chatId).collection("messages").add({
      "sender": sender,
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getChats(String userId) {
    return FirebaseFirestore.instance
        .collection("ai_chats")
        .where("userId", isEqualTo: userId)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return FirebaseFirestore.instance
        .collection("ai_chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("timestamp")
        .snapshots();
  }

  Future<void> deleteChat(String chatId) async {
    final messages = await _db
        .collection("ai_chats")
        .doc(chatId)
        .collection("messages")
        .get();

    for (final doc in messages.docs) {
      await doc.reference.delete();
    }

    await _db.collection("ai_chats").doc(chatId).delete();
  }
}
