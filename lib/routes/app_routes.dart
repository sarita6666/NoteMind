import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/notes/notes_screen.dart';
import '../screens/chat_ai/chat_ai_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    "/login": (_) => LoginScreen(),
    "/register": (_) => RegisterScreen(),
    "/home": (_) => const HomeScreen(),
    "/profile": (_) => const ProfileScreen(),
    "/chat": (_) => const ChatComunitarioScreen(),
    "/notes": (_) => NotesScreen(),
    '/chat_ai': (_) => const ChatAIScreen(),
  };
}
