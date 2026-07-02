import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/note_service.dart';
import '../../models/note_model.dart';
import '../../services/user_service.dart';
import '../../services/chat_service.dart';
import '../../models/message_model.dart';
import 'package:video_player/video_player.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../notes/notes_screen.dart';
import 'package:flutter/services.dart';

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
                      Icon(Icons.share, color: Color(0xFF1565C0)),
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
                            backgroundColor: const Color(0xFF1565C0),
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
                              if (user == null || user!.uid.isEmpty) {
                                throw Exception("Usuario no válido");
                              }

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
                                receiverId.toString(),
                              );

                              await _chatService.createChat(
                                user!.uid,
                                receiverId.toString(),
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
                                  seen: false,
                                  replyTo: "",
                                  replyText: "",
                                  replySender: "",
                                  replySenderId: "",
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
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F9),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 5,
        shadowColor: Colors.black26,
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
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
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.tune, color: Colors.white),
                tooltip: "Filtros",
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _confirmLogout,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 4,

              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),

                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchCategory = value;
                        });
                      },

                      decoration: InputDecoration(
                        hintText: "Buscar notas...",

                        prefixIcon: const Icon(Icons.search),

                        filled: true,

                        fillColor: Colors.white,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),

                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

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
                                  fontSize: 28,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // AQUI DEJAS IGUAL TUS STREAMBUILDER
                          const SizedBox(height: 15),

                          StreamBuilder<List<NoteModel>>(
                            stream: NoteService().getNotes(user!.uid),
                            builder: (context, snapshot) {
                              final myNotes = _applyFilters(
                                snapshot.data ?? [],
                              );

                              myNotes.sort(
                                (a, b) => b.createdAt.compareTo(a.createdAt),
                              );

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

                              notes.sort(
                                (a, b) => b.createdAt.compareTo(a.createdAt),
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
                          StreamBuilder<List<NoteModel>>(
                            stream: NoteService().getNotes(user!.uid),

                            builder: (context, snapshot) {
                              final notes = _applyFilters(snapshot.data ?? []);

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
            if (!isMobile) _buildCategoryPanel(),
          ],
        ),
      ),

      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
      endDrawer: isMobile
          ? Drawer(width: 260, child: SafeArea(child: _buildCategoryPanel()))
          : null,
    );
  }

  Widget _buildCategoryPanel() {
    return Container(
      width: 160,
      decoration: const BoxDecoration(
        color: Color(0xFFE3F2FD),
        border: Border(left: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),

            child: SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.all(14),
                  foregroundColor: Colors.white,
                ),

                onPressed: () {
                  Navigator.pushNamed(context, '/notes');
                },

                child: const Text("＋ Nota"),
              ),
            ),
          ),

          const Divider(),

          Expanded(
            child: ListView.builder(
              itemCount: categories.length,

              itemBuilder: (context, index) {
                final cat = categories[index];
                return MouseRegion(
                  cursor: SystemMouseCursors.click,

                  child: StatefulBuilder(
                    builder: (context, setHover) {
                      bool hover = false;

                      return MouseRegion(
                        onEnter: (_) {
                          setHover(() {
                            hover = true;
                          });
                        },

                        onExit: (_) {
                          setHover(() {
                            hover = false;
                          });
                        },

                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),

                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),

                          child: Material(
                            color: selectedCategory == cat
                                ? const Color(0xFF1565C0)
                                : hover
                                ? Colors.white
                                : Colors.transparent,

                            borderRadius: BorderRadius.circular(12),

                            child: ListTile(
                              title: Text(
                                cat,

                                style: TextStyle(
                                  color: selectedCategory == cat
                                      ? Colors.white
                                      : Colors.black87,

                                  fontWeight: selectedCategory == cat
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),

                              onTap: () {
                                setState(() {
                                  selectedCategory = cat;
                                });

                                if (MediaQuery.of(context).size.width < 700) {
                                  Navigator.pop(context); // Cierra el Drawer
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  //NoteCard
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

            margin: const EdgeInsets.only(bottom: 10),

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(14),

              boxShadow: [
                const BoxShadow(color: Colors.black12, blurRadius: 5),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // =========================
                // CABECERA
                // =========================
                Row(
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("users")
                          .doc(note.userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String photoUrl = "";
                        String userName = note.userName;
                        String userRole = note.userRole;

                        if (snapshot.hasData && snapshot.data!.exists) {
                          final userData =
                              snapshot.data!.data() as Map<String, dynamic>;

                          photoUrl = userData["photoUrl"] ?? "";
                          userName = userData["name"] ?? note.userName;
                          userRole = userData["role"] ?? note.userRole;
                        }

                        return Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundImage: photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: photoUrl.isEmpty
                                    ? Text(
                                        userName[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "$userName ($userRole)",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),

                                    Text(
                                      note.createdAt.toLocal().toString().split(
                                        ' ',
                                      )[0],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.send,
                        size: 20,
                        color: Color(0xFF1565C0),
                      ),

                      onPressed: () {
                        _shareNoteToUsers(note.id);
                      },
                    ),

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
                          }

                          if (value == "delete") {
                            await NoteService().delete(note.id);
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

                const SizedBox(height: 10),

                // =========================
                // IMAGEN
                // =========================
                if (note.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),

                    child: SizedBox(
                      height: 180,

                      width: double.infinity,

                      child: Image.network(note.imageUrl, fit: BoxFit.cover),
                    ),
                  ),

                if (note.videoUrl.isNotEmpty) VideoPreview(url: note.videoUrl),

                const SizedBox(height: 10),

                // =========================
                // TITULO
                // =========================
                Text(
                  note.title,

                  style: const TextStyle(
                    fontSize: 16,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                // =========================
                // TEXTO
                // =========================
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

                const SizedBox(height: 4),

                Text(
                  isExpanded ? "Ver menos ▲" : "Ver más ▼",

                  style: const TextStyle(
                    color: Color(0xFF1565C0),

                    fontSize: 11,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Divider(),

                // =========================
                // ACCIONES
                // =========================
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

                    const SizedBox(width: 10),

                    IconButton(
                      icon: const Icon(Icons.comment),

                      onPressed: () {
                        showComments(note);
                      },
                    ),

                    StreamBuilder(
                      stream: NoteService().getComments(note.id),

                      builder: (context, snapshot) {
                        return Text("${snapshot.data?.docs.length ?? 0}");
                      },
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.smart_toy,

                        color: Color(0xFF1565C0),
                      ),

                      onPressed: () {
                        _askAIAboutNote(note);
                      },
                    ),

                    const Spacer(),

                    if (!isOwner)
                      IconButton(
                        icon: const Icon(
                          Icons.bookmark_add,

                          color: Colors.orange,
                        ),

                        onPressed: () {
                          _saveNoteToProfile(note);
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
                          backgroundColor: const Color(0xFF1565C0),
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
    int level = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: 10.0 + (level * 20),
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
                color: isMe ? const Color(0xFF1565C0) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  if (!isMe)
                    GestureDetector(
                      onTap: () {
                        _replyToComment(noteId, commentId, data["userName"]);
                      },
                      child: Text(
                        "Responder",
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe
                              ? Colors.white70
                              : const Color(0xFF1565C0),
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
                parentUserName: userName,
              );

              Navigator.pop(context);
            },
            child: const Text("Responder"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNoteToProfile(NoteModel note) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) return;

      final existing = await FirebaseFirestore.instance
          .collection("saved_notes")
          .where("noteId", isEqualTo: note.id)
          .where("savedBy", isEqualTo: currentUser.uid)
          .get();

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Ya guardaste esta nota")));
        return;
      }

      await FirebaseFirestore.instance.collection("saved_notes").add({
        // Identificación
        "noteId": note.id,
        "savedBy": currentUser.uid,

        // Información de la nota
        "title": note.title,
        "content": note.content,
        "category": note.category,
        "imageUrl": note.imageUrl,
        "videoUrl": note.videoUrl,

        // Información del autor original
        "userId": note.userId,
        "userName": note.userName,
        "userRole": note.userRole,

        // Fecha original de la nota
        "createdAt": Timestamp.fromDate(note.createdAt),

        // Fecha en la que fue guardada (opcional)
        "savedAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nota guardada en tu perfil")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
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
            ...buildTree(doc.id, level + 1),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Cerrar sesión?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('¿Estás seguro de que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  void _askAIAboutNote(NoteModel note) {
    final questionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Color(0xFF1565C0)),
            SizedBox(width: 10),
            Text("Preguntar a la IA"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    note.content,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: questionCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Ej: Resume esta nota o explícame este tema",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancelar"),
          ),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final question = questionCtrl.text.trim();

              if (question.isEmpty) return;

              Navigator.pop(context);

              final prompt =
                  """
Eres una IA educativa integrada en una aplicación de notas llamada NoteMind.

Debes analizar la nota del usuario y responder basándote únicamente en el contenido proporcionado.

NOTA DEL USUARIO

Título:
${note.title}

Contenido:
${note.content}

${note.imageUrl.isNotEmpty ? "Imagen de la nota: ${note.imageUrl}" : ""}

PREGUNTA DEL USUARIO:
$question

Responde de manera clara, útil y natural.
""";
              Navigator.pushReplacementNamed(
                context,
                "/chat_ai",
                arguments: {"prompt": prompt, "noteTitle": note.title},
              );
            },
            icon: const Icon(Icons.send),
            label: const Text("Preguntar"),
          ),
        ],
      ),
    );
  }
}

class VideoPreview extends StatefulWidget {
  final String url;

  const VideoPreview({super.key, required this.url});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });

    controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _seekForward() async {
    final pos = await controller.position;
    if (pos != null) {
      await controller.seekTo(pos + const Duration(seconds: 10));
    }
  }

  Future<void> _seekBackward() async {
    final pos = await controller.position;
    if (pos != null) {
      final newPos = pos - const Duration(seconds: 10);
      await controller.seekTo(newPos.isNegative ? Duration.zero : newPos);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),

        VideoProgressIndicator(
          controller,
          allowScrubbing: true,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_10),
              onPressed: _seekBackward,
            ),

            IconButton(
              icon: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              onPressed: () {
                setState(() {
                  controller.value.isPlaying
                      ? controller.pause()
                      : controller.play();
                });
              },
            ),

            IconButton(
              icon: const Icon(Icons.forward_10),
              onPressed: _seekForward,
            ),

            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: () async {
                final wasPlaying = controller.value.isPlaying;
                final position = controller.value.position;

                await controller.pause();

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenVideo(
                      url: widget.url,
                      startPosition: position,
                      autoPlay: wasPlaying,
                    ),
                  ),
                );

                if (result != null) {
                  await controller.seekTo(result["position"]);

                  if (result["playing"] == true) {
                    await Future.delayed(
                      const Duration(seconds: 0, milliseconds: 50),
                    );
                    await controller.play();
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class FullScreenVideo extends StatefulWidget {
  final String url;
  final Duration startPosition;
  final bool autoPlay;

  const FullScreenVideo({
    super.key,
    required this.url,
    required this.startPosition,
    required this.autoPlay,
  });

  @override
  State<FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<FullScreenVideo> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    controller.initialize().then((_) async {
      await controller.seekTo(widget.startPosition);

      controller.setLooping(false);

      if (widget.autoPlay) {
        await controller.play();
      }

      if (mounted) {
        setState(() {});
      }
    });

    controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<bool> _closeVideo() async {
    Navigator.pop(context, {
      "position": controller.value.position,
      "playing": controller.value.isPlaying,
    });

    return true;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _forward() async {
    final pos = await controller.position;
    if (pos != null) {
      await controller.seekTo(pos + const Duration(seconds: 10));
    }
  }

  Future<void> _rewind() async {
    final pos = await controller.position;
    if (pos != null) {
      final newPos = pos - const Duration(seconds: 10);

      await controller.seekTo(newPos.isNegative ? Duration.zero : newPos);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
            ),

            VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: const EdgeInsets.all(12),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.replay_10),
                  onPressed: _rewind,
                ),

                IconButton(
                  color: Colors.white,
                  icon: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: () {
                    setState(() {
                      controller.value.isPlaying
                          ? controller.pause()
                          : controller.play();
                    });
                  },
                ),

                IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.forward_10),
                  onPressed: _forward,
                ),

                IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.fullscreen_exit),
                  onPressed: _closeVideo,
                ),
              ],
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
