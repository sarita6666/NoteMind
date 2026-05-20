import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_alert.dart';
import '../../models/message_model.dart';
import '../../widgets/custom_bottom_nav.dart';

class ChatComunitarioScreen extends StatefulWidget {
  const ChatComunitarioScreen({super.key});

  @override
  State<ChatComunitarioScreen> createState() => _ChatComunitarioScreenState();
}

class _ChatComunitarioScreenState extends State<ChatComunitarioScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final AuthService _authService = AuthService();

  String? selectedUserId;
  String selectedUserName = "";
  String search = "";

  Stream<List<MessageModel>>? messagesStream;

  void _logout() async {
    await _authService.logout();

    CustomAlert.show(
      context,
      title: "Sesión cerrada",
      message: "Has cerrado sesión correctamente",
      icon: Icons.logout,
      color: Colors.green,
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacementNamed(context, "/login");
    });
  }

  void openChat(String uid, String name) {
    if (uid.isEmpty) return;

    final chatId = _chatService.getChatId(user!.uid, uid);

    _chatService.createChat(user!.uid, uid);

    setState(() {
      selectedUserId = uid;
      selectedUserName = name;
      messagesStream = _chatService.getMessages(chatId);
    });
  }

  void sendMessage() async {
    if (_controller.text.trim().isEmpty || selectedUserId == null) return;

    final chatId = _chatService.getChatId(user!.uid, selectedUserId!);

    await _chatService.sendMessage(
      chatId: chatId,
      message: MessageModel(
        id: '',
        senderId: user!.uid,
        text: _controller.text.trim(),
        type: "text",
        noteId: "",
        timestamp: DateTime.now(),
      ),
    );

    _controller.clear();
  }

  Future<List<QueryDocumentSnapshot>> _getShareableNotes() async {
    final myNotes = await FirebaseFirestore.instance
        .collection("notes")
        .where("userId", isEqualTo: user!.uid)
        .get();

    final publicNotes = await FirebaseFirestore.instance
        .collection("notes")
        .where("isPublic", isEqualTo: true)
        .get();

    final all = [...myNotes.docs, ...publicNotes.docs];
    final unique = {for (var n in all) n.id: n}.values.toList();

    return unique;
  }

  void _selectNote() {
    if (selectedUserId == null) return;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _getShareableNotes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final notes = snapshot.data!;

            if (notes.isEmpty) {
              return const Center(child: Text("No hay notas disponibles"));
            }

            return ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final raw = notes[index].data();
                if (raw == null) return const SizedBox();

                final note = raw as Map<String, dynamic>;

                return ListTile(
                  leading: Icon(
                    note["isPublic"] == true ? Icons.public : Icons.lock,
                    color: note["isPublic"] == true
                        ? Colors.green
                        : Colors.grey,
                  ),
                  title: Text(note["title"] ?? ""),
                  subtitle: Text(
                    note["content"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    Navigator.pop(context);

                    if (note["isPublic"] != true) {
                      await FirebaseFirestore.instance
                          .collection("notes")
                          .doc(notes[index].id)
                          .update({
                            "sharedWith": FieldValue.arrayUnion([
                              selectedUserId,
                            ]),
                          });
                    }

                    final chatId = _chatService.getChatId(
                      user!.uid,
                      selectedUserId!,
                    );

                    await _chatService.sendMessage(
                      chatId: chatId,
                      message: MessageModel(
                        id: '',
                        senderId: user!.uid,
                        text: "",
                        type: "note",
                        noteId: notes[index].id,
                        timestamp: DateTime.now(),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget contacts() {
    return StreamBuilder(
      stream: _chatService.getUserChats(user!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final chats = snapshot.data!.docs;

        if (chats.isEmpty) {
          return Column(
            children: const [
              SizedBox(height: 40),
              Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                "Buscar contactos",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                "Aún no tienes conversaciones",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Contactos",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ...chats.map((chat) {
              final participants = List<String>.from(chat["participants"]);
              final otherId = participants.firstWhere((id) => id != user!.uid);

              return FutureBuilder(
                future: UserService().getUser(otherId).first,
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox();

                  final raw = snap.data!.data();
                  if (raw == null) return const SizedBox();

                  final data = raw as Map<String, dynamic>;

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(data["name"] ?? ""),
                    subtitle: Text(chat["lastMessage"] ?? ""),
                    onTap: () => openChat(otherId, data["name"] ?? ""),
                  );
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget users() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: UserService().searchUsers(search),
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Todos los usuarios",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ...users.map((u) {
              if (u["email"] == user?.email) return const SizedBox();

              final uid = u["uid"] ?? "";
              if (uid.isEmpty) return const SizedBox();

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(u["name"] ?? ""),
                subtitle: Text(u["email"] ?? ""),
                onTap: () => openChat(uid, u["name"] ?? ""),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget chatView() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: messagesStream,
            builder: (context, snapshot) {
              final messages = snapshot.data ?? [];

              if (messages.isEmpty) {
                return const Center(child: Text("Envía el primer mensaje 👋"));
              }

              return ListView.builder(
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final msg = messages[i];
                  final isMe = msg.senderId == user!.uid;

                  if (msg.type == "note") {
                    return FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection("notes")
                          .doc(msg.noteId)
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == null) {
                          return const SizedBox();
                        }

                        final raw = snapshot.data!.data();
                        if (raw == null) {
                          return const Text("Nota no disponible");
                        }

                        final note = raw as Map<String, dynamic>;
                        final currentUserId = user!.uid;

                        final canAccess =
                            note["isPublic"] == true ||
                            note["userId"] == currentUserId ||
                            (note["sharedWith"] ?? []).contains(currentUserId);

                        if (!canAccess) {
                          return const Text("Sin acceso a esta nota");
                        }

                        return Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note["title"] ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                note["content"] ?? "",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Por: ${note["userName"] ?? ""} (${note["userRole"] ?? ""})",
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? const Color(0xFF7B2FF7)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.note, color: Colors.white),
                  onPressed: _selectMyNotes,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Escribe un mensaje...",
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF7B2FF7)),
                onPressed: sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selectMyNotes() {
    if (selectedUserId == null) return;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection("notes")
              .where("userId", isEqualTo: user!.uid)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final notes = snapshot.data!.docs;

            if (notes.isEmpty) {
              return const Center(child: Text("No tienes notas"));
            }

            return ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final raw = notes[index].data();
                if (raw == null) return const SizedBox();

                final note = raw as Map<String, dynamic>;

                return ListTile(
                  leading: Icon(
                    note["isPublic"] == true ? Icons.public : Icons.lock,
                    color: note["isPublic"] == true
                        ? Colors.green
                        : Colors.grey,
                  ),
                  title: Text(note["title"] ?? ""),
                  subtitle: Text(
                    note["content"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    Navigator.pop(context);

                    if (note["isPublic"] != true) {
                      await FirebaseFirestore.instance
                          .collection("notes")
                          .doc(notes[index].id)
                          .update({
                            "sharedWith": FieldValue.arrayUnion([
                              selectedUserId,
                            ]),
                          });
                    }

                    final chatId = _chatService.getChatId(
                      user!.uid,
                      selectedUserId!,
                    );

                    await _chatService.sendMessage(
                      chatId: chatId,
                      message: MessageModel(
                        id: '',
                        senderId: user!.uid,
                        text: "",
                        type: "note",
                        noteId: notes[index].id,
                        timestamp: DateTime.now(),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)],
            ),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              selectedUserId == null ? "NoteMind" : selectedUserName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: selectedUserId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    selectedUserId = null;
                  });
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: "Cerrar sesión",
          ),
        ],
      ),
      body: selectedUserId == null
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) {
                      setState(() {
                        search = v;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Buscar usuario...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  contacts(),
                  const SizedBox(height: 20),
                  users(),
                ],
              ),
            )
          : chatView(),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }
}
