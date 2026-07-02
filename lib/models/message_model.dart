import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;

  final String senderId;
  final String senderName;
  final String text;

  // text | image | video | note
  final String type;

  final String noteId;

  // Para imágenes y videos
  final String mediaUrl;

  // Respuestas tipo WhatsApp
  final String replyTo;

  final String replyText;

  final String replySender;
  final String replySenderId;
  final DateTime timestamp;

  final bool seen;

  MessageModel({
    required this.id,

    required this.senderId,
    required this.replySenderId,
    required this.text,

    required this.type,

    required this.noteId,

    this.mediaUrl = "",
    this.senderName = "",
    this.replyTo = "",

    this.replyText = "",

    this.replySender = "",

    required this.timestamp,

    required this.seen,
  });

  Map<String, dynamic> toMap() {
    return {
      "senderId": senderId,

      "text": text,

      "type": type,
      "senderName": senderName,
      "noteId": noteId,

      // multimedia
      "mediaUrl": mediaUrl,

      // respuesta
      "replyTo": replyTo,

      "replyText": replyText,

      "replySender": replySender,
      "replySenderId": replySenderId,

      "timestamp": FieldValue.serverTimestamp(),

      "seen": seen,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,

      senderId: map["senderId"] ?? "",

      text: map["text"] ?? "",

      type: map["type"] ?? "text",
      senderName: map["senderName"] ?? "",
      noteId: map["noteId"] ?? "",

      mediaUrl: map["mediaUrl"] ?? "",

      replyTo: map["replyTo"] ?? "",

      replyText: map["replyText"] ?? "",

      replySender: map["replySender"] ?? "",
      replySenderId: map["replySenderId"] ?? "",
      timestamp: (map["timestamp"] as Timestamp?)?.toDate() ?? DateTime.now(),

      seen: map["seen"] ?? false,
    );
  }
}
