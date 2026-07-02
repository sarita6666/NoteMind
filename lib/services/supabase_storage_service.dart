import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final supabase = Supabase.instance.client;
  Future<String?> uploadVideo(Uint8List bytes, String path) async {
    try {
      await supabase.storage
          .from('videos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final videoUrl = supabase.storage.from('videos').getPublicUrl(path);

      print("VIDEO SUBIDO:");
      print(videoUrl);

      return videoUrl;
    } catch (e) {
      print("ERROR SUPABASE VIDEO:");
      print(e);

      return null;
    }
  }

  Future<String?> uploadImage(Uint8List bytes, String path) async {
    try {
      await supabase.storage
          .from('imagenes')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = supabase.storage.from('imagenes').getPublicUrl(path);

      print("IMAGEN SUBIDA:");
      print(imageUrl);

      return imageUrl;
    } catch (e) {
      print("ERROR SUPABASE:");
      print(e);

      return null;
    }
  }
}
