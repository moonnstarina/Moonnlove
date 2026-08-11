import 'package:flutter/material.dart';

const Color _background = Color(0xFFF8F9FA);
const Color _primary = Color(0xFF964549);
const Color _primaryContainer = Color(0xFFFF999C);
const Color _onPrimary = Color(0xFFFFFFFF);
const Color _onSurface = Color(0xFF191C1D);
const Color _onSurfaceVariant = Color(0xFF544242);
const Color _surfaceLowest = Color(0xFFFFFFFF);
const Color _surfaceContainerHigh = Color(0xFFE7E8E9);
const Color _secondary = Color(0xFF695B5B);
const Color _secondaryContainer = Color(0xFFF1DEDE);
const Color _tertiary = Color(0xFF6E595A);
const Color _tertiaryContainer = Color(0xFFCAAFAF);

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur ini segera hadir!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final games = [
      _GameItem(
        icon: Icons.favorite_rounded,
        title: 'Couple Quiz',
        desc: 'Test how well you know each other!',
        color: _primary,
        bg: _primaryContainer.withOpacity(0.2),
      ),
      _GameItem(
        icon: Icons.style_rounded,
        title: 'Love Memory',
        desc: 'Find matching cards together',
        color: _tertiary,
        bg: _tertiaryContainer.withOpacity(0.2),
      ),
      _GameItem(
        icon: Icons.casino_rounded,
        title: 'Truth or Dare',
        desc: 'Fun questions & challenges ♥',
        color: _secondary,
        bg: _secondaryContainer.withOpacity(0.4),
      ),
      _GameItem(
        icon: Icons.task_alt_rounded,
        title: 'Couple Challenge',
        desc: 'Complete tasks together',
        color: _primary,
        bg: _primaryContainer.withOpacity(0.2),
      ),
    ];

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  _buildHero(),
                  const SizedBox(height: 32),
                  const Text(
                    'Time to Play!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Have fun together and discover new things about each other.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final game in games)
                    _buildGameCard(context, game),
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Game',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
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
    return Center(
      child: Container(
        width: 192,
        height: 192,
        decoration: BoxDecoration(
          color: _secondaryContainer.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/game_hero.jpg',
                fit: BoxFit.cover,
                color: _primary.withOpacity(0.15),
                colorBlendMode: BlendMode.multiply,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.sports_esports_rounded,
                  size: 80,
                  color: Color(0x66FF999C),
                ),
              ),
            ),
            const Center(
              child: Icon(
                Icons.sports_esports_rounded,
                size: 80,
                color: Color(0x66FF999C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, _GameItem game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  game.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _comingSoon(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Play',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameItem {
  const _GameItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final Color bg;
}
