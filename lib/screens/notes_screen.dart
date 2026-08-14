import 'package:flutter/material.dart';

const Color _background = Color(0xFFF8F9FA);
const Color _primary = Color(0xFF964549);
const Color _primaryContainer = Color(0xFFFF999C);
const Color _onPrimaryContainer = Color(0xFF792E33);
const Color _onSurface = Color(0xFF191C1D);
const Color _onSurfaceVariant = Color(0xFF544242);
const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
const Color _surfaceContainer = Color(0xFFEDEEEF);
const Color _tertiary = Color(0xFF6E595A);
const Color _tertiaryFixed = Color(0xFFF9DCDC);
const Color _onTertiaryFixed = Color(0xFF271818);
const Color _onTertiaryFixedVariant = Color(0xFF554242);
const Color _tertiaryContainer = Color(0xFFCAAFAF);
const Color _secondary = Color(0xFF695B5B);
const Color _secondaryContainer = Color(0xFFF1DEDE);
const Color _primaryFixed = Color(0xFFFFDAD9);
const Color _outline = Color(0xFF877272);
const Color _inverseSurface = Color(0xFF2E3132);
const Color _inversePrimary = Color(0xFFFFB3B4);
const Color _inverseOnSurface = Color(0xFFF0F1F2);

const _softShadow = [
  BoxShadow(
    color: Color(0x0A964549),
    blurRadius: 20,
    offset: Offset(0, 4),
  ),
];

const _interactiveShadow = [
  BoxShadow(
    color: Color(0x14964549),
    blurRadius: 20,
    offset: Offset(0, 4),
  ),
];

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const _notes = [
    (
      title: 'Song for rainy days',
      desc:
          'This one always reminds me of that afternoon we spent watching the rain from the balcony with hot cocoa.',
      bg: _surfaceContainerLowest,
      titleColor: _primary,
      descColor: _onSurfaceVariant,
      badgeBg: _primaryContainer,
      badgeIcon: Icons.push_pin_rounded,
      badgeColor: _onPrimaryContainer,
      rotation: 0.2,
    ),
    (
      title: 'Our first date theme',
      desc:
          "The cafe was playing this on loop. I couldn't stop looking at your eyes the whole time.",
      bg: _tertiaryFixed,
      titleColor: _onTertiaryFixed,
      descColor: _onTertiaryFixedVariant,
      badgeBg: _tertiaryContainer,
      badgeIcon: Icons.favorite_rounded,
      badgeColor: _onPrimaryContainer,
      rotation: -0.1,
    ),
    (
      title: 'Road trip vibes',
      desc:
          'Add this to the queue for next weekend. Windows down, volume up!',
      bg: _surfaceContainerLowest,
      titleColor: _secondary,
      descColor: _onSurfaceVariant,
      badgeBg: _secondaryContainer,
      badgeIcon: Icons.star_rounded,
      badgeColor: _secondary,
      rotation: 0.1,
    ),
  ];

  static const _tracks = [
    (
      cover: 'assets/images/cover1.jpg',
      title: 'Perfect',
      artist: 'Ed Sheeran',
    ),
    (
      cover: 'assets/images/cover2.jpg',
      title: 'Lover',
      artist: 'Taylor Swift',
    ),
    (
      cover: 'assets/images/cover3.jpg',
      title: 'Make You Feel My Love',
      artist: 'Adele',
    ),
  ];

  bool _playing = true;
  final _likes = {0: false, 1: true, 2: false};
  int _playingIndex = 1;

  void _toggleLike(int index) {
    setState(() => _likes[index] = !_likes[index]);
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  _buildPageHeader(),
                  const SizedBox(height: 32),
                  _buildSharedNotes(),
                  const SizedBox(height: 32),
                  _buildTopTracks(),
                ],
              ),
            ),
            _buildMiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _surfaceContainer,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/nav_avatar.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person,
                    color: _onSurfaceVariant,
                    size: 22,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_rounded,
                  color: _primary,
                  size: 26,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                ),
              ),
            ],
          ),
          const Text(
            'MoonLove',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: _primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.music_note_rounded,
            color: _onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Our Playlist',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
            color: _primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSharedNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shared Notes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _onSurface,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _notes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, i) => _buildNoteCard(_notes[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(
    ({String title, String desc, Color bg, Color titleColor, Color descColor, Color badgeBg, IconData badgeIcon, Color badgeColor, double rotation}) note,
  ) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: note.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceContainer),
        boxShadow: _softShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -12,
            right: -12,
            child: Transform.rotate(
              angle: note.rotation,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: note.badgeBg,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Color(0x1F000000), blurRadius: 4),
                  ],
                ),
                child: Icon(
                  note.badgeIcon,
                  color: note.badgeColor,
                  size: 16,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: note.titleColor,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  note.desc,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: note.descColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopTracks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Tracks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _onSurface,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _tracks.length; i++) ...[
          _buildTrackTile(i, _tracks[i]),
          if (i != _tracks.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildTrackTile(int index, ({String cover, String title, String artist}) track) {
    final isPlaying = _playing && index == _playingIndex;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPlaying ? _primaryFixed : _surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: isPlaying
            ? Border.all(color: _primaryContainer)
            : Border.all(color: Colors.transparent),
        boxShadow: _interactiveShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isPlaying ? _primary : _surfaceContainer,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  track.cover,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.music_note_rounded,
                    color: _onSurfaceVariant,
                    size: 24,
                  ),
                ),
                if (isPlaying)
                  Container(
                    color: _primary.withOpacity(0.4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildEqualizerBars(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isPlaying
                        ? const Color(0xFF3F030B)
                        : _onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: isPlaying
                        ? const Color(0xFF792E33)
                        : _onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _toggleLike(index),
            icon: Icon(
              _likes[index] == true
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: (_likes[index] == true)
                  ? _primary
                  : _outline,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEqualizerBars() {
    return [
      _bar(16, 1.0),
      const SizedBox(width: 2),
      _bar(8, 0.6),
      const SizedBox(width: 2),
      _bar(12, 0.8),
    ];
  }

  Widget _bar(double height, double amplitude) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: _inverseSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 12),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/cover2.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.music_note_rounded,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lover',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _inverseOnSurface,
                          ),
                        ),
                        Text(
                          'Taylor Swift',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: _inverseOnSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.skip_previous_rounded,
                      color: _inverseOnSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _playing = !_playing),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: _inversePrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: _onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: _inverseOnSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            ClipRRect(
              child: Stack(
                children: [
                  Container(height: 4, color: _surfaceContainer.withOpacity(0.2)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1 / 3,
                    child: Container(height: 4, color: _inversePrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
