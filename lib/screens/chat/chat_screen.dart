import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import 'package:video_player/video_player.dart';
import '../../widgets/custom_alert.dart';
import '../../widgets/custom_bottom_nav.dart';

import '../../models/message_model.dart';
import 'shared_note_view.dart';

import 'package:image_picker/image_picker.dart';

import '../../services/supabase_storage_service.dart';

class ChatComunitarioScreen extends StatefulWidget {
  const ChatComunitarioScreen({super.key});

  @override
  State<ChatComunitarioScreen> createState() => _ChatComunitarioScreenState();
}

class _ChatComunitarioScreenState extends State<ChatComunitarioScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();

  final SupabaseStorageService _storage = SupabaseStorageService();

  MessageModel? replyingMessage;

  final TextEditingController _controller = TextEditingController();

  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();

  String highlightedMessageId = "";
  String currentUserName = "";
  String? selectedUserId;
  String selectedUserPhoto = "";
  String selectedUserName = "";

  String search = "";

  Stream<List<MessageModel>>? messagesStream;
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // 🔵 LOGOUT
  void _logout() async {
    await _authService.logout();

    await CustomAlert.show(
      context,
      title: "Sesión cerrada",
      message: "Has cerrado sesión correctamente",
      icon: Icons.logout,
      color: Colors.blue,
    );

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  Future<void> _loadCurrentUser() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    final data = doc.data();

    if (data == null) return;

    setState(() {
      currentUserName = data["name"] ?? "Usuario";
    });
  }

  Widget mediaMessage(MessageModel msg) {
    if (msg.type == "image") {
      return ImagePreview(url: msg.mediaUrl, width: 260, height: 200);
    }

    if (msg.type == "video") {
      return VideoPreview(url: msg.mediaUrl);
    }

    return const SizedBox();
  }

  // 🔵 ABRIR CHAT
  Future<void> openChat(String uid, String name) async {
    if (uid.isEmpty) return;

    final chatId = _chatService.getChatId(user!.uid, uid);

    await _chatService.createChat(user!.uid, uid);

    await _chatService.markMessagesAsSeen(chatId, user!.uid);
    final userData = await UserService().getUser(uid).first;

    final data = userData.data() as Map<String, dynamic>?;

    setState(() {
      selectedUserId = uid;

      selectedUserName = name;

      selectedUserPhoto = data?["photoUrl"]?.toString() ?? "";

      messagesStream = _chatService.getMessages(chatId);
    });
  }
  // =====================================================
  // MENU ADJUNTOS
  // =====================================================

  void openAttachmentMenu() {
    showModalBottomSheet(
      context: context,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (_) {
        return SizedBox(
          height: 220,

          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.note, color: Colors.blue),

                title: const Text("Nota"),

                onTap: () {
                  Navigator.pop(context);

                  _selectNote();
                },
              ),

              ListTile(
                leading: const Icon(Icons.image, color: Colors.green),

                title: const Text("Imagen"),

                onTap: () {
                  Navigator.pop(context);

                  pickImage();
                },
              ),

              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.red),

                title: const Text("Video"),

                onTap: () {
                  Navigator.pop(context);

                  pickVideo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget messageActions(MessageModel msg) {
    final isMyMessage = msg.senderId == user!.uid;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),

      onSelected: (value) async {
        if (value == "reply") {
          startReply(msg);
          return;
        }

        if (value == "delete") {
          final chatId = _chatService.getChatId(user!.uid, selectedUserId!);

          await _chatService.deleteMessage(chatId: chatId, messageId: msg.id);
        }
      },

      itemBuilder: (_) {
        final items = <PopupMenuEntry<String>>[
          const PopupMenuItem(
            value: "reply",
            child: Row(
              children: [
                Icon(Icons.reply),
                SizedBox(width: 8),
                Text("Responder"),
              ],
            ),
          ),
        ];

        if (isMyMessage) {
          items.add(
            const PopupMenuItem(
              value: "delete",
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 8),
                  Text("Eliminar"),
                ],
              ),
            ),
          );
        }

        return items;
      },
    );
  }
  // =====================================================
  // IMAGEN
  // =====================================================

  Future<void> pickImage() async {
    if (selectedUserId == null) return;

    final file = await _picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final bytes = await file.readAsBytes();

    final url = await _storage.uploadImage(
      bytes,

      "chat/${DateTime.now().millisecondsSinceEpoch}.png",
    );

    if (url == null) return;

    final chatId = _chatService.getChatId(user!.uid, selectedUserId!);

    await _chatService.sendMediaMessage(
      chatId: chatId,

      type: "image",

      url: url,

      replyTo: replyingMessage?.id ?? "",

      replyText: replyingMessage?.text ?? "",

      replySender: replyingMessage?.senderId ?? "",
      replySenderId: replyingMessage?.senderId ?? "",
    );

    setState(() {
      replyingMessage = null;
    });
  }

  // =====================================================
  // VIDEO
  // =====================================================

  Future<void> pickVideo() async {
    if (selectedUserId == null) return;

    final file = await _picker.pickVideo(source: ImageSource.gallery);

    if (file == null) return;

    final bytes = await file.readAsBytes();

    final url = await _storage.uploadVideo(
      bytes,

      "chat/${DateTime.now().millisecondsSinceEpoch}.mp4",
    );

    if (url == null) return;

    final chatId = _chatService.getChatId(user!.uid, selectedUserId!);

    await _chatService.sendMediaMessage(
      chatId: chatId,

      type: "video",

      url: url,

      replyTo: replyingMessage?.id ?? "",

      replyText: replyingMessage?.text ?? "",

      replySender: replyingMessage?.senderId ?? "",
      replySenderId: replyingMessage?.senderId ?? "",
    );

    setState(() {
      replyingMessage = null;
    });
  }

  void startReply(MessageModel message) {
    setState(() {
      replyingMessage = message;
    });
  }

  // 🔵 ENVIAR MENSAJE
  void sendMessage() async {
    if (_controller.text.trim().isEmpty || selectedUserId == null) {
      return;
    }

    final chatId = _chatService.getChatId(user!.uid, selectedUserId!);

    await _chatService.sendMessage(
      chatId: chatId,

      message: MessageModel(
        id: '',
        senderId: user!.uid,
        senderName: currentUserName,

        text: _controller.text.trim(),

        type: "text",

        noteId: "",

        mediaUrl: "",

        replyTo: replyingMessage?.id ?? "",

        replyText: replyingMessage?.text ?? "",
        replySenderId: replyingMessage?.senderId ?? "",

        timestamp: DateTime.now(),

        seen: false,
      ),
    );

    _controller.clear();
    setState(() {
      replyingMessage = null;
    });
  }

  // 🔵 OBTENER NOTAS
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

  // 🔵 SELECCIONAR NOTA
  void _selectNote() {
    if (selectedUserId == null) return;

    showModalBottomSheet(
      context: context,

      builder: (_) {
        return FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _getShareableNotes(),

          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              );
            }

            final notes = snapshot.data!;

            if (notes.isEmpty) {
              return const Center(child: Text("No hay notas disponibles"));
            }

            return ListView.builder(
              itemCount: notes.length,

              itemBuilder: (context, index) {
                final raw = notes[index].data();

                if (raw == null) {
                  return const SizedBox();
                }

                final note = raw as Map<String, dynamic>;

                return ListTile(
                  leading: Icon(
                    note["isPublic"] == true ? Icons.public : Icons.lock,

                    color: note["isPublic"] == true ? Colors.blue : Colors.grey,
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
                        seen: false,
                        replySenderId: replyingMessage?.senderId ?? "",
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

  // 🔵 CONTACTOS
  Widget contacts() {
    return StreamBuilder(
      stream: _chatService.getUserChats(user!.uid),

      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final chats = snapshot.data!.docs;

        if (chats.isEmpty) {
          return Column(
            children: const [
              SizedBox(height: 40),

              Icon(Icons.chat_bubble_outline, size: 60, color: Colors.blueGrey),

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

              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 10),

            ...chats.map((chat) {
              final participants = List<String>.from(chat["participants"]);

              final otherId = participants.firstWhere((id) => id != user!.uid);

              return FutureBuilder(
                future: UserService().getUser(otherId).first,

                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const SizedBox();
                  }

                  final raw = snap.data!.data();

                  if (raw == null) {
                    return const SizedBox();
                  }

                  final data = raw as Map<String, dynamic>;

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundImage: (data["photoUrl"] ?? "").isNotEmpty
                          ? NetworkImage(data["photoUrl"])
                          : null,

                      child: (data["photoUrl"] ?? "").isEmpty
                          ? Text((data["name"] ?? "U")[0].toUpperCase())
                          : null,
                    ),

                    title: Text(data["name"] ?? ""),

                    subtitle: Text(chat["lastMessage"] ?? ""),

                    trailing: StreamBuilder<int>(
                      stream: _chatService.unreadCount(chat.id, user!.uid),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;

                        if (count == 0) {
                          return const SizedBox();
                        }

                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "$count",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),

                    onTap: () => openChat(otherId, data["name"] ?? ""),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }

  // 🔵 USUARIOS
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

              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 10),

            ...users.map((u) {
              if (u["email"] == user?.email) {
                return const SizedBox();
              }

              final uid = u["uid"] ?? "";

              if (uid.isEmpty) {
                return const SizedBox();
              }

              return ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundImage: (u["photoUrl"] ?? "").isNotEmpty
                      ? NetworkImage(u["photoUrl"])
                      : null,

                  child: (u["photoUrl"] ?? "").isEmpty
                      ? Text((u["name"] ?? "U")[0].toUpperCase())
                      : null,
                ),
                title: Text(u["name"] ?? ""),

                subtitle: Text(u["email"] ?? ""),

                onTap: () => openChat(uid, u["name"] ?? ""),
              );
            }),
          ],
        );
      },
    );
  }

  Widget replyUserName(String uid) {
    if (uid.isEmpty) {
      return const Text(
        "Usuario",
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .snapshots(),

      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text(
            "Usuario",
            style: TextStyle(fontWeight: FontWeight.bold),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        return Text(
          data?["name"] ?? "Usuario",

          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget userNameFromId(String uid, TextStyle? style) {
    if (uid.isEmpty) {
      return Text("Usuario", style: style);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text("Usuario", style: style);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        return Text(data?["name"] ?? "Usuario", style: style);
      },
    );
  }

  Future<void> jumpToMessage(
    String messageId,
    Map<String, int> messageIndexes,
  ) async {
    if (!messageIndexes.containsKey(messageId)) {
      return;
    }

    final index = messageIndexes[messageId]!;

    await _scrollController.animateTo(
      index * 90.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    setState(() {
      highlightedMessageId = messageId;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          highlightedMessageId = "";
        });
      }
    });
  }

  //  CHAT VIEW
  Widget chatView() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: messagesStream,

            builder: (context, snapshot) {
              final messages = snapshot.data ?? [];
              final Map<String, int> messageIndexes = {};

              for (int i = 0; i < messages.length; i++) {
                messageIndexes[messages[i].id] = i;
              }
              if (messages.isEmpty) {
                return const Center(child: Text("Envía el primer mensaje 👋"));
              }

              return ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,

                itemBuilder: (_, i) {
                  final msg = messages[i];

                  final isMe = msg.senderId == user!.uid;

                  // 🔵 NOTAS
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

                        final note = raw;
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,

                          child: Row(
                            mainAxisSize: MainAxisSize.min,

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Flexible(
                                child: Align(
                                  alignment: isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,

                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          0.70,
                                    ),

                                    child: Container(
                                      margin: const EdgeInsets.all(6),

                                      padding: const EdgeInsets.all(10),

                                      decoration: BoxDecoration(
                                        border: highlightedMessageId == msg.id
                                            ? Border.all(
                                                color: Colors.amber,
                                                width: 3,
                                              )
                                            : null,
                                        color: Colors.blue.shade100,

                                        borderRadius: BorderRadius.circular(12),
                                      ),

                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,

                                        children: [
                                          if ((note["imageUrl"] ?? "")
                                              .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),

                                              child: ImagePreview(
                                                url: note["imageUrl"],
                                                width: 320,
                                                height: 200,
                                              ),
                                            ),
                                          if ((note["videoUrl"] ?? "")
                                              .isNotEmpty)
                                            SizedBox(
                                              height: 250,

                                              child: VideoPreview(
                                                url: note["videoUrl"],
                                              ),
                                            ),
                                          if ((note["imageUrl"] ?? "")
                                                  .isNotEmpty ||
                                              (note["videoUrl"] ?? "")
                                                  .isNotEmpty)
                                            const SizedBox(height: 10),

                                          Text(
                                            note["title"] ?? "",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),

                                          const SizedBox(height: 5),

                                          Text(
                                            note["content"] ?? "",
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              messageActions(msg),
                            ],
                          ),
                        );
                      },
                    );
                  }
                  // 🔵 IMAGEN / VIDEO

                  if (msg.type == "image" || msg.type == "video") {
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,

                      child: Row(
                        mainAxisSize: MainAxisSize.min,

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.all(8),

                              padding: const EdgeInsets.all(5),

                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.blue.shade100
                                    : Colors.grey.shade200,

                                borderRadius: BorderRadius.circular(15),
                              ),

                              child: mediaMessage(msg),
                            ),
                          ),

                          messageActions(msg),
                        ],
                      ),
                    );
                  }
                  // 🔵 MENSAJES
                  return GestureDetector(
                    onLongPress: isMe
                        ? () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Eliminar mensaje"),
                                content: const Text(
                                  "¿Deseas eliminar este mensaje?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancelar"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("Eliminar"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final chatId = _chatService.getChatId(
                                user!.uid,
                                selectedUserId!,
                              );

                              await _chatService.deleteMessage(
                                chatId: chatId,
                                messageId: msg.id,
                              );
                            }
                          }
                        : null,

                    child: Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,

                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Flexible(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.70,
                              ),

                              child: Container(
                                margin: const EdgeInsets.all(6),

                                padding: const EdgeInsets.all(12),

                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFF1976D2)
                                      : Colors.grey.shade300,

                                  borderRadius: BorderRadius.circular(12),
                                ),

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  mainAxisSize: MainAxisSize.min,

                                  children: [
                                    if (msg.replyTo.isNotEmpty ||
                                        msg.replyText.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          jumpToMessage(
                                            msg.replyTo,
                                            messageIndexes,
                                          );
                                        },

                                        child: Container(
                                          padding: const EdgeInsets.all(8),

                                          decoration: BoxDecoration(
                                            color: isMe
                                                ? Colors.blue.shade700
                                                : Colors.grey.shade400,

                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),

                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,

                                            children: [
                                              userNameFromId(
                                                msg.replySenderId,
                                                const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),

                                              const SizedBox(height: 3),

                                              Text(
                                                msg.replyText.isNotEmpty
                                                    ? msg.replyText
                                                    : "Mensaje",

                                                maxLines: 2,

                                                overflow: TextOverflow.ellipsis,

                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    Text(
                                      msg.text,

                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          messageActions(msg),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        //  RESPONDIENDO A
        if (replyingMessage != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),

            padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(
              color: Colors.blue.shade50,

              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),

                topRight: Radius.circular(12),
              ),

              border: Border.all(color: Colors.blue.shade200),
            ),

            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        "Respondiendo a",

                        style: TextStyle(
                          fontWeight: FontWeight.bold,

                          color: Colors.blue,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        replyingMessage!.text.isNotEmpty
                            ? replyingMessage!.text
                            : replyingMessage!.type == "image"
                            ? "🖼 Imagen"
                            : replyingMessage!.type == "video"
                            ? "🎥 Video"
                            : replyingMessage!.type == "note"
                            ? "📝 Nota"
                            : "Mensaje",

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.close),

                  onPressed: () {
                    setState(() {
                      replyingMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),
        // 🔵 INPUT CHAT
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
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  ),

                  shape: BoxShape.circle,
                ),

                child: IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.white),

                  onPressed: openAttachmentMenu,
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
                icon: const Icon(Icons.send, color: Colors.blue),

                onPressed: sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),

      // 🔵 APPBAR
      appBar: AppBar(
        elevation: 0,

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            ),
          ),
        ),

        title: selectedUserId == null
            ? Row(
                children: const [
                  Icon(Icons.auto_awesome, color: Colors.white),

                  SizedBox(width: 8),

                  Text(
                    "NoteMind",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  CircleAvatar(
                    radius: 20,

                    backgroundImage:
                        (selectedUserPhoto != null &&
                            selectedUserPhoto.isNotEmpty)
                        ? NetworkImage(selectedUserPhoto)
                        : null,

                    child: selectedUserPhoto.isEmpty
                        ? Text(
                            selectedUserName.isNotEmpty
                                ? selectedUserName[0].toUpperCase()
                                : "U",

                            style: const TextStyle(
                              color: Colors.white,

                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(width: 10),

                  Text(
                    selectedUserName,

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

                    selectedUserPhoto = "";

                    selectedUserName = "";
                  });
                },
              )
            : null,

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
              tooltip: "Cerrar sesión",
            ),
          ),
        ],
      ),

      // boddy
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

                      prefixIcon: const Icon(Icons.search, color: Colors.blue),

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

