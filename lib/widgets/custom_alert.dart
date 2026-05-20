import 'package:flutter/material.dart';

class CustomAlert {

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.info,
    Color color = Colors.purple,
    bool success = true,
  }) {
    showDialog(
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
              gradient: LinearGradient(
                colors: success
                    ? [Color(0xFF7B2FF7), Color(0xFFF107A3)]
                    : [Colors.red, Colors.orange],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ICONO
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(icon, size: 30, color: color),
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
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 20),

                // BOTÓN
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}