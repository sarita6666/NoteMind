import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_storage_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/custom_alert.dart';
import '../../services/note_service.dart';
import '../../models/note_model.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../notes/notes_screen.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();

  Future<String?> subirImagen() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return null;

    Uint8List bytes = await pickedFile.readAsBytes();

    final storage = SupabaseStorageService();

    final url = await storage.uploadImage(
      bytes,
      'profile_pictures/${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    if (url != null) {
      await UserService().createOrUpdateUser(
        uid: user!.uid,
        name: user!.displayName ?? "Usuario",
        email: user!.email ?? "",
        photoUrl: url,
      );

      print("URL GUARDADA:");
      print(url);
    }

    return url;
  }

  void editarPerfil(BuildContext context, String bioActual) {
    final nameCtrl = TextEditingController(text: user?.displayName ?? "");
    final bioCtrl = TextEditingController(text: bioActual);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar Perfil"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bioCtrl,
                decoration: const InputDecoration(
                  labelText: "Descripción",
                  hintText: "Ej: Desarrollador, estudiante...",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),

            TextButton(
              onPressed: () async {
                await UserService().createOrUpdateUser(
                  uid: user!.uid,
                  name: nameCtrl.text.trim().isEmpty
                      ? user!.displayName ?? "Usuario"
                      : nameCtrl.text.trim(),
                  email: user!.email ?? "",
                  bio: bioCtrl.text.trim(),
                  photoUrl: "",
                );

                await user?.updatePhotoURL(null);

                if (mounted) {
                  setState(() {});
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Foto de perfil eliminada")),
                  );
                }
              },
              child: const Text(
                "Eliminar foto",
                style: TextStyle(color: Colors.red),
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                final bio = bioCtrl.text.trim();

                if (newName.isEmpty) {
                  CustomAlert.show(
                    context,
                    title: "Campo requerido",
                    message: "Debes ingresar un nombre",
                    icon: Icons.warning,
                    color: Colors.orange,
                  );
                  return;
                }

                await user?.updateDisplayName(newName);

                await UserService().createOrUpdateUser(
                  uid: user!.uid,
                  name: newName,
                  email: user!.email ?? "",
                  bio: bio,
                );

                await user?.reload();

                setState(() {});
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1), // Azul oscuro
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    await _authService.logout();

    CustomAlert.show(
      context,
      title: "Sesión cerrada",
      message: "Has cerrado sesión correctamente",
      icon: Icons.logout,
      color: const Color(0xFF1565C0),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacementNamed(context, "/login");
    });
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
                    Builder(
                      builder: (context) {
                        if (note.userId.isEmpty) {
                          print("ERROR: userId vacío");
                          print("Título: ${note.title}");
                          print(note);

                          return CircleAvatar(
                            radius: 22,
                            child: Text(
                              note.userName.isNotEmpty
                                  ? note.userName[0].toUpperCase()
                                  : "?",
                            ),
                          );
                        }

                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("users")
                              .doc(note.userId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            String photoUrl = "";

                            if (snapshot.hasData && snapshot.data!.exists) {
                              final userData =
                                  snapshot.data!.data() as Map<String, dynamic>;

                              photoUrl = userData["photoUrl"] ?? "";
                            }

                            return CircleAvatar(
                              radius: 22,
                              backgroundImage: photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl.isEmpty
                                  ? Text(
                                      note.userName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            );
                          },
                        );
                      },
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
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final updatedUser = FirebaseAuth.instance.currentUser;
    final name = updatedUser?.displayName ?? "Usuario";
    final email = updatedUser?.email ?? "correo@email.com";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),

      appBar: AppBar(
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
              tooltip: "Cerrar sesión",
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: StreamBuilder(
          stream: updatedUser == null
              ? const Stream.empty()
              : UserService().getUser(updatedUser.uid),
          builder: (context, snapshot) {
            String bio = "";
            String photoUrl = "";

            if (snapshot.hasData && snapshot.data!.data() != null) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              bio = data['bio'] ?? "";
              photoUrl = data['photoUrl'] ?? "";
              print("URL desde Firestore: $photoUrl");
            }

            return Column(
              children: [
                const SizedBox(height: 15),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 10),
                            ],
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),

                              Stack(
                                children: [
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF1565C0),
                                          Color(0xFF42A5F5),
                                        ],
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: photoUrl.isNotEmpty
                                          ? Image.network(
                                              "$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}",
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Center(
                                                      child: Text(
                                                        name[0].toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 35,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                            )
                                          : Center(
                                              child: Text(
                                                name[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 35,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),

                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final url = await subirImagen();

                                        if (url != null) {
                                          await UserService()
                                              .createOrUpdateUser(
                                                uid: user!.uid,
                                                name: name,
                                                email: email,
                                                bio: bio,
                                                photoUrl: url,
                                              );

                                          await user?.updatePhotoURL(url);
                                          await user?.reload();

                                          setState(() {});
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 18,
                                          color: Color(0xFF1565C0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                email,
                                style: const TextStyle(color: Colors.grey),
                              ),

                              if (bio.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    bio,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),

                              const SizedBox(height: 15),

                              OutlinedButton(
                                onPressed: () => editarPerfil(context, bio),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 45),
                                ),
                                child: const Text("Editar Perfil"),
                              ),

                              const SizedBox(height: 10),

                              OutlinedButton.icon(
                                onPressed: _logout,
                                icon: const Icon(
                                  Icons.logout,
                                  color: Color(0xFF1565C0),
                                ),
                                label: const Text(
                                  "Cerrar sesión",
                                  style: TextStyle(color: Color(0xFF1565C0)),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 45),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Notas guardadas",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),

                                    const SizedBox(height: 15),

                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection("saved_notes")
                                          .where(
                                            "savedBy",
                                            isEqualTo: FirebaseAuth
                                                .instance
                                                .currentUser!
                                                .uid,
                                          )
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }

                                        final notes = snapshot.data!.docs;

                                        if (notes.isEmpty) {
                                          return const Center(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 20,
                                              ),
                                              child: Text(
                                                "No tienes notas guardadas",
                                              ),
                                            ),
                                          );
                                        }

                                        return ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: notes.length,
                                          itemBuilder: (_, index) {
                                            final data =
                                                notes[index].data()
                                                    as Map<String, dynamic>;

                                            print(
                                              "Imagen: ${data["imageUrl"]}",
                                            );
                                            print("Video: ${data["videoUrl"]}");
                                            print("----------------------");
                                            print(data);
                                            final note = NoteModel(
                                              id: data["noteId"] ?? "",
                                              title: data["title"] ?? "",
                                              content: data["content"] ?? "",
                                              category: data["category"] ?? "",
                                              userId: data["userId"] ?? "",
                                              userName:
                                                  data["userName"] ?? "Usuario",
                                              userRole:
                                                  data["userRole"] ?? "Sin rol",
                                              imageUrl: data["imageUrl"] ?? "",
                                              videoUrl: data["videoUrl"] ?? "",
                                              isPublic: true,
                                              createdAt:
                                                  data["createdAt"] != null
                                                  ? (data["createdAt"]
                                                            as Timestamp)
                                                        .toDate()
                                                  : DateTime.now(),
                                              likes: [],
                                            );
                                            print("note.id = ${note.id}");
                                            print(
                                              "note.userId = '${note.userId}'",
                                            );
                                            print(
                                              "note.userName = ${note.userName}",
                                            );
                                            return _noteCard(note);
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        StreamBuilder<List<NoteModel>>(
                          stream: updatedUser == null
                              ? const Stream.empty()
                              : NoteService().getNotes(updatedUser.uid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final notes = (snapshot.data ?? [])
                              ..sort(
                                (a, b) => b.createdAt.compareTo(a.createdAt),
                              );

                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Mis Notas (${notes.length})",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/notes',
                                          );
                                        },
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text("Nueva Nota"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF1565C0,
                                          ),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  if (notes.isEmpty) ...[
                                    Icon(
                                      Icons.description_outlined,
                                      size: 60,
                                      color: const Color(
                                        0xFF1565C0,
                                      ).withValues(alpha: 0.4),
                                    ),

                                    const SizedBox(height: 10),

                                    const Text("No tienes notas aún"),
                                    const SizedBox(height: 5),
                                    const Text(
                                      "Comienza creando tu primera nota",
                                    ),

                                    const SizedBox(height: 15),

                                    Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF1565C0),
                                            Color(0xFF42A5F5),
                                          ],
                                        ),
                                      ),
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/notes',
                                          );
                                        },
                                        child: const Text(
                                          "Crear Nota",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: notes.length > 3
                                          ? 3
                                          : notes.length,
                                      itemBuilder: (context, index) {
                                        final note = notes[index];

                                        return _noteCard(note);
                                      },
                                    ),

                                    const SizedBox(height: 10),

                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/home');
                                      },
                                      child: const Text("Ver todas las notas"),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),

      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }
}
