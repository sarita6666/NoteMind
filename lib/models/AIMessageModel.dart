class AIMessageModel {
  final String id;
  final String sender;
  final String text;
  final DateTime timestamp;

  AIMessageModel({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  factory AIMessageModel.fromFirestore(String id, Map<String, dynamic> data) {
    return AIMessageModel(
      id: id,
      sender: data["sender"] ?? "",
      text: data["text"] ?? "",
      timestamp: (data["timestamp"]?.toDate()) ?? DateTime.now(),
    );
  }
}
