import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_alert.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  final auth = AuthService();

  // 🔥 VARIABLES DE VISIBILIDAD
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  String? selectedRole; // 'Instructor' o 'Aprendiz'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                //  ICONO SUPERIOR
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.purple,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "NoteMind",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const Text(
                  "Tu asistente inteligente de notas ADSO",
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),

                const SizedBox(height: 25),

                //  CARD REGISTER
                Container(
                  width: 340,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Crear Cuenta",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        "Regístrate para comenzar a usar NoteMind",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),

                      const SizedBox(height: 15),

                      const Text("Nombre Completo"),
                      const SizedBox(height: 5),
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          hintText: "Nombre Completo",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text("Email"),
                      const SizedBox(height: 5),
                      TextField(
                        controller: emailCtrl,
                        decoration: InputDecoration(
                          hintText: "tu@email.com",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text("Contraseña"),
                      const SizedBox(height: 5),
                      TextField(
                        controller: passCtrl,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: "Mínimo 6 caracteres",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text("Confirmar Contraseña"),
                      const SizedBox(height: 5),
                      TextField(
                        controller: confirmPassCtrl,
                        obscureText: !isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          hintText: "Repite tu contraseña",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                isConfirmPasswordVisible =
                                    !isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text("Selecciona tu rol"),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Instructor"),
                              value: "Instructor",
                              groupValue: selectedRole,
                              onChanged: (value) {
                                setState(() {
                                  selectedRole = value;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Aprendiz"),
                              value: "Aprendiz",
                              groupValue: selectedRole,
                              onChanged: (value) {
                                setState(() {
                                  selectedRole = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 🔹 BOTÓN CREAR CUENTA
                      GestureDetector(
                        onTap: () async {
                          final name = nameCtrl.text.trim();
                          final email = emailCtrl.text.trim();
                          final password = passCtrl.text.trim();
                          final confirmPassword = confirmPassCtrl.text.trim();

                          if (name.isEmpty ||
                              email.isEmpty ||
                              password.isEmpty ||
                              confirmPassword.isEmpty ||
                              selectedRole == null) {
                            CustomAlert.show(
                              context,
                              title: "Campos incompletos",
                              message:
                                  "Por favor llena todos los campos y selecciona un rol",
                              icon: Icons.warning,
                              color: Colors.orange,
                              success: false,
                            );
                            return;
                          }

                          if (password.length < 6) {
                            CustomAlert.show(
                              context,
                              title: "Contraseña débil",
                              message: "Debe tener al menos 6 caracteres",
                              icon: Icons.lock,
                              color: Colors.orange,
                              success: false,
                            );
                            return;
                          }

                          if (password != confirmPassword) {
                            CustomAlert.show(
                              context,
                              title: "Error",
                              message: "Las contraseñas no coinciden",
                              icon: Icons.error,
                              color: Colors.red,
                              success: false,
                            );
                            return;
                          }

                          try {
                            final user = await auth.register(
                              email,
                              password,
                              selectedRole!,
                              name,
                            );

                            CustomAlert.show(
                              context,
                              title: "Cuenta creada ",
                              message: "Bienvenido a NoteMind $name",
                              icon: Icons.celebration,
                              color: Colors.green,
                            );

                            Future.delayed(const Duration(seconds: 2), () {
                              Navigator.pushReplacementNamed(context, "/home");
                            });
                          } on FirebaseAuthException catch (e) {
                            String mensaje = "Error al registrarse";

                            if (e.code == 'email-already-in-use') {
                              mensaje = "El correo ya está en uso";
                            } else if (e.code == 'weak-password') {
                              mensaje = "Contraseña muy débil";
                            } else if (e.code == 'invalid-email') {
                              mensaje = "Correo inválido";
                            }

                            CustomAlert.show(
                              context,
                              title: "Oops ",
                              message: mensaje,
                              icon: Icons.error,
                              color: Colors.red,
                              success: false,
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              "Crear Cuenta",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "¿Ya tienes una cuenta? Inicia sesión aquí",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
