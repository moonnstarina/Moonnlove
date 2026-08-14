import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

const Color _background = Color(0xFFF8F9FA);
const Color _primary = Color(0xFF964549);
const Color _primaryContainer = Color(0xFFFF999C);
const Color _onPrimaryContainer = Color(0xFF792E33);
const Color _onPrimary = Color(0xFFFFFFFF);
const Color _onSurface = Color(0xFF191C1D);
const Color _onSurfaceVariant = Color(0xFF544242);
const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
const Color _surfaceContainerHigh = Color(0xFFE7E8E9);
const Color _surfaceContainerHighest = Color(0xFFE1E3E4);
const Color _surfaceVariant = Color(0xFFE1E3E4);
const Color _secondary = Color(0xFF695B5B);
const Color _secondaryContainer = Color(0xFFF1DEDE);
const Color _onSecondaryContainer = Color(0xFF6F6161);
const Color _secondaryFixed = Color(0xFFF1DEDE);
const Color _outline = Color(0xFF877272);

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({
    super.key,
    required this.tracks,
    this.initialIndex = 0,
    this.note = 'This song always reminds me of you! ❤️',
  });

  final List<({String cover, String title, String artist})> tracks;
  final int initialIndex;
  final String note;

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late int _index = widget.initialIndex;
  late bool _playing = true;
  late bool _liked = false;
  int _position = 0;
  Timer? _ticker;

  static const int _duration = 221;

  ({String cover, String title, String artist}) get _track => widget.tracks[_index];

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    if (!_playing) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_position < _duration - 1) {
          _position++;
        } else {
          _next();
        }
      });
    });
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    _startTicker();
  }

  void _toggleLike() => setState(() => _liked = !_liked);

  void _seek(int seconds) => setState(() => _position = max(0, min(_duration, seconds)));

  void _prev() {
    setState(() {
      _index = (_index - 1 + widget.tracks.length) % widget.tracks.length;
      _position = 0;
    });
  }

  void _next() {
    setState(() {
      _index = (_index + 1) % widget.tracks.length;
      _position = 0;
    });
  }

  String _fmt(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  _buildAlbumArt(),
                  const SizedBox(height: 32),
                  _buildSongInfo(),
                  const SizedBox(height: 8),
                  _buildScrubber(),
                  const SizedBox(height: 12),
                  _buildControls(),
                  const SizedBox(height: 32),
                  _buildSharedNote(),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _surfaceContainerHigh,
                  shape: BoxShape.circle,
                  border: Border.all(color: _surfaceVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/player_avatar.jpg',
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

  Widget _buildAlbumArt() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: _secondaryFixed,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F964549),
                  blurRadius: 40,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _track.cover,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.music_note_rounded,
                    color: _primary,
                    size: 72,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0x0D000000)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          children: [
            Text(
              _track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.02,
                color: _onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrubber() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  onTapDown: (details) {
                    final ratio = (details.localPosition.dx / width).clamp(0.0, 1.0);
                    _seek((ratio * _duration).round());
                  },
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: _surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (_position / _duration).clamp(0.0, 1.0),
                      child: Container(
                        decoration: const BoxDecoration(color: _primary),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(_position),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _outline,
                    ),
                  ),
                  Text(
                    _fmt(_duration),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _controlButton(
            onTap: _toggleLike,
            child: Icon(
              _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 28,
              color: _liked ? _primary : _outline,
            ),
          ),
          _controlButton(
            onTap: _prev,
            child: const Icon(
              Icons.skip_previous_rounded,
              size: 32,
              color: _onSurfaceVariant,
            ),
          ),
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40964549),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 40,
                color: _onPrimary,
              ),
            ),
          ),
          _controlButton(
            onTap: _next,
            child: const Icon(
              Icons.skip_next_rounded,
              size: 32,
              color: _onSurfaceVariant,
            ),
          ),
          const SizedBox(
            width: 48,
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _controlButton({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: child,
      ),
    );
  }

  Widget _buildSharedNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _surfaceVariant.withOpacity(0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F964549),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              size: 20,
              color: _onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Shared Note',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: _primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.note,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
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
}
