import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  final String apiKey = "AIzaSyDhOjbNyklgsyBnjf-hn9tjeGO4rI_F9Oo";

  Future<String> sendMessage(String message) async {
    const String systemPrompt = """
Eres un asistente especializado en ADSO (SENA).
Ayudas a estudiantes a entender programación, Flutter, bases de datos y desarrollo web.
Respondes claro, breve y con ejemplos cuando sea necesario.
""";

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );
    final response = await http
        .post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": "$systemPrompt\nUsuario: $message"},
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["candidates"] != null) {
        return data["candidates"][0]["content"]["parts"][0]["text"];
      } else {
        throw Exception("Respuesta inválida: ${response.body}");
      }
    } else {
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 403) {
        throw Exception("API bloqueada o inválida");
      }

      if (response.statusCode == 429) {
        throw Exception("Límite de solicitudes alcanzado");
      }

      if (response.statusCode >= 500) {
        throw Exception("Servidor de IA no disponible");
      }

      throw Exception("Error ${response.statusCode}: ${response.body}");
    }
  }
}
