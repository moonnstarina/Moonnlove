import 'package:flutter/material.dart';
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

  static const _games = [
    (
      icon: Icons.local_fire_department_rounded,
      title: 'Free Fire',
      status: 'Not Playing',
      playing: false,
      color: _primary,
      bg: Color(0x33FF999C),
      glow: Color(0x1AFF999C),
      button: 'Ajak Main',
    ),
    (
      icon: Icons.sports_martial_arts_rounded,
      title: 'Mobile Legends',
      status: 'Playing for 20 mins',
      playing: true,
      color: _tertiary,
      bg: Color(0x33CAAFAF),
      glow: Color(0x1ACAAFAF),
      button: 'Kirim Notif',
    ),
    (
      icon: Icons.grid_view_rounded,
      title: 'Minecraft',
      status: 'Not Playing',
      playing: false,
      color: _secondary,
      bg: Color(0x66F1DEDE),
      glow: Color(0x33F1DEDE),
      button: 'Ajak Main',
    ),
    (
      icon: Icons.emoji_people_rounded,
      title: 'Super Sus',
      status: 'Not Playing',
      playing: false,
      color: _primary,
      bg: Color(0x33FF999C),
      glow: Color(0x1AFF999C),
      button: 'Ajak Main',
    ),
    (
      icon: Icons.category_rounded,
      title: 'Roblox',
      status: 'Not Playing',
      playing: false,
      color: _tertiary,
      bg: Color(0x33CAAFAF),
      glow: Color(0x1ACAAFAF),
      button: 'Ajak Main',
    ),
  ];

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
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur ini segera hadir!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                  for (var i = 0; i < _games.length; i++) ...[
                    _buildGameCard(i, _games[i]),
                    const SizedBox(height: 16),
                  ],
                  _buildAddGameCard(),
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

  Widget _buildGameCard(
    int index,
    ({
      IconData icon,
      String title,
      String status,
      bool playing,
      Color color,
      Color bg,
      Color glow,
      String button,
    }) game,
  ) {
    return Container(
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
                      game.status,
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
                    game.button,
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
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Tambah Game',
          style: TextStyle(fontWeight: FontWeight.w700, color: _onSurface),
        ),
        content: TextField(
          controller: controller,
          maxLength: 30,
          style: const TextStyle(color: _onSurface),
          decoration: InputDecoration(
            hintText: 'Nama game...',
            hintStyle: const TextStyle(color: _onSurfaceVariant),
            filled: true,
            fillColor: _surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: _onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name berhasil ditambahkan ke daftarmu!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
