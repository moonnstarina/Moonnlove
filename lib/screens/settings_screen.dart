import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';
import '../services/partner_service.dart';
import 'account_settings_screen.dart';

const Color _background = Color(0xFFF8F9FA);
const Color _primary = Color(0xFF964549);
const Color _primaryContainer = Color(0xFFFF999C);
const Color _onSurface = Color(0xFF191C1D);
const Color _onSurfaceVariant = Color(0xFF544242);
const Color _secondaryContainer = Color(0xFFF1DEDE);
const Color _error = Color(0xFFBA1A1A);
const Color _errorContainer = Color(0xFFFFDAD6);
const Color _surfaceVariant = Color(0xFFE1E3E4);

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _authService.currentUser;
    if (user == null) return;
    final data = await _authService.getUserData(user.uid);
    if (!mounted) return;
    setState(() {
      _userName = data?['name'] ?? 'User';
      _paired =
          data?['partner_uid']?.toString().isNotEmpty == true;
    });
    if (_paired) {
      final partner = await _partnerService.getPartnerData();
      if (mounted) {
        setState(() {
          _partnerName = partner?['name'] ?? 'Partner';
        });
      }
    }
    final coupleId = await _partnerService.getCoupleId();
    if (coupleId != null && mounted) {
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

  Future<void> _editProfile() async {
    final controller = TextEditingController(text: _userName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Nama'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nama kamu',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    final user = _authService.currentUser;
    if (newName == null || newName.isEmpty || user == null) return;
    await FirebaseDatabase.instance
        .ref()
        .child('users/${user.uid}')
        .update({'name': newName});
    if (mounted) setState(() => _userName = newName);
  }

  @override
  Widget build(BuildContext context) {
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
        Container(
          width: 192,
          height: 192,
          decoration: const BoxDecoration(
            color: Color(0xFFFFDAD9),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/couple.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.person_rounded,
                size: 90,
                color: Color(0xFF964549),
              ),
            ),
          ),
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
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
          style: const TextStyle(fontSize: 14, color: _onSurfaceVariant),
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
          _buildMenuTile(
            icon: Icons.edit_rounded,
            label: 'Edit Profile',
            onTap: _editProfile,
          ),
          _buildMenuTile(
            icon: Icons.settings_rounded,
            label: 'Pengaturan Akun',
            onTap: () =>
                Navigator.pushNamed(context, '/account-settings'),
          ),
          _buildMenuTile(
            icon: Icons.lock_rounded,
            label: 'Privasi',
            onTap: _comingSoon,
          ),
          _buildMenuTile(
            icon: Icons.notifications_rounded,
            label: 'Notifikasi',
            onTap: _comingSoon,
          ),
          _buildMenuTile(
            icon: Icons.language_rounded,
            label: 'Bahasa',
            trailing: const Text(
              'Indonesia',
              style: TextStyle(fontSize: 14, color: _onSurfaceVariant),
            ),
            onTap: _comingSoon,
          ),
          const Padding(
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
    Color color = _primary,
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
              const Icon(
                Icons.chevron_right_rounded,
                color: _onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
