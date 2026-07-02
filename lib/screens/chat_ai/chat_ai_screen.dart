import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/custom_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/ai_chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatAIScreen extends StatefulWidget {
  const ChatAIScreen({super.key});

  @override
  State<ChatAIScreen> createState() => _ChatAIScreenState();
}

class _ChatAIScreenState extends State<ChatAIScreen> {
  final TextEditingController _controller = TextEditingController();

  final AIService _aiService = AIService();
  final AuthService _authService = AuthService();
  final AIChatService _chatService = AIChatService();

  String? currentChatId;

  final user = FirebaseAuth.instance.currentUser;

  List<Map<String, String>> messages = [];
  bool ignoreRoutePrompt = false;
  bool promptLoaded = false;
  bool isLoading = false;
  String? lastPrompt;

  //Crear un chatB
  Future<void> _createChatIfNeeded() async {
    if (currentChatId != null) return;

    currentChatId = await _chatService.createChat(user!.uid);
  }

  //Enviar mennsaje
  void _sendMessage() async {
    if (isLoading) return;
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    await _createChatIfNeeded();

    setState(() {
      messages.add({'text': text, 'sender': 'Tú'});

      isLoading = true;
    });

    _controller.clear();

    await _chatService.saveMessage(
      chatId: currentChatId!,
      sender: "user",
      text: text,
    );
    if (messages.length == 1) {
      await FirebaseFirestore.instance
          .collection("ai_chats")
          .doc(currentChatId)
          .update({"title": text.length > 30 ? text.substring(0, 30) : text});
    }
    try {
      final response = await _aiService.sendMessage(text);

      await _chatService.saveMessage(
        chatId: currentChatId!,
        sender: "ai",
        text: response,
      );

      setState(() {
        messages.add({'text': response, 'sender': 'IA'});
      });
    } catch (e) {
      setState(() {
        messages.add({
          'text': 'La IA tardó demasiado o no respondió. Intenta nuevamente.',
          'sender': 'IA',
        });
      });

      debugPrint("ERROR IA: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  //cargar chats
  Future<void> _loadMessages() async {
    if (currentChatId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection("ai_chats")
        .doc(currentChatId)
        .collection("messages")
        .orderBy("timestamp")
        .get();

    messages.clear();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      messages.add({
        "text": data["text"] ?? "",
        "sender": data["sender"] == "user" ? "Tú" : "IA",
      });
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final chats = await FirebaseFirestore.instance
        .collection("ai_chats")
        .where("userId", isEqualTo: user!.uid)
        .orderBy("createdAt", descending: true)
        .limit(1)
        .get();

    if (chats.docs.isNotEmpty) {
      currentChatId = chats.docs.first.id;

      await _loadMessages();
    }
  }

  Future<void> _newChat() async {
    currentChatId = await _chatService.createChat(user!.uid);

    setState(() {
      messages.clear();
      promptLoaded = false;
      ignoreRoutePrompt = true;
      lastPrompt = null;
    });

    Navigator.pop(context);
  }

  // estilo burbuja de mensaje
  Widget _messageBubble(Map<String, String> msg) {
    final isUser = msg['sender'] == 'Tú';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,

      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),

        padding: const EdgeInsets.all(12),

        constraints: const BoxConstraints(maxWidth: 280),

        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF1976D2) : Colors.blue.shade50,

          borderRadius: BorderRadius.circular(15),
        ),

        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,

          children: [
            Text(
              msg['sender']!,

              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,

                color: isUser ? Colors.white70 : Colors.blueGrey,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              msg['text']!,

              style: TextStyle(color: isUser ? Colors.white : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  // LOGOUT
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

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final prompt = args?["prompt"] as String?;
    final noteTitle = args?["noteTitle"] as String?;

    //  CARGAR PROMPT AUTOMÁTICO
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (prompt != null &&
          prompt.isNotEmpty &&
          !ignoreRoutePrompt &&
          !promptLoaded &&
          !isLoading) {
        promptLoaded = true;
        if (prompt == lastPrompt) return;

        lastPrompt = prompt;
        await _createChatIfNeeded();

        setState(() {
          messages.add({'text': prompt, 'sender': 'Tú'});

          isLoading = true;
        });

        await _chatService.saveMessage(
          chatId: currentChatId!,
          sender: "user",
          text: prompt,
        );
        await FirebaseFirestore.instance
            .collection("ai_chats")
            .doc(currentChatId)
            .update({"title": noteTitle ?? "Análisis de nota"});
        try {
          final response = await _aiService.sendMessage(prompt);

          await _chatService.saveMessage(
            chatId: currentChatId!,
            sender: "ai",
            text: response,
          );

          if (mounted) {
            setState(() {
              messages.add({'text': response, 'sender': 'IA'});
            });
          }
        } catch (e) {
          print("ERROR IA:");
          print(e);

          setState(() {
            messages.add({'text': 'Error: $e', 'sender': 'IA'});
          });
        } finally {
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),

      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _newChat,
                    icon: const Icon(Icons.add),
                    label: const Text("Nuevo chat"),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatService.getChats(user!.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final chats = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: chats.length,

                    itemBuilder: (_, index) {
                      final chat = chats[index];

                      return ListTile(
                        leading: const Icon(Icons.chat),

                        title: Text(
                          chat["title"] ?? "Nuevo chat",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Eliminar conversación"),
                                content: const Text(
                                  "¿Deseas eliminar este chat?",
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
                              await _chatService.deleteChat(chat.id);

                              if (currentChatId == chat.id) {
                                setState(() {
                                  currentChatId = null;
                                  messages.clear();
                                });
                              }
                            }
                          },
                        ),

                        onTap: () async {
                          currentChatId = chat.id;

                          setState(() {
                            ignoreRoutePrompt = false;
                          });

                          await _loadMessages();

                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      //  APPBAR
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            ),
          ),
        ),

        title: Row(
          children: const [
            Icon(Icons.auto_awesome, color: Colors.white),

            SizedBox(width: 8),

            Text(
              "NoteMind",

              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ),
        ],
      ),

      //  BODY
      body: Column(
        children: [
          // MENSAJES
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),

              itemCount: messages.length,

              itemBuilder: (_, index) => _messageBubble(messages[index]),
            ),
          ),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8),

              child: CircularProgressIndicator(color: Colors.blue),
            ),

          //  INPUT CHAT
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

            padding: const EdgeInsets.symmetric(horizontal: 12),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(30),

              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),

            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,

                    decoration: const InputDecoration(
                      hintText: "Escribe un mensaje...",
                      border: InputBorder.none,
                    ),

                    textInputAction: TextInputAction.send,

                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),

                //   BOTÓN ENVIAR
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),

                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }
}
