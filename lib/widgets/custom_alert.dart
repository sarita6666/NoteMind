import 'package:flutter/material.dart';

class CustomAlert {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.info,
    Color color = Colors.blue,
    bool success = true,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),

              // 🔵 NUEVOS COLORES AZULES
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: success
                    ? [
                        const Color(0xFF1565C0), // Azul fuerte
                        const Color(0xFF42A5F5), // Azul claro
                      ]
                    : [
                        const Color(0xFF0D47A1), // Azul oscuro
                        const Color(0xFF1976D2), // Azul medio
                      ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ICONO
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    icon,
                    size: 30,
                    color: color,
                  ),
                ),

                const SizedBox(height: 15),

                // TITULO
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // MENSAJE
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 20),

                // BOTÓN
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}