//configuración de imagen
class ImagePreview extends StatelessWidget {
  final String url;
  final double width;
  final double height;

  const ImagePreview({
    super.key,
    required this.url,
    this.width = 320,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            width: width,
            height: height,
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FullScreenImage(url: url)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String url;

  const FullScreenImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,

              child: Image.network(url),
            ),
          ),

          Positioned(
            top: 40,
            right: 20,

            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),

              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

//configuración de video
class VideoPreview extends StatefulWidget {
  final String url;
  final double width;
  final double height;

  const VideoPreview({
    super.key,
    required this.url,
    this.width = 320,
    this.height = 200,
  });

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

  Future<void> _openFullscreen() async {
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
        await Future.delayed(const Duration(milliseconds: 50));
        await controller.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container(
        width: widget.width,
        height: widget.height,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: VideoPlayer(controller),
              ),
            ),

            // Tap para play/pause
            GestureDetector(
              onTap: () {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              },
              child: Container(
                width: widget.width,
                height: widget.height,
                color: Colors.transparent,
              ),
            ),

            // Botón fullscreen
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: _openFullscreen,
                ),
              ),
            ),
            // Controles centrales
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _seekBackward,
                  icon: const Icon(
                    Icons.replay_10,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                IconButton(
                  onPressed: () {
                    controller.value.isPlaying
                        ? controller.pause()
                        : controller.play();
                  },
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    color: Colors.white,
                    size: 56,
                  ),
                ),

                IconButton(
                  onPressed: _seekForward,
                  icon: const Icon(
                    Icons.forward_10,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ],
        ),

        SizedBox(
          width: widget.width,
          child: VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          ),
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
