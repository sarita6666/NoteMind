import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message_model.dart';
import 'supabase_storage_service.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  final SupabaseStorageService _storage = SupabaseStorageService();

  String getChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode
        ? "${user1}_$user2"
        : "${user2}_$user1";
  }

  Stream<int> unreadCount(String chatId, String currentUserId) {
    return FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .where("seen", isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            return doc["senderId"] != currentUserId;
          }).length;
        });
  }

  Future<void> deleteMessage({
    required String chatId,

    required String messageId,
  }) async {
    await _db
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .delete();
  }

  Future<void> markMessagesAsSeen(String chatId, String currentUserId) async {
    final messages = await _db
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .where("seen", isEqualTo: false)
        .get();

    for (final doc in messages.docs) {
      if (doc["senderId"] != currentUserId) {
        await doc.reference.update({"seen": true});
      }
    }
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

  // =====================================================
  // MENSAJE NORMAL + RESPUESTAS
  // =====================================================

  Future<void> sendMessage({
    required String chatId,

    required MessageModel message,
  }) async {
    final chatRef = _db.collection("chats").doc(chatId);

    await chatRef.collection("messages").add(message.toMap());

    await chatRef.update({
      "lastMessage": message.text.isEmpty ? "📎 Archivo" : message.text,

      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  // =====================================================
  // SUBIR IMAGEN
  // =====================================================

  Future<String?> uploadImage(Uint8List bytes, String name) async {
    return await _storage.uploadImage(bytes, name);
  }

  // =====================================================
  // SUBIR VIDEO
  // =====================================================

  Future<String?> uploadVideo(Uint8List bytes, String name) async {
    return await _storage.uploadVideo(bytes, name);
  }

  // =====================================================
  // ENVIAR MULTIMEDIA
  // =====================================================

  Future<void> sendMediaMessage({
    required String chatId,

    required String type,

    required String url,

    String replyTo = "",

    String replyText = "",

    String replySender = "",
    required String replySenderId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final message = MessageModel(
      id: "",

      senderId: user.uid,

      text: "",

      type: type,

      noteId: "",

      mediaUrl: url,

      replyTo: replyTo,

      replyText: replyText,

      replySender: replySender,
      replySenderId: replySenderId,
      timestamp: DateTime.now(),

      seen: false,
    );

    await sendMessage(chatId: chatId, message: message);
  }

  // =====================================================
  // NOTA COMPARTIDA
  // =====================================================

  Future<void> sendNote({
    required String chatId,
    required String noteId,
    required String senderName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    await _db.collection("chats").doc(chatId).collection("messages").add({
      "senderId": user!.uid,

      "type": "note",

      "noteId": noteId,

      "text": "",

      "timestamp": FieldValue.serverTimestamp(),
      "senderName": senderName,
      "seen": false,
    });

    await _db.collection("chats").doc(chatId).update({
      "lastMessage": "📄 Nota compartida",

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
        .orderBy("updatedAt", descending: true)
        .snapshots();
  }
}
