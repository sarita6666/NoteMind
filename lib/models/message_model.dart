import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String type;
  final String noteId;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.type,
    required this.noteId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      "senderId": senderId,
      "text": text,
      "type": type,
      "noteId": noteId,
      "timestamp": FieldValue.serverTimestamp(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic>? map, String id) {
    if (map == null) {
      return MessageModel(
        id: id,
        senderId: "",
        text: "",
        type: "text",
        noteId: "",
        timestamp: DateTime.now(),
      );
    }

    return MessageModel(
      id: id,
      senderId: map["senderId"] ?? "",
      text: map["text"] ?? "",
      type: map["type"] ?? "text",
      noteId: map["noteId"] ?? "",
      timestamp: (map["timestamp"] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
