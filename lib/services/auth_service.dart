import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // LOGIN
  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // REGISTER con rol
  Future<User?> register(
    String email,
    String password,
    String role,
    String name,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;

    if (user != null) {
      // Actualizar displayName
      await user.updateDisplayName(name);

      // GUARDAR USUARIO COMPLETO
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'role': role,
        'bio': "",
        'photoUrl': "",
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return user;
  }

  // GUARDAR EMAIL EN LOCAL
  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> emails = prefs.getStringList("emails") ?? [];
    if (!emails.contains(email)) {
      emails.add(email);
      await prefs.setStringList("emails", emails);
    }
  }

  Future<List<String>> getSavedEmails() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList("emails") ?? [];
  }

  User? get currentUser => _auth.currentUser;

  Future<void> logout() async {
    await _auth.signOut();
  }

  // OBTENER ROL DEL USUARIO
  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      return doc.data()!['role'] as String?;
    }
    return null;
  }
}
