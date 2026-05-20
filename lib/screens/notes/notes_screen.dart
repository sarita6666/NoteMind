import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/note_model.dart';
import '../../services/note_service.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_alert.dart';

class NotesScreen extends StatefulWidget {
  final NoteModel? note;

  const NotesScreen({super.key, this.note});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();

  String _category = "General";
  bool isPublic = true;

  final List<String> categories = [
    "General",
    "Trabajo",
    "Estudio",
    "Ideas",
    "Personal",
    "Importante",
    "Urgente",
    "Otros"
  ];

  NoteModel? _editingNote;

  @override
  void initState() {
    super.initState();

    if (widget.note != null) {
      _editingNote = widget.note;

      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _category = widget.note!.category;
      isPublic = widget.note!.isPublic;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editingNote == null ? "Nueva Nota" : "Editar Nota"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF7B2FF7),
              Color(0xFFF107A3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 20)
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  focusNode: _titleFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_contentFocus);
                  },
                  decoration: InputDecoration(
                    labelText: "Título",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: _contentController,
                  focusNode: _contentFocus,
                  textInputAction: TextInputAction.done,
                  maxLines: 5,
                  onSubmitted: (_) async {
                    await _saveOrUpdateNote(user?.uid);
                  },
                  decoration: InputDecoration(
                    labelText: "Contenido",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: _category,
                  items: categories
                      .map((cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _category = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Categoría",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SwitchListTile(
                  title: const Text("Nota pública"),
                  value: isPublic,
                  onChanged: (value) {
                    setState(() {
                      isPublic = value;
                    });
                  },
                ),

                const Spacer(),

                GestureDetector(
                  onTap: () async {
                    await _saveOrUpdateNote(user?.uid);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF7B2FF7),
                          Color(0xFFF107A3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Guardar Nota",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 GUARDAR / ACTUALIZAR
  Future<void> _saveOrUpdateNote(String? userId) async {
    if (userId == null) {
      CustomAlert.show(
        context,
        title: "Error",
        message: "Debes iniciar sesión",
        icon: Icons.error,
        color: Colors.red,
        success: false,
      );
      return;
    }

    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      CustomAlert.show(
        context,
        title: "Campos vacíos",
        message: "Completa título y contenido",
        icon: Icons.warning,
        color: Colors.orange,
        success: false,
      );
      return;
    }

    try {
      print("GUARDANDO NOTA...");
      print("USER ID: $userId");

      final userSnap = await UserService().getUser(userId).first;
      final data = userSnap.data() as Map<String, dynamic>?;

      if (data == null) {
        CustomAlert.show(
          context,
          title: "Error",
          message: "No se pudieron cargar tus datos",
          icon: Icons.error,
          color: Colors.red,
          success: false,
        );
        return;
      }

      print("USER DATA OK: $data");

      if (_editingNote == null) {
        await NoteService().create(
          NoteModel(
            id: '',
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            category: _category,
            userId: userId,
            userName: data['name'] ?? 'Usuario',
            userRole: data['role'] ?? 'Sin rol',
            imageUrl: '',
            isPublic: isPublic,
            createdAt: DateTime.now(),
          ),
        );

        print("NOTA CREADA");

        CustomAlert.show(
          context,
          title: "Guardado",
          message: "Tu nota se guardó correctamente",
          icon: Icons.check_circle,
          color: Colors.green,
        );
      } else {
        await NoteService().update(
          NoteModel(
            id: _editingNote!.id,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            category: _category,
            userId: userId,
            userName: _editingNote!.userName,
            userRole: _editingNote!.userRole,
            imageUrl: '',
            isPublic: isPublic,
            createdAt: _editingNote!.createdAt,
          ),
        );

        print("NOTA ACTUALIZADA");

        CustomAlert.show(
          context,
          title: "Actualizado",
          message: "Tu nota se actualizó correctamente",
          icon: Icons.check_circle,
          color: Colors.green,
        );
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      print("ERROR GUARDANDO NOTA: $e");

      CustomAlert.show(
        context,
        title: "Error",
        message: "No se pudo guardar la nota",
        icon: Icons.error,
        color: Colors.red,
        success: false,
      );
    }
  }
}