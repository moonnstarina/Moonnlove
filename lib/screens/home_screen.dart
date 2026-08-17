import '../providers/app_palette.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/partner_service.dart';

Color get _background => AppPalette.background;
Color get _primary => AppPalette.primary;
Color get _primaryContainer => AppPalette.primaryContainer;
Color get _primaryFixed => AppPalette.primaryFixed;
Color get _onSurface => AppPalette.onSurface;
Color get _onSurfaceVariant => AppPalette.onSurfaceVariant;
Color get _outline => AppPalette.outline;
Color get _surfaceLowest => AppPalette.surfaceLowest;
Color get _surfaceContainer => AppPalette.surfaceContainer;
Color get _secondary => AppPalette.secondary;
Color get _secondaryContainer => AppPalette.secondaryContainer;
Color get _tertiary => AppPalette.tertiary;
Color get _tertiaryContainer => AppPalette.tertiaryContainer;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onNavigateToTab});

  final void Function(int index)? onNavigateToTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _authService = AuthService();
  final _partnerService = PartnerService();

  String _userName = 'User';
  String _partnerName = 'Partner';
  String? _partnerPhotoUrl;
  bool _paired = false;
  int _days = 0;
  String _sinceText = '';
  String? _partnerUid;
  DateTime? _sinceDate;
  Timer? _daysTimer;
  StreamSubscription<DatabaseEvent>? _userListener;
  StreamSubscription<DatabaseEvent>? _partnerListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _listenUserData();
    _loadTimeTogether();
    _scheduleDayRollover();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _daysTimer?.cancel();
    _userListener?.cancel();
    _partnerListener?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDays();
      _scheduleDayRollover();
    }
  }

  DateTime _nextMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1)
        .add(const Duration(seconds: 1));
  }

  void _scheduleDayRollover() {
    _daysTimer?.cancel();
    final delay = _nextMidnight().difference(DateTime.now());
    _daysTimer = Timer(delay, () {
      _refreshDays();
      _scheduleDayRollover();
    });
  }

  void _refreshDays() {
    final since = _sinceDate;
    if (since == null || !mounted) return;
    final days = DateTime.now().difference(since).inDays;
    if (days != _days) setState(() => _days = days);
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user == null) return;
    final data = await _authService.getUserData(user.uid);
    if (data != null && mounted) {
      setState(() {
        _userName = data['name'] ?? 'User';
        _partnerUid = data['partner_uid']?.toString();
        _paired = _partnerUid != null && _partnerUid!.isNotEmpty;
        if (!_paired) _partnerName = 'Partner';
      });
      if (_paired) _attachPartnerListener(_partnerUid!);
    }
  }

  void _listenUserData() {
    final user = _authService.currentUser;
    if (user == null) return;
    _userListener = FirebaseDatabase.instance
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
        _partnerPhotoUrl = map['photo_url']?.toString();
      });
    });
  }

  Future<void> _loadTimeTogether() async {
    final coupleId = await _partnerService.getCoupleId();
    if (coupleId == null || !mounted) return;
    var since = await _partnerService.getAnniversary();
    if (since == null) {
      final event = await FirebaseDatabase.instance
          .ref()
          .child('couples/$coupleId/created_at')
          .once();
      final created = event.snapshot.value;
      if (created is int) {
        since = DateTime.fromMillisecondsSinceEpoch(created);
      }
    }
    final resolved = since;
    if (resolved == null || !mounted) return;
    setState(() {
      _sinceDate = resolved;
      _days = DateTime.now().difference(resolved).inDays;
      _sinceText = _formatDate(resolved);
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur ini segera hadir!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final coupleName = _paired ? '$_userName ♥ $_partnerName' : _userName;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(coupleName),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroCard(),
                    const SizedBox(height: 24),
                    _buildInteractionBar(),
                    const SizedBox(height: 32),
                    _buildTimeTogetherCard(),
                    const SizedBox(height: 32),
                    _buildQuickActions(primaryColor),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(String coupleName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupleName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
                Text(
                  _paired ? 'Online' : 'Belum terhubung',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _primaryFixed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: _partnerPhotoUrl != null
                  ? Image.network(
                      _partnerPhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildHeroImage(),
                    )
                  : _buildHeroImage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return Image.asset(
      'assets/images/logo.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(
        Icons.favorite,
        size: 80,
        color: _primary,
      ),
    );
  }

  Future<void> _sendInteraction(String key, String label) async {
    if (!_paired) {
      _showComingSoon();
      return;
    }
    const messages = {
      'heart': 'Mengirim cinta buat kamu ❤️',
      'hug': 'Mengirim pelukan hangat 🤗',
      'kiss': 'Mengirim ciuman 😘',
      'miss': 'Kangen kamu 🥺',
      'mood': 'Gimana kabarmu hari ini? 😊',
    };
    try {
      await _partnerService.sendInteraction(key, messages[key] ?? label);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terkirim ke $_partnerName 💌'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
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

  Widget _buildInteractionBar() {
    const items = [
      (key: 'heart', emoji: '❤️', label: 'Send Love'),
      (key: 'hug', emoji: '🤗', label: 'Hug'),
      (key: 'kiss', emoji: '😘', label: 'Ciuman'),
      (key: 'miss', emoji: '🥺', label: 'I Miss You'),
      (key: 'mood', emoji: '😊', label: 'Check Mood'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Kirim ke pasangan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.map((item) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _sendInteraction(item.key, item.label),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _primaryContainer.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTogetherCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(
                Icons.favorite_rounded,
                size: 40,
                color: _primary.withOpacity(0.2),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Our Time Together',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$_days',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Days',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _paired && _sinceText.isNotEmpty
                    ? 'Since $_sinceText'
                    : 'Hubungkan pasangan dulu',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Color primaryColor) {
    final items = [
      _QuickAction(
        icon: Icons.local_fire_department_rounded,
        label: 'Streak',
        bg: _tertiaryContainer.withOpacity(0.2),
        fg: _tertiary,
        route: '/streak',
      ),
      _QuickAction(
        icon: Icons.music_note_rounded,
        label: 'Note & Playlist',
        bg: _tertiaryContainer.withOpacity(0.2),
        fg: _tertiary,
        route: '/notes',
        more: true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              _buildQuickActionTile(item, primaryColor),
              if (i != items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _surfaceContainer,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildQuickActionTile(_QuickAction item, Color primaryColor) {
    return InkWell(
      onTap: () {
        if (item.route != null) {
          Navigator.pushNamed(context, item.route!);
        } else if (item.tab != null && widget.onNavigateToTab != null) {
          widget.onNavigateToTab!(item.tab!);
        } else {
          _showComingSoon();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.bg,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.fg, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _onSurface,
                ),
              ),
            ),
            if (item.more)
              Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text(
                  'More',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _onSurfaceVariant,
                  ),
                ),
              ),
            Icon(Icons.chevron_right_rounded, color: _onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    this.tab,
    this.route,
    this.more = false,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final int? tab;
  final String? route;
  final bool more;
}
