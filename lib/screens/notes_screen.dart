import '../providers/app_palette.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/partner_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'music_player_screen.dart';

Color get _background => AppPalette.background;
Color get _primary => AppPalette.primary;
Color get _primaryContainer => AppPalette.primaryContainer;
Color get _onPrimaryContainer => AppPalette.onPrimaryContainer;
Color get _onSurface => AppPalette.onSurface;
Color get _onSurfaceVariant => AppPalette.onSurfaceVariant;
Color get _surfaceContainerLowest => AppPalette.surfaceContainerLowest;
Color get _surfaceContainer => AppPalette.surfaceContainer;
Color get _tertiary => AppPalette.tertiary;
Color get _tertiaryFixed => AppPalette.tertiaryFixed;
Color get _onTertiaryFixed => AppPalette.onTertiaryFixed;
Color get _onTertiaryFixedVariant => AppPalette.onTertiaryFixedVariant;
Color get _tertiaryContainer => AppPalette.tertiaryContainer;
Color get _secondary => AppPalette.secondary;
Color get _secondaryContainer => AppPalette.secondaryContainer;
Color get _primaryFixed => AppPalette.primaryFixed;
Color get _outline => AppPalette.outline;
Color get _inverseSurface => AppPalette.inverseSurface;
Color get _inversePrimary => AppPalette.inversePrimary;
Color get _inverseOnSurface => AppPalette.inverseOnSurface;
Color get _error => AppPalette.error;

get _softShadow => [
      BoxShadow(
        color: _primary.withOpacity(0.04),
        blurRadius: 20,
        offset: Offset(0, 4),
      ),
    ];

