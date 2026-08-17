import '../providers/app_palette.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Color get _background => AppPalette.background;
Color get _primary => AppPalette.primary;
Color get _primaryContainer => AppPalette.primaryContainer;
Color get _onPrimaryContainer => AppPalette.onPrimaryContainer;
Color get _onPrimary => AppPalette.onPrimary;
Color get _onSurface => AppPalette.onSurface;
Color get _onSurfaceVariant => AppPalette.onSurfaceVariant;
Color get _surfaceContainerLowest => AppPalette.surfaceContainerLowest;
Color get _surfaceContainerHigh => AppPalette.surfaceContainerHigh;
Color get _surfaceContainerHighest => AppPalette.surfaceContainerHighest;
Color get _surfaceVariant => AppPalette.surfaceVariant;
Color get _secondary => AppPalette.secondary;
Color get _secondaryContainer => AppPalette.secondaryContainer;
Color get _onSecondaryContainer => AppPalette.onSecondaryContainer;
Color get _secondaryFixed => AppPalette.secondaryFixed;
Color get _outline => AppPalette.outline;

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({
    super.key,
    required this.tracks,
    this.initialIndex = 0,
    this.note = 'This song always reminds me of you!',
  });

  final List<TrackInfo> tracks;
  final int initialIndex;
  final String note;

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late int _index = widget.initialIndex;
  late bool _liked = false;
  final AudioPlayer _player = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  bool _loading = true;
  bool _disposed = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  TrackInfo get _track => widget.tracks[_index];

  @override
  void initState() {
    super.initState();
    _player.positionStream.listen((pos) {
      if (!_disposed && mounted) setState(() => _position = pos);
    });
    _player.durationStream.listen((dur) {
      if (!_disposed && mounted && dur != null) setState(() => _duration = dur);
    });
    _player.playerStateStream.listen((state) {
      if (!_disposed && mounted) {
        if (state.processingState == ProcessingState.completed) {
          _next();
        }
      }
    });
    _loadTrack();
  }

  @override
  void dispose() {
    _disposed = true;
    _player.dispose();
    _yt.close();
    super.dispose();
  }

  Future<void> _loadTrack() async {
    if (_index < 0 || _index >= widget.tracks.length) return;
    setState(() => _loading = true);
    try {
      final url = _track.youtubeUrl;
      if (url.isEmpty) return;
      final manifest = await _yt.videos.streams.getManifest(Uri.parse(url));
      final audioStream = manifest.audioOnly.withHighestBitrate();
      await _player.setUrl(audioStream.url.toString());
      if (!_disposed && mounted) {
        setState(() => _loading = false);
        _player.play();
      }
    } catch (_) {
      if (!_disposed && mounted) setState(() => _loading = false);
    }
  }

  void _togglePlay() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _toggleLike() => setState(() => _liked = !_liked);

  void _seek(Duration position) => _player.seek(position);

  void _prev() {
    if (_index > 0) {
      setState(() => _index--);
      _loadTrack();
    }
  }

  void _next() {
    if (_index < widget.tracks.length - 1) {
      setState(() => _index++);
      _loadTrack();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.person,
                    color: _onSurfaceVariant,
                    size: 22,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: Icon(
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
          Text(
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
                _track.coverUrl.isNotEmpty
                    ? Image.network(
                        _track.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.music_note_rounded,
                          color: _primary,
                          size: 72,
                        ),
                      )
                    : Icon(
                        Icons.music_note_rounded,
                        color: _primary,
                        size: 72,
                      ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0x0D000000)),
                  ),
                ),
                if (_loading)
                  Container(
                    color: Colors.black26,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
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
              style: TextStyle(
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
              style: TextStyle(
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
    final dur = _duration.inSeconds > 0 ? _duration : const Duration(seconds: 1);
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
                    _seek(Duration(seconds: (ratio * dur.inSeconds).round()));
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
                      widthFactor: (_position.inSeconds / dur.inSeconds).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(color: _primary),
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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _outline),
                  ),
                  Text(
                    _fmt(_duration),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _outline),
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
            child: Icon(
              Icons.skip_previous_rounded,
              size: 32,
              color: _onSurfaceVariant,
            ),
          ),
          GestureDetector(
            onTap: _loading ? null : _togglePlay,
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
              child: _loading
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(
                      _player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 40,
                      color: _onPrimary,
                    ),
            ),
          ),
          _controlButton(
            onTap: _next,
            child: Icon(
              Icons.skip_next_rounded,
              size: 32,
              color: _onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 48, height: 48),
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
        decoration: BoxDecoration(shape: BoxShape.circle),
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
            decoration: BoxDecoration(
              color: _secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
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
                Padding(
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
                  style: TextStyle(
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

class TrackInfo {
  final String title;
  final String artist;
  final String youtubeUrl;
  final String coverUrl;

  const TrackInfo({
    required this.title,
    required this.artist,
    required this.youtubeUrl,
    this.coverUrl = '',
  });

  factory TrackInfo.fromMap(Map<dynamic, dynamic> map) {
    return TrackInfo(
      title: map['title']?.toString() ?? 'Unknown',
      artist: map['artist']?.toString() ?? 'Unknown',
      youtubeUrl: map['youtubeUrl']?.toString() ?? '',
      coverUrl: map['coverUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'artist': artist,
        'youtubeUrl': youtubeUrl,
        'coverUrl': coverUrl,
      };
}
