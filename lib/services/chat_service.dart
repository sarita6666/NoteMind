import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  String getChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode
        ? "${user1}_$user2"
        : "${user2}_$user1";
  }

  Future<void> sendNote({
    required String chatId,
    required String noteId,
  }) async {
    final chatRef = _db.collection("chats").doc(chatId);

    await chatRef.collection("messages").add({
      "senderId": FirebaseAuth.instance.currentUser!.uid,
      "type": "note",
      "noteId": noteId,
      "text": "",
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  Future<void> createChat(String user1, String user2) async {
    final chatId = getChatId(user1, user2);

    final doc = _db.collection("chats").doc(chatId);

    final exists = await doc.get();

    if (!exists.exists) {
      await doc.set({
        "participants": [user1, user2],
        "lastMessage": "",
        "updatedAt": FieldValue.serverTimestamp(),
      });
    }
  }

  // 🔥 ENVÍA MENSAJE (CREA SUBCOLECCIÓN)
  Future<void> sendMessage({
    required String chatId,
    required MessageModel message,
  }) async {
    final chatRef = _db.collection("chats").doc(chatId);

    await chatRef.collection("messages").add(message.toMap());

    await chatRef.update({
      "lastMessage": message.text,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _db
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("timestamp")
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<QuerySnapshot> getUserChats(String uid) {
    return _db
        .collection("chats")
        .where("participants", arrayContains: uid)
        .snapshots();
  }
}
