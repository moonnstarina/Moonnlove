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
    final existing = data?['invite_code']?.toString() ?? '';
    if (existing.isNotEmpty) {
      final holder = await _db.ref().child('codes/$existing').once();
      if (holder.snapshot.value?.toString() == uid) return existing;
    }

    for (var i = 0; i < 20; i++) {
      final code = generateCode();
      final result = await _db.ref().child('codes/$code').runTransaction(
        (node) {
          if (node != null) return Transaction.abort();
          return Transaction.success(uid);
        },
      );
      if (result.committed) {
        await _usersRef.child(uid).update({'invite_code': code});
        return code;
      }
    }
    throw Exception('Gagal membuat kode unik, coba lagi');
  }

  Future<Map<String, dynamic>> pairByCode(String code) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Not logged in');

    final codeTrimmed = code.trim();
    if (codeTrimmed.length != 6) {
      throw Exception('Kode harus 6 digit');
    }

    final codeEvent = await _db.ref().child('codes/$codeTrimmed').once();
    final partnerUid = codeEvent.snapshot.value?.toString();
    if (partnerUid == null) {
      throw Exception('Kode tidak ditemukan');
    }
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
    updates['users/$uid/invite_code'] = '';
    updates['users/$partnerUid/partner_uid'] = uid;
    updates['users/$partnerUid/couple_id'] = coupleId;
    updates['users/$partnerUid/invite_code'] = '';
    updates['codes/$codeTrimmed'] = null;
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

  Future<void> unpair() async {
    final uid = currentUid;
    if (uid == null) throw Exception('Not logged in');

    final myData = await _authService.getUserData(uid);
    final partnerUid = myData?['partner_uid']?.toString();
    final coupleId = myData?['couple_id']?.toString();

    if (partnerUid == null || partnerUid.isEmpty) {
      throw Exception('Kamu belum terhubung dengan pasangan');
    }

    final updates = <String, Object?>{
      'users/$uid/partner_uid': '',
      'users/$uid/couple_id': '',
      'users/$uid/invite_code': '',
      'users/$partnerUid/partner_uid': '',
      'users/$partnerUid/couple_id': '',
      'users/$partnerUid/invite_code': '',
    };
    if (coupleId != null && coupleId.isNotEmpty) {
      updates['couples/$coupleId'] = null;
    }
    await _db.ref().update(updates);
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
          'photos/$uid/${DateTime.now().millisecondsSinceEpoch}_$uid.jpg',
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
          'chat_images/$uid/${DateTime.now().millisecondsSinceEpoch}_$uid.jpg',
        );
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }

  Future<DatabaseReference?> getGamesRef() async {
    final coupleId = await getCoupleId();
    if (coupleId == null) return null;
    return _couplesRef.child(coupleId).child('games');
  }

  Future<void> addGame(String name, {String? package}) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Not logged in');
    final coupleId = await getCoupleId();
    if (coupleId == null) throw Exception('Belum terhubung dengan pasangan');
    await _couplesRef.child(coupleId).child('games').push().set({
      'name': name,
      if (package != null && package.isNotEmpty) 'package': package,
      'added_by_uid': uid,
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<void> removeGame(String gameId) async {
    final coupleId = await getCoupleId();
    if (coupleId == null) return;
    await _couplesRef.child(coupleId).child('games').child(gameId).remove();
  }

  Future<void> sendGameMessage(String gameName, {bool invite = true}) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Not logged in');
    final coupleId = await getCoupleId();
    if (coupleId == null) throw Exception('Belum terhubung dengan pasangan');

    final message = invite
        ? 'Ajak main $gameName yuk! 🎮'
        : 'Lagi main $gameName nih! Main bareng yuk? 🎮';
    await _couplesRef
        .child(coupleId)
        .child('messages')
        .push()
        .set({
          'sender_uid': uid,
          'message': message,
          'type': 'game',
          'game_name': gameName,
          'timestamp': ServerValue.timestamp,
          'is_read': false,
        });
  }

  Future<void> sendInteraction(String key, String message) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Not logged in');
    final coupleId = await getCoupleId();
    if (coupleId == null) throw Exception('Belum terhubung dengan pasangan');

    await _couplesRef
        .child(coupleId)
        .child('messages')
        .push()
        .set({
          'sender_uid': uid,
          'message': message,
          'type': 'interaction',
          'interaction': key,
          'timestamp': ServerValue.timestamp,
          'is_read': false,
        });
  }

  Future<void> sendAnniversaryMessage() async {
    final uid = currentUid;
    if (uid == null) throw Exception('Not logged in');
    final coupleId = await getCoupleId();
    if (coupleId == null) throw Exception('Belum terhubung dengan pasangan');
    final myData = await _authService.getUserData(uid);
    final myName = myData?['name']?.toString() ?? 'Aku';

    await _couplesRef
        .child(coupleId)
        .child('messages')
        .push()
        .set({
          'sender_uid': uid,
          'message': '$myName mengingatkanmu: hari ini tanggal jadian kita! 🎉',
          'type': 'anniversary',
          'timestamp': ServerValue.timestamp,
          'is_read': false,
        });
  }

  Future<void> saveLocation(double lat, double lng) async {
    final uid = currentUid;
    if (uid == null) return;
    await _usersRef.child(uid).child('location').set({
      'lat': lat,
      'lng': lng,
      'updated_at': ServerValue.timestamp,
    });
  }

  Future<Map<String, double>?> getPartnerLocation() async {
    final partnerData = await getPartnerData();
    final loc = partnerData?['location'];
    if (loc is Map) {
      final lat = loc['lat'];
      final lng = loc['lng'];
      if (lat is num && lng is num) {
        return {'lat': lat.toDouble(), 'lng': lng.toDouble()};
      }
    }
    return null;
  }
}
