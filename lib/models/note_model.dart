import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String title;
  final String content;
  final String userId;
  final String userName;
  final String userRole;
  final String category;
  final String imageUrl;
  final bool isPublic;

  // 🔥 NUEVO
  final DateTime createdAt;

  final List<String> likes;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.category,
    required this.imageUrl,
    required this.isPublic,
    required this.createdAt,
    this.likes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "content": content,
      "userId": userId,
      "userName": userName,
      "userRole": userRole,
      "category": category,
      "imageUrl": imageUrl,
      "isPublic": isPublic,
      "createdAt": FieldValue.serverTimestamp(),
      "likes": likes,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map, String id) {
    return NoteModel(
      id: id,
      title: map["title"] ?? "",
      content: map["content"] ?? "",
      userId: map["userId"] ?? "",
      userName: map["userName"] ?? "Usuario",
      userRole: map["userRole"] ?? "Sin rol",
      category: map["category"] ?? "",
      imageUrl: map["imageUrl"] ?? "",
      isPublic: map["isPublic"] ?? false,
      likes: List<String>.from(map["likes"] ?? []),

      createdAt: map["createdAt"] != null
          ? (map["createdAt"] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