get _interactiveShadow => [
      BoxShadow(
        color: _primary.withOpacity(0.08),
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
  final _authService = AuthService();
  final _partnerService = PartnerService();
  final _notesRefController = Completer<DatabaseReference?>();
  final _tracksRefController = Completer<DatabaseReference?>();

  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _tracks = [];
  bool _loading = true;
  StreamSubscription<DatabaseEvent>? _notesSub;
  StreamSubscription<DatabaseEvent>? _tracksSub;

  static const _defaultNotes = [
    (
      title: 'Song for rainy days',
      desc:
          'This one always reminds me of that afternoon we spent watching the rain from the balcony with hot cocoa.',
    ),
    (
      title: 'Our first date theme',
      desc:
          "The cafe was playing this on loop. I couldn't stop looking at your eyes the whole time.",
    ),
    (
      title: 'Road trip vibes',
      desc:
          'Add this to the queue for next weekend. Windows down, volume up!',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initRefs();
  }

  @override
  void dispose() {
    _notesSub?.cancel();
    _tracksSub?.cancel();
    super.dispose();
  }

  Future<void> _initRefs() async {
    final notesRef = await _partnerService.getNotesRef();
    final tracksRef = await _partnerService.getTracksRef();
    if (!mounted) return;
    setState(() => _loading = false);

    if (notesRef != null) {
      _notesRefController.complete(notesRef);
      _notesSub = notesRef.onValue.listen((event) {
        final data = event.snapshot.value;
        final list = <Map<String, dynamic>>[];
        if (data is Map) {
          data.forEach((key, val) {
            if (val is Map) {
              final note = Map<String, dynamic>.from(val);
              note['id'] = key.toString();
              list.add(note);
            }
          });
        }
        if (mounted) setState(() => _notes = list);
      });
    } else {
      _notesRefController.complete(null);
    }

    if (tracksRef != null) {
      _tracksRefController.complete(tracksRef);
      _tracksSub = tracksRef.onValue.listen((event) {
        final data = event.snapshot.value;
        final list = <Map<String, dynamic>>[];
        if (data is Map) {
          data.forEach((key, val) {
            if (val is Map) {
              final track = Map<String, dynamic>.from(val);
              track['id'] = key.toString();
              list.add(track);
            }
          });
        }
        if (mounted) setState(() => _tracks = list);
      });
    } else {
      _tracksRefController.complete(null);
    }
  }

  List<Map<String, dynamic>> get _displayNotes {
    if (_notes.isNotEmpty) return _notes;
    return _defaultNotes
        .map((n) => {'title': n.title, 'desc': n.desc, 'id': null})
        .toList();
  }

  void _addNote() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tambah Note', style: TextStyle(color: _onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: 'Judul',
                hintStyle: TextStyle(color: _onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Deskripsi',
                hintStyle: TextStyle(color: _onSurfaceVariant),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: _outline)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result != true) return;
    final title = titleCtrl.text.trim();
    final desc = descCtrl.text.trim();
    if (title.isEmpty) return;
    final ref = await _notesRefController.future;
    if (ref == null) return;
    final uid = _authService.currentUser?.uid ?? '';
    await ref.push().set({
      'title': title,
      'description': desc,
      'creator_uid': uid,
      'timestamp': ServerValue.timestamp,
    });
  }

  void _deleteNote(String noteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Note', style: TextStyle(color: _onSurface)),
        content: Text('Yakin hapus note ini?',
            style: TextStyle(color: _onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: _outline)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _error),
            child: Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ref = await _notesRefController.future;
    if (ref == null) return;
    await ref.child(noteId).remove();
  }

  void _addTrack() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrackSearchSheet(
        onSelected: (title, artist, url, coverUrl) async {
          final ref = await _tracksRefController.future;
          if (ref == null) return;
          final uid = _authService.currentUser?.uid ?? '';
          await ref.push().set({
            'youtubeUrl': url,
            'title': title,
            'artist': artist.isNotEmpty ? artist : 'Unknown',
            'coverUrl': coverUrl,
            'addedBy': uid,
            'likes': {uid: false},
            'timestamp': ServerValue.timestamp,
          });
        },
      ),
    );
  }

  void _toggleTrackLike(int index) async {
    final track = _tracks[index];
    final trackId = track['id']?.toString();
    if (trackId == null) return;
    final ref = await _tracksRefController.future;
    if (ref == null) return;
    final uid = _authService.currentUser?.uid ?? '';
    final current = track['likes']?[uid] == true;
    await ref.child(trackId).child('likes/$uid').set(!current);
  }

  void _openPlayer(int index) {
    final trackList = _tracks
        .map((t) => TrackInfo.fromMap(t))
        .where((t) => t.youtubeUrl.isNotEmpty)
        .toList();
    if (trackList.isEmpty) return;
    final noteText =
        _displayNotes.isNotEmpty ? _displayNotes[index % _displayNotes.length]['desc'] ?? '' : '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MusicPlayerScreen(
          tracks: trackList,
          initialIndex: index.clamp(0, trackList.length - 1),
          note: noteText,
        ),
      ),
    );
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _buildPageHeader(),
                  const SizedBox(height: 32),
                  _buildSharedNotes(),
                  const SizedBox(height: 32),
                  _buildTopTracks(),
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
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: _onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'MoonLove',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
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
          decoration: BoxDecoration(
            color: _primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.music_note_rounded,
            color: _onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
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
    final notes = _displayNotes;
    final badgeColors = [
      (_primaryContainer, _onPrimaryContainer, Icons.push_pin_rounded),
      (_tertiaryContainer, _onPrimaryContainer, Icons.favorite_rounded),
      (_secondaryContainer, _secondary, Icons.star_rounded),
    ];
    final cardBgs = [
      _surfaceContainerLowest,
      _tertiaryFixed,
      _surfaceContainerLowest,
    ];
    final rotations = [0.2, -0.1, 0.1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Shared Notes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _onSurface,
              ),
            ),
            GestureDetector(
              onTap: _addNote,
              child: Icon(
                Icons.add_circle_rounded,
                color: _primary,
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 150,
          child: notes.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada note',
                    style: TextStyle(color: _onSurfaceVariant, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, i) {
                    final note = notes[i];
                    final ci = i % badgeColors.length;
                    return _buildNoteCard(
                      title: note['title']?.toString() ?? '',
                      desc: note['description']?.toString() ?? '',
                      bg: cardBgs[ci],
                      badgeBg: badgeColors[ci].$1,
                      badgeIcon: badgeColors[ci].$3,
                      badgeColor: badgeColors[ci].$2,
                      rotation: rotations[ci],
                      onDelete: note['id'] != null
                          ? () => _deleteNote(note['id'])
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNoteCard({
    required String title,
    required String desc,
    required Color bg,
    required Color badgeBg,
    required IconData badgeIcon,
    required Color badgeColor,
    required double rotation,
    VoidCallback? onDelete,
  }) {
    return GestureDetector(
      onLongPress: onDelete,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bg,
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
                angle: rotation,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x1F000000), blurRadius: 4),
                    ],
                  ),
                  child: Icon(
                    badgeIcon,
                    color: badgeColor,
                    size: 16,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    desc,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: _onSurfaceVariant,
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

  Widget _buildTopTracks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Tracks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _onSurface,
              ),
            ),
            GestureDetector(
              onTap: _addTrack,
              child: Icon(
                Icons.add_circle_rounded,
                color: _primary,
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_tracks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Belum ada lagu',
                style: TextStyle(color: _onSurfaceVariant, fontSize: 14),
              ),
            ),
          )
        else
          for (var i = 0; i < _tracks.length; i++) ...[
            _buildTrackTile(i, _tracks[i]),
            if (i != _tracks.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _buildTrackTile(int index, Map<String, dynamic> track) {
    final uid = _authService.currentUser?.uid ?? '';
    final isLiked = track['likes']?[uid] == true;
    final title = track['title']?.toString() ?? 'Unknown';
    final artist = track['artist']?.toString() ?? 'Unknown';

    return GestureDetector(
      onTap: () => _openPlayer(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent),
          boxShadow: _interactiveShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _surfaceContainer,
              ),
              clipBehavior: Clip.antiAlias,
              child: Icon(
                Icons.music_note_rounded,
                color: _onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: _onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _toggleTrackLike(index),
              icon: Icon(
                isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isLiked ? _primary : _outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackSearchSheet extends StatefulWidget {
  const _TrackSearchSheet({required this.onSelected});

  final void Function(String title, String artist, String url, String coverUrl)
      onSelected;

  @override
  State<_TrackSearchSheet> createState() => _TrackSearchSheetState();
}

class _TrackSearchSheetState extends State<_TrackSearchSheet> {
  final _searchCtrl = TextEditingController();
  final _yt = YoutubeExplode();
  List<SearchResult> _results = [];
  bool _searching = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _searchCtrl.dispose();
    _yt.close();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _results = [];
    });
    try {
      final searchList = await _yt.search.search(query);
      if (!_disposed && mounted) {
        setState(() {
          _results = searchList.toList();
          _searching = false;
        });
      }
    } catch (_) {
      if (!_disposed && mounted) setState(() => _searching = false);
    }
  }

  void _select(SearchResult r) {
    final url = 'https://www.youtube.com/watch?v=${r.id}';
    final title = r.title;
    final artist = r.author;
    final coverUrl =
        'https://img.youtube.com/vi/${r.id}/mqdefault.jpg';
    widget.onSelected(title, artist, url, coverUrl);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppPalette.surfaceContainerLowest,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPalette.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Cari lagu di YouTube...',
                          hintStyle:
                              TextStyle(color: AppPalette.onSurfaceVariant),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: AppPalette.onSurfaceVariant),
                          filled: true,
                          fillColor: AppPalette.surfaceContainer,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: _search,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppPalette.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            color: AppPalette.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              if (_searching)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )
              else if (_results.isEmpty && _searchCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Tidak ada hasil',
                    style: TextStyle(
                        color: AppPalette.onSurfaceVariant, fontSize: 14),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: AppPalette.surfaceContainer,
                    ),
                    itemBuilder: (context, i) {
                      final r = _results[i];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://img.youtube.com/vi/${r.id}/mqdefault.jpg',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: AppPalette.surfaceContainer,
                              child: Icon(Icons.music_note_rounded,
                                  color: AppPalette.onSurfaceVariant),
                            ),
                          ),
                        ),
                        title: Text(
                          r.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          r.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppPalette.onSurfaceVariant,
                          ),
                        ),
                        trailing: Icon(Icons.add_circle_outline_rounded,
                            color: AppPalette.primary),
                        onTap: () => _select(r),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
