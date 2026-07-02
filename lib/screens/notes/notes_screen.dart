import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/note_model.dart';
import '../../services/note_service.dart';
import '../../services/user_service.dart';
import '../../services/supabase_storage_service.dart';
import '../../widgets/custom_alert.dart';
import 'package:flutter/foundation.dart';

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
  bool isLoading = false;
  XFile? selectedImage;
  XFile? selectedVideo;
  final List<String> categories = [
    "General",
    "Trabajo",
    "Estudio",
    "Ideas",
    "Personal",
    "Importante",
    "Urgente",
    "Otros",
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

  Future<void> pickVideo() async {
    final picker = ImagePicker();

    final video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      setState(() {
        selectedVideo = video;
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
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
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),

            child: Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 20),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =========================
                  // TITULO
                  // =========================
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

                  // =========================
                  // CONTENIDO
                  // =========================
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

                  // =========================
                  // CATEGORIA
                  // =========================
                  DropdownButtonFormField<String>(
                    initialValue: _category,

                    items: categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),

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

                  // =========================
                  // PUBLICA
                  // =========================
                  SwitchListTile(
                    title: const Text("Nota pública"),
                    value: isPublic,

                    onChanged: (value) {
                      setState(() {
                        isPublic = value;
                      });
                    },
                  ),

                  const SizedBox(height: 10),
                  //boton imagen
                  ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Agregar imagen"),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),
                  //boton video
                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    onPressed: pickVideo,
                    icon: const Icon(Icons.video_library),
                    label: const Text("Agregar video"),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  //imagen preview
                  if (selectedImage != null)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),

                          child: Container(
                            width: double.infinity,

                            constraints: const BoxConstraints(maxHeight: 250),

                            color: Colors.grey.shade200,

                            child: kIsWeb
                                ? Image.network(
                                    selectedImage!.path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(selectedImage!.path),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // =========================
                        // QUITAR IMAGEN
                        // =========================
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedImage = null;
                            });
                          },

                          icon: const Icon(Icons.close),

                          label: const Text("Quitar imagen"),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // =========================
                  // BOTON GUARDAR
                  // =========================
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () async {
                            setState(() {
                              isLoading = true;
                            });

                            try {
                              await _saveOrUpdateNote(user?.uid);
                            } finally {
                              if (mounted) {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            }
                          },

                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),

                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                        ),

                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
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
      ),
    );
  }

  // =========================
  // GUARDAR / ACTUALIZAR
  // =========================
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

      // SUBIR IMAGEN
      String uploadedImageUrl = '';

      if (selectedImage != null) {
        final bytes = await selectedImage!.readAsBytes();

        final storage = SupabaseStorageService();

        uploadedImageUrl =
            await storage.uploadImage(
              bytes,
              'notes/${DateTime.now().millisecondsSinceEpoch}_${selectedImage!.name}',
            ) ??
            '';
      }
      //subir video
      String uploadedVideoUrl = '';

      if (selectedVideo != null) {
        final bytes = await selectedVideo!.readAsBytes();

        final storage = SupabaseStorageService();

        uploadedVideoUrl =
            await storage.uploadVideo(
              bytes,
              'videos/${DateTime.now().millisecondsSinceEpoch}_${selectedVideo!.name}',
            ) ??
            '';
      }
      // =========================
      // CREAR
      // =========================
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
            imageUrl: uploadedImageUrl,
            videoUrl: uploadedVideoUrl,
            isPublic: isPublic,
            createdAt: DateTime.now(),
          ),
        );

        CustomAlert.show(
          context,
          title: "Guardado",
          message: "Tu nota se guardó correctamente",
          icon: Icons.check_circle,
          color: Colors.blue,
          success: true,
        );
      }
      // =========================
      // ACTUALIZAR
      // =========================
      else {
        await NoteService().update(
          NoteModel(
            id: _editingNote!.id,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            category: _category,
            userId: userId,
            userName: _editingNote!.userName,
            userRole: _editingNote!.userRole,
            imageUrl: uploadedImageUrl.isEmpty
                ? _editingNote!.imageUrl
                : uploadedImageUrl,
            videoUrl: uploadedVideoUrl.isEmpty
                ? _editingNote!.videoUrl
                : uploadedVideoUrl,

            isPublic: isPublic,
            createdAt: _editingNote!.createdAt,
          ),
        );

        CustomAlert.show(
          context,
          title: "Actualizado",
          message: "Tu nota se actualizó correctamente",
          icon: Icons.check_circle,
          color: Colors.blue,
          success: true,
        );
      }

      // =========================
      // REDIRECCION AL HOME
      // =========================
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    } catch (e) {
      print(e);

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
