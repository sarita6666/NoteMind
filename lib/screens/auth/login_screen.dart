import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_alert.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final auth = AuthService();

  List<String> savedEmails = [];

  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    loadEmails();
  }

  void loadEmails() async {
    savedEmails = await auth.getSavedEmails();
    setState(() {});
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

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
                        "Iniciar Sesión",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        "Ingresa tus credenciales para continuar",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),

                      const SizedBox(height: 15),

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

                      if (savedEmails.isNotEmpty)
                        Wrap(
                          children: savedEmails.map((email) {
                            return GestureDetector(
                              onTap: () {
                                emailCtrl.text = email;
                              },
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(email),
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 10),

                      const Text("Contraseña"),
                      const SizedBox(height: 5),

                      TextField(
                        controller: passCtrl,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: "********",
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

                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () async {
                          final email = emailCtrl.text.trim();
                          final password = passCtrl.text.trim();

                          if (email.isEmpty || password.isEmpty) {
                            CustomAlert.show(
                              context,
                              title: "Campos incompletos",
                              message: "Por favor llena todos los campos",
                              icon: Icons.warning,
                              color: Colors.orange,
                              success: false,
                            );
                            return;
                          }

                          if (!isValidEmail(email)) {
                            CustomAlert.show(
                              context,
                              title: "Correo inválido",
                              message: "Ingresa un correo válido",
                              icon: Icons.error,
                              color: Colors.red,
                              success: false,
                            );
                            return;
                          }

                          if (password.length < 6) {
                            CustomAlert.show(
                              context,
                              title: "Contraseña inválida",
                              message: "Debe tener al menos 6 caracteres",
                              icon: Icons.error,
                              color: Colors.red,
                              success: false,
                            );
                            return;
                          }

                          try {
                            await auth.login(email, password);
                            await auth.saveEmail(email);

                            CustomAlert.show(
                              context,
                              title: "Bienvenido ",
                              message: "Inicio de sesión exitoso",
                              icon: Icons.check_circle,
                              color: Colors.green,
                            );

                            Future.delayed(const Duration(seconds: 2), () {
                              Navigator.pushReplacementNamed(context, "/home");
                            });
                          } on FirebaseAuthException catch (e) {
                            print("ERROR FIREBASE: ${e.code}");
                            print("MENSAJE: ${e.message}");

                            String mensaje;

                            switch (e.code) {
                              case 'user-not-found':
                                mensaje = "El correo no está registrado.";
                                break;

                              case 'wrong-password':
                                mensaje = "La contraseña es incorrecta.";
                                break;

                              case 'invalid-email':
                                mensaje = "El correo no es válido.";
                                break;

                              case 'invalid-credential':
                                mensaje = "Correo o contraseña incorrectos.";
                                break;

                              case 'user-disabled':
                                mensaje = "Este usuario ha sido deshabilitado.";
                                break;

                              case 'too-many-requests':
                                mensaje =
                                    "Demasiados intentos. Intenta más tarde.";
                                break;

                              case 'network-request-failed':
                                mensaje = "Sin conexión a internet.";
                                break;

                              default:
                                mensaje = e.message ?? "Error desconocido";
                            }

                            CustomAlert.show(
                              context,
                              title: "Error al iniciar sesión",
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
                              "Iniciar Sesión",
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
                            Navigator.pushNamed(context, "/register");
                          },
                          child: const Text(
                            "¿No tienes una cuenta? Regístrate aquí",
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          " Crea una cuenta para probar NoteMind\nLos datos se guardan en tu navegador (localStorage)",
                          style: TextStyle(fontSize: 11),
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
