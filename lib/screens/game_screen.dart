import '../providers/app_palette.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/game_detector_service.dart';
import '../services/partner_service.dart';

Color get _background => AppPalette.background;
Color get _primary => AppPalette.primary;
Color get _primaryContainer => AppPalette.primaryContainer;
Color get _onPrimaryContainer => AppPalette.onPrimaryContainer;
Color get _onPrimary => AppPalette.onPrimary;
Color get _onSurface => AppPalette.onSurface;
Color get _onSurfaceVariant => AppPalette.onSurfaceVariant;
Color get _surfaceLowest => AppPalette.surfaceLowest;
Color get _surfaceContainerLow => AppPalette.surfaceContainerLow;
Color get _outlineVariant => AppPalette.outlineVariant;
Color get _secondary => AppPalette.secondary;
Color get _secondaryContainer => AppPalette.secondaryContainer;
Color get _tertiary => AppPalette.tertiary;
Color get _tertiaryContainer => AppPalette.tertiaryContainer;

class _GameInfo {
  _GameInfo({
    required this.icon,
    required this.title,
    required this.color,
    required this.bg,
    required this.glow,
    this.firebaseKey,
    this.package,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Color bg;
  final Color glow;
  final String? firebaseKey;
  final String? package;
  bool playing = false;
  DateTime? playingSince;
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _floatController;
  late final Animation<double> _floatOffset;
  final _partnerService = PartnerService();
  final _authService = AuthService();

  final List<_GameInfo> _customGames = [];
  StreamSubscription<DatabaseEvent>? _gamesSub;
  StreamSubscription<DatabaseEvent>? _nowPlayingSub;
  Timer? _detectTimer;
  bool _hasPermission = false;
  bool _detecting = false;
  String? _mePlaying;
  Map<String, dynamic>? _partnerPlaying;
  DateTime? _partnerSince;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatOffset = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _initDetection();
    _initCustomGames();
    _initNowPlaying();
  }

  Future<void> _initCustomGames() async {
    final ref = await _partnerService.getGamesRef();
    if (ref == null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _gamesSub == null) _initCustomGames();
      });
      return;
    }
    _gamesSub?.cancel();
    _gamesSub = ref.onValue.listen((event) {
      if (!mounted) return;
      final value = event.snapshot.value;
      final games = <_GameInfo>[];
      if (value is Map) {
        value.forEach((key, raw) {
          if (raw is Map) {
            games.add(_GameInfo(
              icon: Icons.sports_esports_rounded,
              title: raw['name']?.toString() ?? 'Game',
              color: _primary,
              bg: _primaryContainer.withOpacity(0.2),
              glow: _primaryContainer.withOpacity(0.1),
              firebaseKey: key.toString(),
              package: raw['package']?.toString(),
            ));
          }
        });
      }
      setState(() {
        _customGames
          ..clear()
          ..addAll(games);
      });
    });
  }

  Future<void> _initNowPlaying() async {
    final ref = await _partnerService.getNowPlayingRef();
    if (ref == null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _nowPlayingSub == null) _initNowPlaying();
      });
      return;
    }
    _nowPlayingSub?.cancel();
    _nowPlayingSub = ref.onValue.listen((event) {
      if (!mounted) return;
      final value = event.snapshot.value;
      Map<String, dynamic>? partner;
      DateTime? partnerSince;
      final myUid = _authService.currentUser?.uid;
      if (value is Map) {
        value.forEach((key, raw) {
          if (key.toString() != myUid && raw is Map) {
            partner = raw.cast<String, dynamic>();
            final since = raw['since'];
            if (since is int) {
              partnerSince = DateTime.fromMillisecondsSinceEpoch(since);
            }
          }
        });
      }
      setState(() {
        _partnerPlaying = partner;
        _partnerSince = partnerSince;
      });
    });
  }

  Future<void> _initDetection() async {
    _hasPermission = await GameDetectorService.hasUsagePermission();
    if (mounted) {
      setState(() {});
    }
    _detectTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkForegroundGame(),
    );
    _checkForegroundGame();
  }

  Future<void> _checkForegroundGame() async {
    if (_detecting) return;
    if (!_hasPermission) return;
    if (_customGames.isEmpty) return;
    _detecting = true;
    final package = await GameDetectorService.getForegroundPackage();
    final since = await GameDetectorService.getForegroundSince();

    _GameInfo? detected;
    for (final game in _customGames) {
      final hasPackage = game.package?.isNotEmpty == true;
      final matched = hasPackage
          ? package == game.package
          : GameDetectorService.gameNameForPackage(package) == game.title;
      if (matched) {
        detected = game;
        break;
      }
    }

    if (detected?.title != _mePlaying) {
      _mePlaying = detected?.title;
      try {
        if (detected != null) {
          await _partnerService.setNowPlaying(
            package ?? '',
            detected.title,
            since ?? DateTime.now(),
          );
        } else {
          await _partnerService.clearNowPlaying();
        }
      } catch (_) {}
    }

    if (!mounted) {
      _detecting = false;
      return;
    }
    setState(() {
      for (final game in _customGames) {
        final hasPackage = game.package?.isNotEmpty == true;
        final matched = hasPackage
            ? package == game.package
            : GameDetectorService.gameNameForPackage(package) == game.title;
        if (matched) {
          if (!game.playing) {
            game.playing = true;
            game.playingSince = since ?? DateTime.now();
          }
        } else {
          game.playing = false;
          game.playingSince = null;
        }
      }
    });
    _detecting = false;
  }

  Future<void> _requestPermission() async {
    await GameDetectorService.openUsageSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshOnResume();
    }
  }

  Future<void> _refreshOnResume() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _hasPermission = await GameDetectorService.hasUsagePermission();
    if (mounted) setState(() {});
    if (_hasPermission) _checkForegroundGame();
    if (_gamesSub == null) _initCustomGames();
    if (_nowPlayingSub == null) _initNowPlaying();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gamesSub?.cancel();
    _nowPlayingSub?.cancel();
    _detectTimer?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  bool _isPartnerPlaying(_GameInfo game) {
    final p = _partnerPlaying;
    if (p == null) return false;
    final package = p['package']?.toString();
    final name = p['game']?.toString();
    final hasPackage = game.package?.isNotEmpty == true;
    if (package != null && package.isNotEmpty) {
      return hasPackage
          ? package == game.package
          : GameDetectorService.gameNameForPackage(package) == game.title;
    }
    return name == game.title;
  }

  String _statusText(_GameInfo game) {
    final local = game.playing;
    final partner = _isPartnerPlaying(game);
    if (!local && !partner) return 'Not Playing';
    final since = local ? game.playingSince! : _partnerSince!;
    final elapsed = DateTime.now().difference(since).inMinutes;
    return 'Playing for $elapsed mins';
  }

  Future<void> _sendGameAction(String gameName, {required bool invite}) async {
    try {
      await _partnerService.sendGameMessage(gameName, invite: invite);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(invite
                ? 'Ajakan bermain $gameName terkirim! 🎮'
                : 'Notifikasi $gameName terkirim! 🎮'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _buildHero(),
                  const SizedBox(height: 32),
                  Text(
                    'Time to Play!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.02,
                      color: _onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Have fun together and discover new things about each other.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_hasPermission) _buildPermissionBanner(),
                  if (_customGames.isEmpty)
                    _buildEmptyGames()
                  else
                    for (var i = 0; i < _customGames.length; i++) ...[
                      _buildGameCard(i, _customGames[i]),
                      const SizedBox(height: 16),
                    ],
                  const SizedBox(height: 4),
                  _buildAddGameCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryContainer.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility_rounded, color: _onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Izinkan akses penggunaan aplikasi untuk mendeteksi game yang sedang dimainkan.',
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: _onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _requestPermission,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Izinkan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                widget.onNavigateToTab?.call(0);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: _onSurface,
                  size: 24,
                ),
              ),
            ),
          ),
          Text(
            'Game',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return AnimatedBuilder(
      animation: _floatOffset,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, _floatOffset.value),
        child: Center(
          child: Container(
            width: 192,
            height: 192,
            decoration: BoxDecoration(
              color: _secondaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primaryContainer.withOpacity(0.2), _surfaceLowest],
                    ),
                  ),
                ),
                Image.asset(
                  'assets/images/game_hero.jpg',
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.9),
                  color: _primary.withOpacity(0.15),
                  colorBlendMode: BlendMode.multiply,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.sports_esports_rounded,
                    size: 80,
                    color: Color(0x66FF999C),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(int index, _GameInfo game) {
    final playingNow = game.playing || _isPartnerPlaying(game);
    return GestureDetector(
      onLongPress: () => _removeGame(game),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              bottom: -40,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: game.glow,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: game.bg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(game.icon, color: game.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _statusText(game),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              playingNow ? FontWeight.w700 : FontWeight.w400,
                          color: playingNow ? _primary : _onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _sendGameAction(
                    game.title,
                    invite: !game.playing,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: game.playing ? _primaryContainer : _primary,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: game.playing
                          ? []
                          : [
                              BoxShadow(
                                color: _primary.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Text(
                      game.playing ? 'Kirim Notif' : 'Ajak Main',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: game.playing ? _onPrimaryContainer : _onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGames() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _primaryContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_esports_rounded,
              color: _primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada game',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambah game yang kalian mainkan bareng, list-nya otomatis muncul di HP pasanganmu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: _onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddGameCard() {
    return GestureDetector(
      onTap: _addGame,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _outlineVariant, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_rounded,
              color: _onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Tambah Game',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addGame() async {
    final installed = await GameDetectorService.getInstalledApps();
    final controller = TextEditingController();

    final draft = await showDialog<({String name, String package})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = installed
              .where((a) => a.label.toLowerCase().contains(
                    controller.text.toLowerCase(),
                  ))
              .toList();
          return AlertDialog(
            backgroundColor: const Color(0xFFFFFFFF),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'Tambah Game',
              style: TextStyle(fontWeight: FontWeight.w700, color: _onSurface),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pilih game yang terpasang di HP-mu',
                      style: TextStyle(
                        fontSize: 13,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    style: TextStyle(color: _onSurface),
                    decoration: InputDecoration(
                      hintText: 'Cari game...',
                      hintStyle: TextStyle(color: _onSurfaceVariant),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: _onSurfaceVariant,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: _surfaceLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: installed.isEmpty
                        ? Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Gagal memuat daftar app dari HP.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: _onSurfaceVariant,
                              ),
                            ),
                          )
                        : filtered.isEmpty
                            ? Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Tidak ada game yang cocok.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _onSurfaceVariant,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: filtered.length > 12
                                    ? 12
                                    : filtered.length,
                                itemBuilder: (context, i) {
                                  final app = filtered[i];
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: _surfaceContainerLow,
                                      child: Icon(
                                        Icons.sports_esports_rounded,
                                        color: _primary,
                                        size: 18,
                                      ),
                                    ),
                                    title: Text(
                                      app.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _onSurface,
                                      ),
                                    ),
                                    subtitle: Text(
                                      app.package,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _onSurfaceVariant,
                                      ),
                                    ),
                                    onTap: () => Navigator.pop(
                                      context,
                                      (name: app.label, package: app.package),
                                    ),
                                  );
                                },
                              ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: TextStyle(color: _onSurfaceVariant),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (draft != null && draft.name.trim().isNotEmpty) {
      try {
        await _partnerService.addGame(
          draft.name.trim(),
          package: draft.package,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${draft.name.trim()} ditambahkan ke daftar bareng!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeGame(_GameInfo game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hapus ${game.title}?',
          style: TextStyle(fontWeight: FontWeight.w700, color: _onSurface),
        ),
        content: Text(
          'Game akan dihapus dari daftar bareng untuk kalian berdua.',
          style: TextStyle(color: _onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(color: _onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && game.firebaseKey != null) {
      try {
        await _partnerService.removeGame(game.firebaseKey!);
      } catch (_) {}
    }
  }
}
