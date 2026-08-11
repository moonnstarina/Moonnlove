import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> register(String email, String password, String name) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await result.user?.updateDisplayName(name);
    await result.user?.reload();

    try {
      await _db.child('users/${result.user!.uid}').set({
        'uid': result.user!.uid,
        'name': name,
        'email': email,
        'photo_url': '',
        'partner_uid': '',
        'couple_id': '',
        'invite_code': '',
        'theme_primary_color': 0xFFE91E63,
        'theme_mode': 'light',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }).timeout(const Duration(seconds: 5), onTimeout: () {
        // Timeout, skip simpan data
      });
    } catch (e) {
      // Gagal simpan, skip
    }

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
    try {
      final DatabaseEvent event = await _db.child('users/$uid').once();
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  String getErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Format email tidak valid';
        case 'user-disabled':
          return 'Akun kamu telah dinonaktifkan';
        case 'user-not-found':
          return 'Email tidak terdaftar';
        case 'wrong-password':
          return 'Password salah';
        case 'invalid-credential':
          return 'Email atau password salah';
        case 'email-already-in-use':
          return 'Email sudah terdaftar, gunakan email lain';
        case 'weak-password':
          return 'Password terlalu lemah (minimal 6 karakter)';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan, coba lagi nanti';
        case 'network-request-failed':
          return 'Tidak ada koneksi internet';
        case 'operation-not-allowed':
          return 'Metode login tidak diizinkan';
        default:
          return 'Terjadi kesalahan: ${e.message ?? e.code}';
      }
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
