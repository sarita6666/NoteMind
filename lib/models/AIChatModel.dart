class AIChatModel {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;

  AIChatModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
  });

  factory AIChatModel.fromFirestore(String id, Map<String, dynamic> data) {
    return AIChatModel(
      id: id,
      userId: data["userId"] ?? "",
      title: data["title"] ?? "Nuevo chat",
      createdAt: (data["createdAt"]?.toDate()) ?? DateTime.now(),
    );
  }
}
