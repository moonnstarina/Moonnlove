import 'package:flutter/material.dart';
import 'photo_detail_screen.dart';

const Color _background = Color(0xFFF8F9FA);
const Color _primary = Color(0xFF964549);
const Color _primaryContainer = Color(0xFFFF999C);
const Color _onPrimaryContainer = Color(0xFF792E33);
const Color _onSurface = Color(0xFF191C1D);
const Color _onSurfaceVariant = Color(0xFF544242);
const Color _surfaceLowest = Color(0xFFFFFFFF);

const List<String> _tabs = ['All', 'Photos', 'Videos', 'Places'];

class PhotoAlbumScreen extends StatefulWidget {
  const PhotoAlbumScreen({super.key});

  @override
  State<PhotoAlbumScreen> createState() => _PhotoAlbumScreenState();
}

class _PhotoAlbumScreenState extends State<PhotoAlbumScreen> {
  int _tabIndex = 0;

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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _buildTabs(),
                  const SizedBox(height: 24),
                  _buildMasonryGrid(),
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
          const SizedBox(width: 24),
          const Expanded(
            child: Center(
              child: Text(
                'Post a Picture',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 8),
        ],
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final active = i == _tabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? _primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? _onPrimaryContainer : _onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMasonryGrid() {
    const tiles = [
      (asset: 'assets/images/album1.jpg', ratio: 3 / 4),
      (asset: 'assets/images/album2.jpg', ratio: 1.0),
      (asset: 'assets/images/album3.jpg', ratio: 4 / 3),
      (asset: 'assets/images/album4.jpg', ratio: 3 / 4),
      (asset: 'assets/images/album5.jpg', ratio: 1.0),
      (asset: 'assets/images/album6.jpg', ratio: 4 / 5),
    ];

    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      (i.isEven ? left : right).add(
        GestureDetector(
          onTap: () => _openDetail(i),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: AspectRatio(
              aspectRatio: tile.ratio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  tile.asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFFFDAD9),
                    child: const Icon(
                      Icons.photo_rounded,
                      size: 40,
                      color: Color(0x80964549),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: left)),
        const SizedBox(width: 12),
        Expanded(child: Column(children: right)),
      ],
    );
  }

  void _openDetail(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoDetailScreen(photoIndex: index),
      ),
    );
  }
}
