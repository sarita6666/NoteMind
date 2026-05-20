import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/note_service.dart';
import '../../models/note_model.dart';
import '../../services/user_service.dart';
import '../../services/chat_service.dart';
import '../../models/message_model.dart';

import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/custom_alert.dart';
import '../notes/notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _shareNoteToUsers(String noteId) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return StreamBuilder(
          stream: FirebaseFirestore.instance.collection("users").snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data!.docs;

            return Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.share, color: Color(0xFF7B2FF7)),
                      SizedBox(width: 8),
                      Text(
                        "Compartir nota",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final u = users[index].data();

                        // 🔥 VALIDAR USER
                        final receiverId = u["uid"];
                        if (receiverId == null ||
                            receiverId.toString().isEmpty) {
                          return const SizedBox();
                        }

                        if (receiverId == user?.uid) {
                          return const SizedBox();
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF7B2FF7),
                            child: Text(
                              (u["name"] ?? "U")[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(u["name"] ?? ""),
                          subtitle: Text(u["email"] ?? ""),
                          onTap: () async {
                            Navigator.pop(context);

                            try {
                              // 🔥 VALIDAR USER ACTUAL
                              if (user == null || user!.uid.isEmpty) {
                                throw Exception("Usuario no válido");
                              }

                              // 🔥 VALIDAR NOTE ID
                              if (noteId.isEmpty) {
                                throw Exception("noteId vacío");
                              }

                              final noteRef = FirebaseFirestore.instance
                                  .collection("notes")
                                  .doc(noteId);

                              final noteDoc = await noteRef.get();

                              if (!noteDoc.exists) {
                                throw Exception("La nota no existe");
                              }

                              final noteData =
                                  noteDoc.data() as Map<String, dynamic>;

                              // 🔥 ASEGURAR sharedWith
                              List sharedWith =
                                  (noteData["sharedWith"] ?? []) as List;

                              if (noteData["isPublic"] != true &&
                                  !sharedWith.contains(receiverId)) {
                                await noteRef.update({
                                  "sharedWith": FieldValue.arrayUnion([
                                    receiverId,
                                  ]),
                                });
                              }

                              final chatId = _chatService.getChatId(
                                user!.uid,
                                receiverId.toString(), // 🔥 FIX
                              );

                              await _chatService.createChat(
                                user!.uid,
                                receiverId.toString(), // 🔥 FIX
                              );

                              await _chatService.sendMessage(
                                chatId: chatId,
                                message: MessageModel(
                                  id: '',
                                  senderId: user!.uid,
                                  text: "",
                                  type: "note",
                                  noteId: noteId,
                                  timestamp: DateTime.now(),
                                ),
                              );

                              await FirebaseFirestore.instance
                                  .collection("chats")
                                  .doc(chatId)
                                  .set({
                                    "participants": [
                                      user!.uid,
                                      receiverId.toString(),
                                    ],
                                    "lastMessage": "Nota compartida",
                                    "lastTimestamp":
                                        FieldValue.serverTimestamp(),
                                  }, SetOptions(merge: true));

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Nota enviada")),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  final ChatService _chatService = ChatService();
  final user = FirebaseAuth.instance.currentUser;

  String searchCategory = '';
  String selectedCategory = 'Todas';

  final List<String> categories = [
    'Todas',
    'General',
    'Trabajo',
    'Estudio',
    'Ideas',
    'Personal',
    'Importante',
    'Urgente',
    'Otros',
  ];

  List<NoteModel> _applyFilters(List<NoteModel> notes) {
    List<NoteModel> filtered = notes;

    if (selectedCategory != 'Todas') {
      filtered = filtered.where((n) => n.category == selectedCategory).toList();
    }

    if (searchCategory.isNotEmpty) {
      final query = searchCategory.toLowerCase();

      filtered = filtered.where((n) {
        return n.title.toLowerCase().contains(query) ||
            n.content.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)],
            ),
          ),
        ),
        title: StreamBuilder(
          stream: user == null
              ? const Stream.empty()
              : UserService().getUser(user!.uid),
          builder: (context, snapshot) {
            String name = user?.displayName ?? "Usuario";

            if (snapshot.hasData && snapshot.data!.data() != null) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              name = data['name'] ?? name;
            }

            return Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "NoteMind",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "Hola, $name 👋",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _confirmLogout,
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchCategory = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Buscar...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: selectedCategory,
                    items: categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Mis Notas",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B2FF7),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/notes');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text(
                            "Nueva Nota",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    StreamBuilder<List<NoteModel>>(
                      stream: NoteService().getNotes(user!.uid),
                      builder: (context, snapshot) {
                        final myNotes = _applyFilters(snapshot.data ?? []);

                        if (myNotes.isEmpty) {
                          return _emptyState("No tienes notas aún");
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: myNotes.length,
                          itemBuilder: (context, index) {
                            return _noteCard(myNotes[index]);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "Notas públicas",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 10),

                    StreamBuilder<List<NoteModel>>(
                      stream: NoteService().getAllNotes(),
                      builder: (context, snapshot) {
                        List<NoteModel> notes = _applyFilters(
                          snapshot.data ?? [],
                        );

                        if (notes.isEmpty) {
                          return _emptyState("No hay coincidencias");
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            return _noteCard(notes[index]);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/notes');
        },
        label: const Text("Nueva Nota", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF7B2FF7),
      ),

      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  Widget _noteCard(NoteModel note) {
    final isOwner = note.userId == user?.uid;
    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, size: 18),
                        color: const Color(0xFF7B2FF7),
                        onPressed: () {
                          _shareNoteToUsers(note.id);
                        },
                      ),
                    ),

                    const SizedBox(width: 5),
                    if (isOwner)
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == "edit") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotesScreen(note: note),
                              ),
                            );
                          } else if (value == "delete") {
                            await NoteService().delete(note.id);
                            CustomAlert.show(
                              context,
                              title: "Eliminado",
                              message: "Nota eliminada",
                              icon: Icons.delete,
                              color: Colors.red,
                            );
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: "edit", child: Text("Editar")),
                          PopupMenuItem(
                            value: "delete",
                            child: Text("Eliminar"),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 5),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Text(
                    note.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondChild: Text(note.content),
                ),

                const SizedBox(height: 6),

                Text(
                  isExpanded ? "Ver menos ▲" : "Ver más ▼",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Por: ${note.userName} (${note.userRole})",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 2),

                Text(
                  "Fecha: ${note.createdAt.toLocal().toString().split(' ')[0]}",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Text(
                      note.category,
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      note.isPublic ? Icons.public : Icons.lock,
                      size: 16,
                      color: note.isPublic ? Colors.green : Colors.grey,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        note.likes.contains(user!.uid)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        NoteService().toggleLike(note.id, user!.uid);
                      },
                    ),
                    Text("${note.likes.length}"),
                    const SizedBox(width: 15),
                    IconButton(
                      icon: const Icon(Icons.comment),
                      onPressed: () {
                        showComments(note);
                      },
                    ),
                    StreamBuilder(
                      stream: NoteService().getComments(note.id),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        return Text("$count");
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.menu_book_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 🔥 COMENTARIOS PRO (threads)
  void showComments(NoteModel note) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      "Comentarios",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: NoteService().getComments(note.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final all = snapshot.data!.docs;

                        final mainComments = all
                            .where((c) => (c.data() as Map)["parentId"] == null)
                            .toList();

                        if (mainComments.isEmpty) {
                          return const Center(
                            child: Text("No hay comentarios aún"),
                          );
                        }

                        return SingleChildScrollView(
                          controller: scrollController,
                          child: _buildCommentsTree(
                            snapshot.data!.docs,
                            note.id,
                          ),
                        );
                      },
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.only(
                      left: 10,
                      right: 10,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                      top: 5,
                    ),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: "Escribe un comentario...",
                              filled: true,
                              fillColor: Colors.grey.shade200,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        CircleAvatar(
                          backgroundColor: const Color(0xFF7B2FF7),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: () async {
                              if (controller.text.trim().isEmpty) return;

                              final userDoc = await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(user!.uid)
                                  .get();

                              final u = userDoc.data()!;

                              await NoteService().addComment(
                                noteId: note.id,
                                text: controller.text.trim(),
                                userName: u["name"],
                                userRole: u["role"] ?? "Sin rol",
                                userId: user!.uid,
                              );

                              controller.clear();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _chatBubble({
    required String noteId,
    required String commentId,
    required Map<String, dynamic> data,
    required bool isMe,
    int level = 0, // 🔥 para jerarquía
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: 10.0 + (level * 20), // 🔥 indentación dinámica
        right: 10,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF7B2FF7) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔥 QUIÉN RESPONDE A QUIÉN
                  if (data["parentUserName"] != null)
                    Text(
                      "↳ respondiendo a @${data["parentUserName"]}",
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: isMe ? Colors.white70 : Colors.grey,
                      ),
                    ),

                  Text(
                    "${data["userName"]} (${data["userRole"]})",
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    data["text"] ?? "",
                    style: TextStyle(color: isMe ? Colors.white : Colors.black),
                  ),

                  if (data["edited"] == true)
                    Text(
                      "editado",
                      style: TextStyle(
                        fontSize: 9,
                        color: isMe ? Colors.white70 : Colors.grey,
                      ),
                    ),

                  const SizedBox(height: 5),

                  // 🔥 BOTÓN RESPONDER
                  if (!isMe)
                    GestureDetector(
                      onTap: () {
                        _replyToComment(noteId, commentId, data["userName"]);
                      },
                      child: Text(
                        "Responder",
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.white70 : Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (isMe)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == "edit") {
                  _editComment(noteId, commentId, data["text"]);
                } else if (value == "delete") {
                  NoteService().deleteComment(
                    noteId: noteId,
                    commentId: commentId,
                  );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: "edit", child: Text("Editar")),
                PopupMenuItem(value: "delete", child: Text("Eliminar")),
              ],
            ),
        ],
      ),
    );
  }

  void _replyToComment(String noteId, String parentId, String userName) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Responder a $userName"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              final userDoc = await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user!.uid)
                  .get();

              final u = userDoc.data()!;

              await NoteService().addComment(
                noteId: noteId,
                text: controller.text.trim(),
                userName: u["name"],
                userRole: u["role"],
                userId: user!.uid,
                parentId: parentId,
                parentUserName: userName, // 🔥 CLAVE
              );

              Navigator.pop(context);
            },
            child: const Text("Responder"),
          ),
        ],
      ),
    );
  }

  void _editComment(String noteId, String commentId, String oldText) {
    final controller = TextEditingController(text: oldText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar comentario"),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              await NoteService().updateComment(
                noteId: noteId,
                commentId: commentId,
                text: controller.text.trim(),
              );

              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTree(List<QueryDocumentSnapshot> all, String noteId) {
    Map<String, List<QueryDocumentSnapshot>> map = {};

    for (var doc in all) {
      final data = doc.data() as Map<String, dynamic>;
      final parent = data["parentId"];

      if (parent == null) {
        map.putIfAbsent("root", () => []).add(doc);
      } else {
        map.putIfAbsent(parent, () => []).add(doc);
      }
    }

    List<Widget> buildTree(String parentId, int level) {
      final children = map[parentId] ?? [];

      return children.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final isMe = data["userId"] == user!.uid;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chatBubble(
              noteId: noteId,
              commentId: doc.id,
              data: data,
              isMe: isMe,
              level: level,
            ),
            ...buildTree(doc.id, level + 1), // 🔥 recursivo
          ],
        );
      }).toList();
    }

    return Column(children: buildTree("root", 0));
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('¿Estás seguro de que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
