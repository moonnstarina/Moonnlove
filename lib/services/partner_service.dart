import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';

class PartnerService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final AuthService _authService = AuthService();

  DatabaseReference get _usersRef => _db.ref().child('users');
  DatabaseReference get _couplesRef => _db.ref().child('couples');

  String? get currentUid => _authService.currentUser?.uid;

  String generateCode() {
    final rand = Random.secure();
    return (100000 + rand.nextInt(900000)).toString();
  }

  Future<String> getMyCode() async {
    final uid = currentUid;
    if (uid == null) throw Exception('Not logged in');

    final data = await _authService.getUserData(uid);
    final existing = data?['invite_code'];
    if (existing != null && existing.toString().isNotEmpty) {
      return existing.toString();
    }

    String code = generateCode();
    final taken = await _isCodeTaken(code);
    while (taken) {
      code = generateCode();
    }

    await _usersRef.child(uid).update({'invite_code': code});
    return code;
  }

  Future<bool> _isCodeTaken(String code) async {
    final event = await _usersRef
        .orderByChild('invite_code')
        .equalTo(code)
        .once();
    return event.snapshot.value != null;
  }

  Future<Map<String, dynamic>> pairByCode(String code) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Not logged in');

    final codeTrimmed = code.trim();
    if (codeTrimmed.length != 6) {
      throw Exception('Kode harus 6 digit');
    }

    final event = await _usersRef
        .orderByChild('invite_code')
        .equalTo(codeTrimmed)
        .once();

    final snapshot = event.snapshot;
    if (snapshot.value == null) {
      throw Exception('Kode tidak ditemukan');
    }

    final partnerUid = (snapshot.value as Map).keys.first;
    if (partnerUid == uid) {
      throw Exception('Gak bisa pairing dengan diri sendiri');
    }

    final myData = await _authService.getUserData(uid);
    if (myData?['partner_uid']?.toString().isNotEmpty == true) {
      throw Exception('Kamu sudah punya pasangan');
    }

    final partnerData = await _authService.getUserData(partnerUid);
    if (partnerData?['partner_uid']?.toString().isNotEmpty == true) {
      throw Exception('Pasangan sudah punya pasangan lain');
    }

    final coupleId = _makeCoupleId(uid, partnerUid);

    final updates = <String, Object?>{};
    updates['users/$uid/partner_uid'] = partnerUid;
    updates['users/$uid/couple_id'] = coupleId;
    updates['users/$partnerUid/partner_uid'] = uid;
    updates['users/$partnerUid/couple_id'] = coupleId;
    updates['couples/$coupleId'] = {
      'uid1': uid,
      'uid2': partnerUid,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    await _db.ref().update(updates);

    return {
      'couple_id': coupleId,
      'partner_uid': partnerUid,
      'partner_name': partnerData?['name'] ?? 'Partner',
    };
  }

  String _makeCoupleId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<bool> isPaired() async {
    final uid = currentUid;
    if (uid == null) return false;
    final data = await _authService.getUserData(uid);
    return data?['partner_uid']?.toString().isNotEmpty == true;
  }

  Future<String?> getCoupleId() async {
    final uid = currentUid;
    if (uid == null) return null;
    final data = await _authService.getUserData(uid);
    return data?['couple_id']?.toString();
  }

  Future<Map<String, dynamic>?> getPartnerData() async {
    final uid = currentUid;
    if (uid == null) return null;
    final data = await _authService.getUserData(uid);
    final partnerUid = data?['partner_uid']?.toString();
    if (partnerUid == null || partnerUid.isEmpty) return null;
    return await _authService.getUserData(partnerUid);
  }
}
