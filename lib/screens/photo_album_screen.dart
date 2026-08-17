import '../providers/app_palette.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/partner_service.dart';
import 'photo_detail_screen.dart';

Color get _background => AppPalette.background;
Color get _primary => AppPalette.primary;
Color get _primaryContainer => AppPalette.primaryContainer;
Color get _onPrimaryContainer => AppPalette.onPrimaryContainer;
Color get _onSurface => AppPalette.onSurface;
Color get _onSurfaceVariant => AppPalette.onSurfaceVariant;
Color get _surfaceLowest => AppPalette.surfaceLowest;
Color get _surfaceContainer => AppPalette.surfaceContainer;

const List<String> _tabs = ['All', 'Photos', 'Videos', 'Places'];

class PhotoAlbumScreen extends StatefulWidget {
  const PhotoAlbumScreen({super.key});

  @override
  State<PhotoAlbumScreen> createState() => _PhotoAlbumScreenState();
}

class _PhotoAlbumScreenState extends State<PhotoAlbumScreen> {
  final _authService = AuthService();
  final _partnerService = PartnerService();
  final _picker = ImagePicker();

  int _tabIndex = 0;
  bool _paired = false;
  bool _loading = true;
  DatabaseReference? _photosRef;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final photosRef = await _partnerService.getPhotosRef();
    if (!mounted) return;
    setState(() {
      _photosRef = photosRef;
      _paired = photosRef != null;
      _loading = false;
    });
  }

  Future<void> _pickAndUpload() async {
    final user = _authService.currentUser;
    if (user == null) return;
    final source = await showModalBottomSheet<_PickSource>(
      context: context,
      backgroundColor: _surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  'Upload Foto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _sourceButton(
                icon: Icons.photo_camera_rounded,
                label: 'Ambil Foto',
                value: _PickSource.camera,
              ),
              const SizedBox(height: 8),
              _sourceButton(
                icon: Icons.photo_library_rounded,
                label: 'Pilih dari Galeri',
                value: _PickSource.gallery,
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final XFile? picked;
    try {
      picked = switch (source) {
        _PickSource.camera => await _picker.pickImage(source: ImageSource.camera),
        _PickSource.gallery => await _picker.pickImage(source: ImageSource.gallery),
      };
    } catch (_) {
      _showSnack('Gagal membuka kamera/galeri');
      return;
    }
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      await _partnerService.uploadPhoto(picked.path);
      if (mounted) _showSnack('Foto berhasil diunggah 💖');
    } catch (e) {
      if (mounted) _showSnack('Gagal upload: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required _PickSource value,
  }) {
    return Material(
      color: _surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.pop(context, value),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: _primary, size: 24),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: _background,
      floatingActionButton: _paired
          ? FloatingActionButton(
              onPressed: _uploading ? null : _pickAndUpload,
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 4,
              child: _uploading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_a_photo_rounded),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
                child: _loading
                  ? Center(child: CircularProgressIndicator())
                  : !_paired
                      ? _buildNotPaired()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
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

  Widget _buildNotPaired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_rounded,
                size: 60, color: _onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 15),
            const Text(
              'Hubungkan pasangan dulu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Album hanya tersedia setelah terhubung dengan pasangan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/partner'),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Hubungkan Pasangan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
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
          Expanded(
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
        boxShadow: [
          BoxShadow(color: AppPalette.shadow, blurRadius: 8),
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
    final photosRef = _photosRef;
    if (photosRef == null) return const SizedBox.shrink();
    return StreamBuilder<DatabaseEvent>(
      stream: photosRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Gagal memuat foto'));
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return _buildEmpty();
        }
        final data = snapshot.data!.snapshot.value as Map;
        final photos = <_PhotoEntry>[];
        data.forEach((key, value) {
          final map = value is Map ? Map<String, dynamic>.from(value) : {};
          photos.add(
            _PhotoEntry(
              id: key.toString(),
              url: map['url']?.toString() ?? '',
              type: map['type']?.toString() ?? 'photo',
              timestamp: map['timestamp'] is int
                  ? map['timestamp'] as int
                  : DateTime.now().millisecondsSinceEpoch,
            ),
          );
        });
        photos.sort((a, b) => (b.timestamp).compareTo(a.timestamp));
        photos.retainWhere(_matchesTab);

        if (photos.isEmpty) return _buildEmpty();
        final left = <Widget>[];
        final right = <Widget>[];
        for (var i = 0; i < photos.length; i++) {
          final photo = photos[i];
          (i.isEven ? left : right).add(
            GestureDetector(
              onTap: () => _openDetail(photo),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: AspectRatio(
                  aspectRatio: i % 3 == 0 ? 3 / 4 : 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      photo.url,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                              color: _surfaceContainer,
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _primary,
                                  ),
                                ),
                              ),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        color: AppPalette.primaryFixed,
                        child: Icon(
                          Icons.photo_rounded,
                          size: 40,
                          color: _primary.withOpacity(0.5),
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
      },
    );
  }

  bool _matchesTab(_PhotoEntry photo) {
    return switch (_tabIndex) {
      0 => true,
      1 => photo.type == 'photo',
      2 => photo.type == 'video',
      3 => true,
      _ => true,
    };
  }

  Widget _buildEmpty() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(
          Icons.photo_library_rounded,
          size: 64,
          color: _onSurfaceVariant.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        const Text(
          'Belum ada foto',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Tekan tombol + untuk upload momen pertama kalian',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: _onSurfaceVariant),
        ),
      ],
    );
  }

  void _openDetail(_PhotoEntry photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoDetailScreen(
          photoId: photo.id,
          initialUrl: photo.url,
        ),
      ),
    );
  }
}

enum _PickSource { camera, gallery }

class _PhotoEntry {
  const _PhotoEntry({
    required this.id,
    required this.url,
    required this.type,
    required this.timestamp,
  });
  final String id;
  final String url;
  final String type;
  final int timestamp;
}
