import '../providers/app_palette.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/partner_service.dart';
import 'account_settings_screen.dart';
import 'notification_settings_screen.dart';

Color get _background => AppPalette.background;
Color get _primary => AppPalette.primary;
Color get _primaryContainer => AppPalette.primaryContainer;
Color get _onPrimaryContainer => AppPalette.onPrimaryContainer;
Color get _onSurface => AppPalette.onSurface;
Color get _onSurfaceVariant => AppPalette.onSurfaceVariant;
Color get _secondaryContainer => AppPalette.secondaryContainer;
Color get _error => AppPalette.error;
Color get _errorContainer => AppPalette.errorContainer;
Color get _surfaceVariant => AppPalette.surfaceVariant;
Color get _surfaceLowest => AppPalette.surfaceLowest;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _partnerService = PartnerService();

  String _userName = 'User';
  String _partnerName = 'Partner';
  bool _paired = false;
  String _sinceText = '';
  String? _partnerUid;
  String? _photoUrl;
  StreamSubscription<DatabaseEvent>? _ownListener;
  StreamSubscription<DatabaseEvent>? _partnerListener;

  @override
  void initState() {
    super.initState();
    _load();
    _listen();
  }

  @override
  void dispose() {
    _ownListener?.cancel();
    _partnerListener?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final user = _authService.currentUser;
    if (user == null) return;
    final data = await _authService.getUserData(user.uid);
    if (!mounted) return;
    setState(() {
      _userName = data?['name'] ?? 'User';
      _paired = data?['partner_uid']?.toString().isNotEmpty == true;
      _partnerUid = data?['partner_uid']?.toString();
      _photoUrl = data?['photo_url']?.toString();
    });
    if (_paired && _partnerUid != null) _attachPartnerListener(_partnerUid!);
    final coupleId = await _partnerService.getCoupleId();
    if (coupleId != null && mounted) {
      final anniversary = await _partnerService.getAnniversary();
      if (anniversary != null && mounted) {
        setState(() {
          _sinceText = _formatDate(anniversary);
        });
        return;
      }
      final event = await FirebaseDatabase.instance
          .ref()
          .child('couples/$coupleId/created_at')
          .once();
      final created = event.snapshot.value;
      if (created is int && mounted) {
        setState(() {
          _sinceText = _formatDate(
            DateTime.fromMillisecondsSinceEpoch(created),
          );
        });
      }
    }
  }

  void _listen() {
    final user = _authService.currentUser;
    if (user == null) return;
    _ownListener = FirebaseDatabase.instance
        .ref()
        .child('users/${user.uid}')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data == null || !mounted) return;
      final map = Map<dynamic, dynamic>.from(data as Map);
      final partnerUid = map['partner_uid']?.toString();
      setState(() {
        _userName = map['name']?.toString() ?? _userName;
        _photoUrl = map['photo_url']?.toString();
        _paired = partnerUid != null && partnerUid.isNotEmpty;
        _partnerUid = _paired ? partnerUid : null;
        if (!_paired) _partnerName = 'Partner';
      });
      if (_paired && _partnerUid != null) {
        _attachPartnerListener(_partnerUid!);
      }
    });
  }

  void _attachPartnerListener(String partnerUid) {
    _partnerListener?.cancel();
    _partnerListener = FirebaseDatabase.instance
        .ref()
        .child('users/$partnerUid')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data == null || !mounted) return;
      final map = Map<dynamic, dynamic>.from(data as Map);
      setState(() {
        _partnerName = map['name']?.toString() ?? _partnerName;
      });
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur ini segera hadir!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAvatar() {
    final fallback = Image.asset(
      'assets/images/logo.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.person_rounded,
        size: 90,
        color: Color(0xFF964549),
      ),
    );
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return Image.network(
        _photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return fallback;
  }

  Future<void> _editProfile() async {
    final controller = TextEditingController(text: _userName);
    XFile? picked;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final file = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 600,
                    maxHeight: 600,
                    imageQuality: 85,
                  );
                  if (file != null) setDialogState(() => picked = file);
                },
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (picked != null)
                        Image.file(File(picked!.path), fit: BoxFit.cover)
                      else if (_photoUrl != null && _photoUrl!.isNotEmpty)
                        Image.network(
                          _photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Image.asset('assets/images/logo.png'),
                        )
                      else
                        Image.asset('assets/images/logo.png'),
                      Container(
                        color: Colors.black26,
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ketuk untuk ganti foto',
                style: TextStyle(fontSize: 12, color: _onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Nama kamu',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    final user = _authService.currentUser;
    if (result == null || result.isEmpty || user == null) return;

    var photoUrl = _photoUrl;
    if (picked != null) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      try {
        photoUrl = await _partnerService.uploadProfilePhoto(picked!.path);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto gagal diupload, nama tetap tersimpan'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) Navigator.pop(context);
      }
    }

    final updates = <String, Object?>{'name': result};
    if (photoUrl != null) updates['photo_url'] = photoUrl;
    await FirebaseDatabase.instance
        .ref()
        .child('users/${user.uid}')
        .update(updates);
    if (mounted) setState(() => _userName = result);
  }

  Future<void> _connectPartner() async {
    String? myCode;
    try {
      myCode = await _partnerService.getMyCode();
    } catch (_) {}
    final codeController = TextEditingController();
    final submitted = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hubungkan dengan Pasangan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (myCode != null) ...[
              Text(
                'Kode kamu (kirim ke pasangan):',
                style: TextStyle(fontSize: 13, color: _onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  myCode,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    color: _onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'Kode pasangan (6 digit)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, codeController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text('Hubungkan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (submitted == null || submitted.isEmpty || !mounted) return;
    try {
      await _partnerService.pairByCode(submitted);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kamu berhasil terhubung dengan pasangan!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _disconnectPartner() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yakin mau putus?'),
        content: const Text(
          'Hubungan dengan pasanganmu akan diputus dan data couple dihapus. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: _error),
            child: const Text('Ya, Putus',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final verifyCode = _partnerService.generateCode();
    final codeController = TextEditingController();
    final submitted = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Verifikasi Kode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Masukkan kode berikut untuk mengonfirmasi putus hubungan:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text(
              verifyCode,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: _error,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ketik kode di atas',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, codeController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: _error),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (submitted == null || !mounted) return;

    if (submitted != verifyCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode salah, hubungan tidak diputus'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await _partnerService.unpair();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kamu sudah putus dari pasangan'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildMenuCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: const Row(
        children: [
          SizedBox(width: 40),
          Expanded(child: SizedBox()),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 192,
          height: 192,
          fit: BoxFit.cover,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                _paired
                    ? '$_userName & $_partnerName'
                    : _userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '♥',
              style: TextStyle(fontSize: 18, color: _primary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _paired && _sinceText.isNotEmpty
              ? 'Together since $_sinceText'
              : 'Belum terhubung dengan pasangan',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: _onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildMenuCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 30,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_paired) ...[
            _buildMenuTile(
              icon: Icons.favorite_rounded,
              label: 'Kamu sudah terhubung',
              showChevron: false,
              onTap: () {},
            ),
            _buildMenuTile(
              icon: Icons.link_off_rounded,
              label: 'Putus Hubungan',
              color: _error,
              bg: _errorContainer.withOpacity(0.5),
              showChevron: false,
              onTap: _disconnectPartner,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child:
                  Divider(height: 1, thickness: 1, color: _surfaceVariant),
            ),
          ] else
            _buildMenuTile(
              icon: Icons.favorite_rounded,
              label: 'Hubungkan',
              onTap: _connectPartner,
            ),
          _buildMenuTile(
            icon: Icons.edit_rounded,
            label: 'Edit Profile',
            onTap: _editProfile,
          ),
          _buildMenuTile(
            icon: Icons.lock_rounded,
            label: 'Privasi',
            onTap: () => Navigator.pushNamed(context, '/app-lock'),
          ),
          _buildMenuTile(
            icon: Icons.notifications_rounded,
            label: 'Notifikasi',
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          _buildMenuTile(
            icon: Icons.language_rounded,
            label: 'Bahasa',
            trailing: Text(
              'Indonesia',
              style: TextStyle(fontSize: 14, color: _onSurfaceVariant),
            ),
            onTap: _comingSoon,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, thickness: 1, color: _surfaceVariant),
          ),
          _buildMenuTile(
            icon: Icons.logout_rounded,
            label: 'Logout',
            color: _error,
            bg: _errorContainer.withOpacity(0.5),
            showChevron: false,
            onTap: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF964549),
    Color? bg,
    Widget? trailing,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg ?? _secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color == _error ? color : _onSurface,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 4),
            ],
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                color: _onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
