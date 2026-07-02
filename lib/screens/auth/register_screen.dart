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

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // FONDO AZUL
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 🔵 ICONO SUPERIOR
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.blue,
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

                // 🔵 CARD REGISTER
                Container(
                  width: 340,
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 10),
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

                      //  NOMBRE
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

                      //  EMAIL
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

                      //  PASSWORD
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
                              color: Colors.blue,
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

                      //  CONFIRM PASSWORD
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
                              color: Colors.blue,
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

                      //  ROLES
                      const Text("Selecciona tu rol"),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              activeColor: Colors.blue,
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
                              activeColor: Colors.blue,
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

                      //  BOTÓN CREAR CUENTA
                      //  BOTÓN CREAR CUENTA
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () async {
                                setState(() {
                                  isLoading = true;
                                });

                                try {
                                  final name = nameCtrl.text.trim();

                                  final email = emailCtrl.text.trim();

                                  final password = passCtrl.text.trim();

                                  final confirmPassword = confirmPassCtrl.text
                                      .trim();

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
                                      color: Colors.blueAccent,
                                      success: false,
                                    );

                                    return;
                                  }

                                  if (password.length < 6) {
                                    CustomAlert.show(
                                      context,
                                      title: "Contraseña débil",
                                      message:
                                          "Debe tener al menos 6 caracteres",
                                      icon: Icons.lock,
                                      color: Colors.blueAccent,
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
                                      color: Colors.blueAccent,
                                      success: false,
                                    );

                                    return;
                                  }

                                  await auth.register(
                                    email,
                                    password,
                                    selectedRole!,
                                    name,
                                  );

                                  await CustomAlert.show(
                                    context,
                                    title: "Cuenta creada",
                                    message: "Bienvenido a NoteMind $name",
                                    icon: Icons.celebration,
                                    color: Colors.blue,
                                  );

                                  await Future.delayed(
                                    const Duration(seconds: 2),
                                  );

                                  if (mounted) {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      "/home",
                                    );
                                  }
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
                                    title: "Oops",
                                    message: mensaje,
                                    icon: Icons.error,
                                    color: Colors.blueAccent,
                                    success: false,
                                  );
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

                            borderRadius: BorderRadius.circular(10),
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

                      // 🔵 LOGIN
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },

                          child: const Text(
                            "¿Ya tienes una cuenta? Inicia sesión aquí",
                            style: TextStyle(color: Colors.blue),
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
