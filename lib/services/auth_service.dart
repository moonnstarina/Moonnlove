import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> register(String email, String password, String name) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.child('users/${result.user!.uid}').set({
      'uid': result.user!.uid,
      'name': name,
      'email': email,
      'photo_url': '',
      'partner_uid': '',
      'theme_primary_color': 0xFFE91E63,
      'theme_mode': 'light',
      'created_at': ServerValue.timestamp,
    });

    return result;
  }

  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    DatabaseEvent event = await _db.child('users/$uid').once();
    if (event.snapshot.value != null) {
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    }
    return null;
  }
}