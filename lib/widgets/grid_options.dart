import 'package:flutter/material.dart';
import 'card_option.dart';

class GridOptions extends StatelessWidget {
  const GridOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        CardOption(
          icon: Icons.note_alt,
          title: "Mis Notas",
          color: Colors.blue,
          onTap: () {
            Navigator.pushNamed(context, '/notes');
          },
        ),
        CardOption(
          icon: Icons.smart_toy,
          title: "Asistente IA",
          color: Colors.purple,
          onTap: () {
            Navigator.pushNamed(context, '/chat');
          },
        ),
        CardOption(
          icon: Icons.person,
          title: "Perfil",
          color: Colors.orange,
          onTap: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
        CardOption(
          icon: Icons.calendar_month,
          title: "Agenda",
          color: Colors.green,
          onTap: () {},
        ),
      ],
    );
  }
}