import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Google verifies ownership of the account before Firebase receives it.
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn(scopes: const ['email']).signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user == null || !user.emailVerified) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Akun Google harus memiliki email yang terverifikasi.',
      );
    }
    await _createProfileIfNeeded(user);
    return result;
  }

  Future<void> _createProfileIfNeeded(User user) async {
    final ref = _db.child('users/${user.uid}');
    final existing = await ref.once();
    if (existing.snapshot.exists) return;

    await ref.set({
      'uid': user.uid,
      'name': user.displayName ?? 'MoonnLove User',
      'email': user.email ?? '',
      'photo_url': user.photoURL ?? '',
      'partner_uid': '',
      'couple_id': '',
      'invite_code': '',
      'theme_primary_color': 0xFFE91E63,
      'theme_mode': 'light',
      'created_at': ServerValue.timestamp,
    });
  }

  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final DatabaseEvent event = await _db.child('users/$uid').once();
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String getErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-not-verified':
          return 'Email Google belum terverifikasi. Verifikasi dulu di akun Google kamu.';
        case 'invalid-credential':
          return 'Login Google tidak dapat diverifikasi.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan, coba lagi nanti.';
        case 'network-request-failed':
          return 'Tidak ada koneksi internet.';
        case 'operation-not-allowed':
          return 'Login Google belum diaktifkan di Firebase.';
        default:
          return 'Terjadi kesalahan: ${e.message ?? e.code}';
      }
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
