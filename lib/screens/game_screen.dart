import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../services/game_detector_service.dart';
import '../services/partner_service.dart';

const Color _background = Color(0xFFF8F9FA);
const Color _primary = Color(0xFF964549);
const Color _primaryContainer = Color(0xFFFF999C);
const Color _onPrimaryContainer = Color(0xFF792E33);
const Color _onPrimary = Color(0xFFFFFFFF);
const Color _onSurface = Color(0xFF191C1D);
const Color _onSurfaceVariant = Color(0xFF544242);
const Color _surfaceLowest = Color(0xFFFFFFFF);
const Color _surfaceContainerHigh = Color(0xFFE7E8E9);
const Color _surfaceContainerLow = Color(0xFFF3F4F5);
const Color _outlineVariant = Color(0xFFDAC1C0);
const Color _secondary = Color(0xFF695B5B);
const Color _secondaryContainer = Color(0xFFF1DEDE);
const Color _tertiary = Color(0xFF6E595A);
const Color _tertiaryContainer = Color(0xFFCAAFAF);

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
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatOffset;
  final _partnerService = PartnerService();

  final List<_GameInfo> _customGames = [];
  StreamSubscription<DatabaseEvent>? _gamesSub;
  Timer? _detectTimer;
  bool _hasPermission = false;
  bool _detecting = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatOffset = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _initDetection();
    _initCustomGames();
  }

  Future<void> _initCustomGames() async {
    final ref = await _partnerService.getGamesRef();
    if (ref == null || !mounted) return;
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
              bg: const Color(0x33FF999C),
              glow: const Color(0x1AFF999C),
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
    _detecting = true;
    final package = await GameDetectorService.getForegroundPackage();
    final since = await GameDetectorService.getForegroundSince();
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
    await Future.delayed(const Duration(seconds: 2));
    _hasPermission = await GameDetectorService.hasUsagePermission();
    if (mounted) {
      setState(() {});
      if (_hasPermission) _checkForegroundGame();
    }
  }

  @override
  void dispose() {
    _gamesSub?.cancel();
    _detectTimer?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  String _statusText(_GameInfo game) {
    if (!game.playing) return 'Not Playing';
    final elapsed = DateTime.now().difference(game.playingSince!).inMinutes;
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
                  const Text(
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
                  const Text(
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
          const Icon(Icons.visibility_rounded, color: _onPrimaryContainer),
          const SizedBox(width: 12),
          const Expanded(
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
              child: const Text(
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
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: _onSurface,
                  size: 24,
                ),
              ),
            ),
          ),
          const Text(
            'Game',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 16,
                    color: Color(0xFFFBC02D),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '120',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _onSurface,
                    ),
                  ),
                ],
              ),
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
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x33FF999C), _surfaceLowest],
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
                        style: const TextStyle(
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
                              game.playing ? FontWeight.w700 : FontWeight.w400,
                          color: game.playing ? _primary : _onSurfaceVariant,
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
            decoration: const BoxDecoration(
              color: Color(0x33FF999C),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: _primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada game',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
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
            const Icon(
              Icons.add_circle_rounded,
              color: _onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
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
    var manual = installed.isEmpty;

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
            title: const Text(
              'Tambah Game',
              style: TextStyle(fontWeight: FontWeight.w700, color: _onSurface),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Pilih dari HP'),
                        icon: Icon(Icons.smartphone_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Ketik Manual'),
                        icon: Icon(Icons.keyboard_rounded, size: 18),
                      ),
                    ],
                    selected: {manual},
                    onSelectionChanged: (s) =>
                        setDialogState(() => manual = s.first),
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (manual)
                    TextField(
                      controller: controller,
                      maxLength: 30,
                      autofocus: true,
                      style: const TextStyle(color: _onSurface),
                      decoration: InputDecoration(
                        hintText: 'Nama game...',
                        hintStyle:
                            const TextStyle(color: _onSurfaceVariant),
                        filled: true,
                        fillColor: _surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (v) {
                        final name = v.trim();
                        if (name.isNotEmpty) {
                          Navigator.pop(
                              context, (name: name, package: ''));
                        }
                      },
                    )
                  else ...[
                    TextField(
                      controller: controller,
                      style: const TextStyle(color: _onSurface),
                      decoration: InputDecoration(
                        hintText: 'Cari app...',
                        hintStyle:
                            const TextStyle(color: _onSurfaceVariant),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _onSurfaceVariant,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: _surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Tidak ada app yang cocok. Coba pilih "Ketik Manual".',
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
                                    child: const Icon(
                                      Icons.sports_esports_rounded,
                                      color: _primary,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    app.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _onSurface,
                                    ),
                                  ),
                                  subtitle: Text(
                                    app.package,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: _onSurfaceVariant),
                ),
              ),
              if (manual)
                FilledButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      Navigator.pop(context, (name: name, package: ''));
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Simpan'),
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
          style: const TextStyle(fontWeight: FontWeight.w700, color: _onSurface),
        ),
        content: const Text(
          'Game akan dihapus dari daftar bareng untuk kalian berdua.',
          style: TextStyle(color: _onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
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
