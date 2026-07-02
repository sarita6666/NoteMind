import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SharedNoteView extends StatelessWidget {
  final String noteId;

  const SharedNoteView({super.key, required this.noteId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nota compartida")),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("notes")
            .doc(noteId)
            .get(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final note = snapshot.data!.data() as Map<String, dynamic>?;

          if (note == null) {
            return const Center(child: Text("Nota no encontrada"));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                if ((note["imageUrl"] ?? "").isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),

                    child: Image.network(note["imageUrl"]),
                  ),

                if ((note["imageUrl"] ?? "").isNotEmpty)
                  const SizedBox(height: 15),

                if ((note["videoUrl"] ?? "").isNotEmpty)
                  Container(
                    height: 220,

                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),

                if ((note["videoUrl"] ?? "").isNotEmpty)
                  const SizedBox(height: 15),

                Text(
                  note["title"] ?? "",

                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  note["content"] ?? "",

                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
