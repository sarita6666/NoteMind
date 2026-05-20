import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/custom_alert.dart';

class ChatAIScreen extends StatefulWidget {
  const ChatAIScreen({super.key});

  @override
  State<ChatAIScreen> createState() => _ChatAIScreenState();
}

class _ChatAIScreenState extends State<ChatAIScreen> {
  final TextEditingController _controller = TextEditingController();
  final AIService _aiService = AIService();
  final AuthService _authService = AuthService();

  List<Map<String, String>> messages = [];
  bool isLoading = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({'text': text, 'sender': 'Tú'});
      isLoading = true;
    });

    _controller.clear();
    FocusScope.of(context).unfocus();

    try {
      final response = await _aiService.sendMessage(text);
      setState(() {
        messages.add({'text': response, 'sender': 'IA'});
      });
    } catch (e) {
      setState(() {
        messages.add({'text': 'Error al obtener respuesta', 'sender': 'IA'});
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _messageBubble(Map<String, String> msg) {
    final isUser = msg['sender'] == 'Tú';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? Colors.purple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg['sender']!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isUser ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg['text']!,
              style: TextStyle(color: isUser ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)],
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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: "Cerrar sesión",
          ),
        ],
      ),
      body: Column(
        children: [
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
              child: CircularProgressIndicator(),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
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
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.purple),
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