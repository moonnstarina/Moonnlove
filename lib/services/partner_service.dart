import 'dart:io';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  Future<void> saveAnniversary(DateTime date) async {
    final coupleId = await getCoupleId();
    if (coupleId == null) throw Exception('Belum terhubung dengan pasangan');
    await _couplesRef
        .child(coupleId)
        .child('anniversary')
        .set(date.millisecondsSinceEpoch);
  }

  Future<DateTime?> getAnniversary() async {
    final coupleId = await getCoupleId();
    if (coupleId == null) return null;
    final event = await _couplesRef
        .child(coupleId)
        .child('anniversary')
        .once();
    final value = event.snapshot.value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  Future<void> savePhotoUrl(String url) async {
    final uid = currentUid;
    if (uid == null) return;
    await _usersRef.child(uid).update({'photo_url': url});
  }

  Future<void> saveNotificationPrefs(Map<String, bool> prefs) async {
    final uid = currentUid;
    if (uid == null) return;
    await _usersRef.child(uid).child('notifications').set(prefs);
  }

  Future<Map<String, bool>> getNotificationPrefs() async {
    final uid = currentUid;
    if (uid == null) return {};
    final data = await _authService.getUserData(uid);
    final prefs = data?['notifications'];
    if (prefs is Map) {
      return prefs.map((k, v) => MapEntry(k.toString(), v == true));
    }
    return {};
  }

  Future<DatabaseReference?> getPhotosRef() async {
    final coupleId = await getCoupleId();
    if (coupleId == null) return null;
    return _couplesRef.child(coupleId).child('photos');
  }

  Future<String> uploadPhoto(String filePath, {String caption = ''}) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Not logged in');
    final coupleId = await getCoupleId();
    if (coupleId == null) throw Exception('Belum terhubung dengan pasangan');

    final ref = FirebaseStorage.instance.ref().child(
          'photos/$coupleId/${DateTime.now().millisecondsSinceEpoch}_$uid.jpg',
        );
    await ref.putFile(File(filePath));
    final url = await ref.getDownloadURL();

    final photosRef = await getPhotosRef();
    await photosRef?.push().set({
      'url': url,
      'uploader_uid': uid,
      'caption': caption,
      'timestamp': ServerValue.timestamp,
      'type': 'photo',
      'likes': {uid: true},
    });
    return url;
  }

  Future<void> togglePhotoLike(String photoId) async {
    final uid = currentUid;
    if (uid == null) return;
    final photosRef = await getPhotosRef();
    if (photosRef == null) return;
    final photo = (await photosRef.child(photoId).once()).snapshot.value;
    if (photo is! Map) return;
    final likes = photo['likes'];
    final liked = likes is Map && likes.containsKey(uid);
    if (liked) {
      await photosRef.child(photoId).child('likes').child(uid).remove();
    } else {
      await photosRef.child(photoId).child('likes').child(uid).set(true);
    }
  }

  Future<void> updatePhotoCaption(String photoId, String caption) async {
    final photosRef = await getPhotosRef();
    await photosRef?.child(photoId).update({'caption': caption});
  }

  Future<void> markActiveToday() async {
    final coupleId = await getCoupleId();
    if (coupleId == null) return;
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await _couplesRef
        .child(coupleId)
        .child('streak_dates')
        .child(key)
        .set(true);
  }

  Future<Map<String, bool>> getStreakDates() async {
    final coupleId = await getCoupleId();
    if (coupleId == null) return {};
    final event = await _couplesRef.child(coupleId).child('streak_dates').once();
    final value = event.snapshot.value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v == true));
    }
    return {};
  }

  Future<String> uploadChatImage(String filePath) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Not logged in');
    final coupleId = await getCoupleId();
    if (coupleId == null) throw Exception('Belum terhubung dengan pasangan');

    final ref = FirebaseStorage.instance.ref().child(
          'chat_images/$coupleId/${DateTime.now().millisecondsSinceEpoch}_$uid.jpg',
        );
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }
}
