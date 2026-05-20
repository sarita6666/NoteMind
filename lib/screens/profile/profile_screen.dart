import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/custom_alert.dart';
import '../../services/note_service.dart';
import '../../models/note_model.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();

  // 🔥 SUBIR FOTO
  Future<String?> subirImagen() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('${user!.uid}.jpg');

    await ref.putFile(
      File(file.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final url = await ref.getDownloadURL();
    print("Nueva URL subida: $url");

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
                maxLines: 2,
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
            ElevatedButton(
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                final bio = bioCtrl.text.trim();

                if (newName.isEmpty) return;

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
      color: Colors.green,
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacementNamed(context, "/login");
    });
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

                        // CARD PERFIL
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
                                          Color(0xFF7B2FF7),
                                          Color(0xFFF107A3),
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
                                          color: Colors.purple,
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
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  "Cerrar sesión",
                                  style: TextStyle(color: Colors.red),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 45),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        //  MIS NOTAS
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

                            final notes = snapshot.data ?? [];

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
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Mis Notas (${notes.length})",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  if (notes.isEmpty) ...[
                                    Icon(
                                      Icons.description_outlined,
                                      size: 60,
                                      color: Colors.grey.shade400,
                                    ),

                                    const SizedBox(height: 10),

                                    const Text(
                                      "No tienes notas aún",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    const Text(
                                      "Comienza creando tu primera nota",
                                      style: TextStyle(color: Colors.grey),
                                    ),

                                    const SizedBox(height: 15),

                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF7B2FF7),
                                            Color(0xFFF107A3),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
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

                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            note.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            note.content,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              note.category,
                                              style: const TextStyle(
                                                color: Colors.purple,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        );
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
